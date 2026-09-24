CLASS lhc_externaldata DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS sendToCloud FOR MODIFY
      IMPORTING keys FOR ACTION ExternalData~sendToCloud.
    METHODS sendToCloudBatch FOR MODIFY
      IMPORTING keys FOR ACTION ExternalData~sendToCloudBatch.
    METHODS sendToCloudBatchFlat FOR MODIFY
      IMPORTING keys FOR ACTION ExternalData~sendToCloudBatchFlat.

ENDCLASS.

CLASS lhc_externaldata IMPLEMENTATION.

  METHOD sendToCloud.
    "1. 根据 Action 收到的主键读取 SAP 数据
    READ ENTITIES OF zi_rap_if006 IN LOCAL MODE
      ENTITY ExternalData
      FIELDS ( ExternalOrderNo ExternalItemNo
               Material Amount Currency )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_orders)
      FAILED failed.

    "2. 定义发送 JSON 的结构
    TYPES:
      BEGIN OF ty_payload,
        external_order_no TYPE zrap_if006-external_order_no,
        external_item_no  TYPE zrap_if006-external_item_no,
        material          TYPE zrap_if006-material,
        amount            TYPE zrap_if006-amount,
        currency          TYPE zrap_if006-currency,
        write_mode        TYPE c LENGTH 1,
      END OF ty_payload.

    DATA lo_client TYPE REF TO if_http_client.
    DATA lv_status TYPE i.
    DATA lv_response TYPE string.
    DATA lv_error TYPE string.

    DATA(lt_mapping) = VALUE /ui2/cl_json=>name_mappings(
      ( abap = 'EXTERNAL_ORDER_NO' json = 'ExternalOrderNo' )
      ( abap = 'EXTERNAL_ITEM_NO'  json = 'ExternalItemNo'  )
      ( abap = 'MATERIAL'          json = 'Material'        )
      ( abap = 'AMOUNT'            json = 'Amount'          )
      ( abap = 'CURRENCY'          json = 'Currency'        )
      ( abap = 'WRITE_MODE' json = 'WriteMode' )
    ).

    "3. 逐条发送勾选的数据
    LOOP AT lt_orders INTO DATA(ls_order).

      CLEAR:
        lo_client,
        lv_status,
        lv_response,
        lv_error.

      "取得当前订单对应的 Action 参数
      READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_action_key>)
        WITH TABLE KEY entity
        COMPONENTS %tky = ls_order-%tky.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(lv_write_mode) = <ls_action_key>-%param-WriteMode.

      "只允许两种模式
      IF lv_write_mode <> 'I'
         AND lv_write_mode <> 'U'.

        APPEND VALUE #(
          %tky = ls_order-%tky
        ) TO failed-externaldata.

        APPEND VALUE #(
          %tky = ls_order-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'WriteMode は I または U を指定してください'
          )
        ) TO reported-externaldata.

        CONTINUE.

      ENDIF.

      DATA(ls_payload) = VALUE ty_payload(
        external_order_no = ls_order-ExternalOrderNo
        external_item_no  = ls_order-ExternalItemNo
        material          = ls_order-Material
        amount            = ls_order-Amount
        currency          = ls_order-Currency
        write_mode = lv_write_mode
      ).

      DATA(lv_json) = /ui2/cl_json=>serialize(
        data          = ls_payload
        name_mappings = lt_mapping ).

      "4. 创建 HTTP Client
      cl_http_client=>create_by_destination(
        EXPORTING
          destination = 'Z_IF006_WRITE_HANA'
        IMPORTING
          client      = lo_client
        EXCEPTIONS
          OTHERS      = 1 ).

      IF sy-subrc <> 0 OR lo_client IS INITIAL.

        lv_error = 'HTTP Client 创建失败'.

      ELSE.

        "5. POST 到 IF006_WRITE_HANA
        lo_client->request->set_method(
          if_http_request=>co_request_method_post ).

        lo_client->request->set_content_type(
          'application/json; charset=utf-8' ).

        lo_client->request->set_cdata( lv_json ).

        lo_client->send(
          EXCEPTIONS
            OTHERS = 1 ).

        IF sy-subrc <> 0.

          lv_error = 'HTTP 发送失败'.

        ELSE.

          lo_client->receive(
            EXCEPTIONS
              OTHERS = 1 ).

          IF sy-subrc <> 0.

            lv_error = 'HTTP 接收失败'.

          ELSE.

            lo_client->response->get_status(
              IMPORTING
                code = lv_status ).

            lv_response =
              lo_client->response->get_cdata( ).

            IF lv_status < 200 OR lv_status >= 300.

              "INSERT ONLY：识别 HANA Cloud 重复主键错误
              IF lv_write_mode = 'I'
                 AND lv_response CS 'unique constraint violated'.

                lv_error = 'Cloudに登録済みです'.

              ELSE.

                lv_error = |Cloud送信失敗 HTTP { lv_status }|.

              ENDIF.

            ENDIF.

          ENDIF.

        ENDIF.

        lo_client->close( ).

      ENDIF.

      "6. 返回 RAP 消息
      IF lv_error IS NOT INITIAL.

        APPEND VALUE #(
          %tky = ls_order-%tky
        ) TO failed-externaldata.

        APPEND VALUE #(
          %tky = ls_order-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = lv_error )
        ) TO reported-externaldata.

      ELSE.

        APPEND VALUE #(
          %tky = ls_order-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-success
            text     = |Cloud 送信成功: { ls_order-ExternalOrderNo }| )
        ) TO reported-externaldata.

      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD sendToCloudBatch.

  ENDMETHOD.

  METHOD sendToCloudBatchFlat.
    "--------------------------------------------------
    " 1. 定义批量 JSON 结构
    "--------------------------------------------------
    TYPES:
      BEGIN OF ty_order,
        external_order_no TYPE zrap_if006-external_order_no,
        external_item_no  TYPE zrap_if006-external_item_no,
        material          TYPE zrap_if006-material,
        amount            TYPE zrap_if006-amount,
        currency          TYPE zrap_if006-currency,
      END OF ty_order,

      tt_orders TYPE STANDARD TABLE OF ty_order WITH EMPTY KEY,

      BEGIN OF ty_payload,
        write_mode TYPE c LENGTH 1,
        orders     TYPE tt_orders,
      END OF ty_payload.

    TYPES:
      BEGIN OF ty_batch_result,
        processed_count TYPE i,
        success_count   TYPE i,
      END OF ty_batch_result.

    DATA ls_batch_result TYPE ty_batch_result.

    DATA:
      ls_payload  TYPE ty_payload,
      lo_client   TYPE REF TO if_http_client,
      lv_status   TYPE i,
      lv_response TYPE string,
      lv_error    TYPE string.

    "接收 Fiori 传入的订单主键 JSON
    TYPES:
      BEGIN OF ty_key,
        external_order_no TYPE zrap_if006-external_order_no,
        external_item_no  TYPE zrap_if006-external_item_no,
      END OF ty_key.

    DATA lt_requested_keys TYPE STANDARD TABLE OF ty_key
                           WITH EMPTY KEY.

    "--------------------------------------------------
    " 2. 一次 Action 接收一组订单
    "--------------------------------------------------
    LOOP AT keys INTO DATA(ls_batch).

      CLEAR:
        ls_payload,
        lo_client,
        ls_batch_result,
        lv_status,
        lv_response,
        lv_error.

      ls_payload-write_mode =
        ls_batch-%param-WriteMode.

      "------------------------------------------------
      " 2. 取得普通 Action 参数
      "------------------------------------------------
      ls_payload-write_mode = ls_batch-%param-WriteMode.

      CLEAR lt_requested_keys.

      IF ls_payload-write_mode <> 'I'
         AND ls_payload-write_mode <> 'U'.

        lv_error = 'WriteMode は I または U を指定してください'.

      ELSEIF ls_batch-%param-KeysJson IS INITIAL.

        lv_error = '送信対象データがありません'.

      ELSE.

        "----------------------------------------------
        " 3. 将 KeysJson 转换为订单主键内表
        "----------------------------------------------
        DATA(lt_key_mapping) =
          VALUE /ui2/cl_json=>name_mappings(
            ( abap = 'EXTERNAL_ORDER_NO'
              json = 'ExternalOrderNo' )
            ( abap = 'EXTERNAL_ITEM_NO'
              json = 'ExternalItemNo' )
          ).

        TRY.

            /ui2/cl_json=>deserialize(
              EXPORTING
                json          = ls_batch-%param-KeysJson
                name_mappings = lt_key_mapping
              CHANGING
                data          = lt_requested_keys
            ).

          CATCH cx_root.

            lv_error = 'KeysJson の形式が不正です'.

        ENDTRY.

        IF lv_error IS INITIAL.

          IF lt_requested_keys IS INITIAL
             OR lines( lt_requested_keys ) > 100.

            lv_error = '送信件数は1件から100件までです'.

          ENDIF.

        ENDIF.

        "检查主键是否为空
        IF lv_error IS INITIAL.

          LOOP AT lt_requested_keys INTO DATA(ls_key).

            IF ls_key-external_order_no IS INITIAL
               OR ls_key-external_item_no IS INITIAL.

              lv_error = '注文番号または明細番号が未入力です'.

              EXIT.

            ENDIF.

          ENDLOOP.

        ENDIF.

        "检查同一次请求中是否存在重复主键
        IF lv_error IS INITIAL.

          DATA(lv_original_count) =
            lines( lt_requested_keys ).

          SORT lt_requested_keys
            BY external_order_no external_item_no.

          DELETE ADJACENT DUPLICATES FROM lt_requested_keys
            COMPARING external_order_no external_item_no.

          IF lines( lt_requested_keys ) <> lv_original_count.

            lv_error = '送信対象に重複キーがあります'.

          ENDIF.

        ENDIF.

      ENDIF.


      "------------------------------------------------
      " 4. 参数错误：返回 RAP Message
      "------------------------------------------------
      IF lv_error IS NOT INITIAL.

        APPEND VALUE #(
          %cid = ls_batch-%cid
        ) TO failed-externaldata.

        APPEND VALUE #(
          %cid = ls_batch-%cid
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = lv_error )
        ) TO reported-externaldata.

        CONTINUE.

      ENDIF.


      "------------------------------------------------
      " 5. 根据全部主键，一次读取 SAP 数据
      "------------------------------------------------
      READ ENTITIES OF zi_rap_if006 IN LOCAL MODE
        ENTITY ExternalData
        FIELDS (
          ExternalOrderNo
          ExternalItemNo
          Material
          Amount
          Currency
        )
        WITH VALUE #(
          FOR ls_item IN lt_requested_keys
          (
            ExternalOrderNo = ls_item-external_order_no
            ExternalItemNo  = ls_item-external_item_no
          )
        )
        RESULT DATA(lt_orders).


      "检查是否全部读取成功
      IF lines( lt_orders ) <>
         lines( lt_requested_keys ).

        APPEND VALUE #(
          %cid = ls_batch-%cid
        ) TO failed-externaldata.

        APPEND VALUE #(
          %cid = ls_batch-%cid
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = '送信対象の取得件数が一致しません' )
        ) TO reported-externaldata.

        CONTINUE.

      ENDIF.

      "------------------------------------------------
      " 4. 把读取结果组装成 Orders[]
      "------------------------------------------------
      LOOP AT lt_orders INTO DATA(ls_order).

        APPEND VALUE ty_order(
          external_order_no = ls_order-ExternalOrderNo
          external_item_no  = ls_order-ExternalItemNo
          material          = ls_order-Material
          amount            = ls_order-Amount
          currency          = ls_order-Currency
        ) TO ls_payload-orders.

      ENDLOOP.

      "------------------------------------------------
      " 5. JSON 字段名称转换
      "------------------------------------------------
      DATA(lt_mapping) = VALUE /ui2/cl_json=>name_mappings(
        ( abap = 'WRITE_MODE'
          json = 'WriteMode' )
        ( abap = 'ORDERS'
          json = 'Orders' )
        ( abap = 'EXTERNAL_ORDER_NO'
          json = 'ExternalOrderNo' )
        ( abap = 'EXTERNAL_ITEM_NO'
          json = 'ExternalItemNo' )
        ( abap = 'MATERIAL'
          json = 'Material' )
        ( abap = 'AMOUNT'
          json = 'Amount' )
        ( abap = 'CURRENCY'
          json = 'Currency' )
      ).

      DATA(lv_json) = /ui2/cl_json=>serialize(
        data          = ls_payload
        name_mappings = lt_mapping
      ).

      "------------------------------------------------
      " 6. 创建 HTTP Client
      "------------------------------------------------
      cl_http_client=>create_by_destination(
        EXPORTING
          destination = 'Z_IF006_WRITE_HANA'
        IMPORTING
          client      = lo_client
        EXCEPTIONS
          OTHERS      = 1
      ).

      IF sy-subrc <> 0 OR lo_client IS INITIAL.

        lv_error = 'HTTP Client 作成失敗'.

      ELSE.

        "一次 POST 整份 JSON
        lo_client->request->set_method(
          if_http_request=>co_request_method_post
        ).

        lo_client->request->set_content_type(
          'application/json; charset=utf-8'
        ).

        lo_client->request->set_cdata( lv_json ).

        lo_client->send(
          EXCEPTIONS
            OTHERS = 1
        ).

        IF sy-subrc <> 0.

          lv_error = 'HTTP 送信失敗'.

        ELSE.

          lo_client->receive(
            EXCEPTIONS
              OTHERS = 1
          ).

          IF sy-subrc <> 0.

            lv_error = 'HTTP 応答受信失敗'.

          ELSE.

            lo_client->response->get_status(
              IMPORTING
                code = lv_status
            ).

            lv_response =
              lo_client->response->get_cdata( ).

            IF lv_status < 200 OR lv_status >= 300.

              lv_error = |Cloud送信失敗 HTTP { lv_status }|.

            ELSE.

              "----------------------------------------------
              " iFlow 返回 JSON：
              " {"ProcessedCount":2,"SuccessCount":2}
              "----------------------------------------------
              CLEAR ls_batch_result.

              DATA(lt_result_mapping) =
                VALUE /ui2/cl_json=>name_mappings(
                  ( abap = 'PROCESSED_COUNT'
                    json = 'ProcessedCount' )
                  ( abap = 'SUCCESS_COUNT'
                    json = 'SuccessCount' )
                ).

              TRY.

                  /ui2/cl_json=>deserialize(
                    EXPORTING
                      json          = lv_response
                      name_mappings = lt_result_mapping
                    CHANGING
                      data          = ls_batch_result
                  ).

                CATCH cx_root.

                  lv_error = 'Cloud応答JSON解析失敗'.

              ENDTRY.

              "本次实际发送件数
              DATA(lv_expected_count) =
                lines( ls_payload-orders ).

              "iFlow / JDBC 实际处理件数必须与发送件数完全一致
              IF lv_error IS INITIAL.

                IF ls_batch_result-processed_count <> lv_expected_count
                   OR ls_batch_result-success_count <> lv_expected_count.

                  lv_error =
                    |Cloud件数不一致: 成功 { ls_batch_result-success_count }/{ lv_expected_count }件|.

                ENDIF.

              ENDIF.

            ENDIF.

          ENDIF.

        ENDIF.

        lo_client->close( ).

      ENDIF.

      "------------------------------------------------
      " 7. 返回 RAP 消息
      "------------------------------------------------
      IF lv_error IS NOT INITIAL.

        APPEND VALUE #(
          %cid = ls_batch-%cid
        ) TO failed-externaldata.

        APPEND VALUE #(
          %cid = ls_batch-%cid
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = lv_error )
        ) TO reported-externaldata.

      ELSE.

        APPEND VALUE #(
          %cid = ls_batch-%cid
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-success
            text = |Cloud登録成功: { ls_batch_result-success_count }件| )
        ) TO reported-externaldata.

      ENDIF.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
