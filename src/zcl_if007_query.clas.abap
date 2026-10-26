CLASS zcl_if007_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_IF007_QUERY IMPLEMENTATION.


  METHOD if_rap_query_provider~select.
    DATA lt_result TYPE STANDARD TABLE OF zce_if007_overview
                     WITH EMPTY KEY.

    "--------------------------------------------------
    " 1. 接收 Fiori 的 Paging
    "--------------------------------------------------
    DATA(lv_top) =
      io_request->get_paging( )->get_page_size( ).

    DATA(lv_skip) =
      io_request->get_paging( )->get_offset( ).

    "--------------------------------------------------
    " 2. 接收 Fiori 的 Filter
    "--------------------------------------------------
    DATA lr_salesorder TYPE RANGE OF vbak-vbeln.

    TRY.

        DATA(lt_filter_condition) =
          io_request->get_filter( )->get_as_ranges( ).

        READ TABLE lt_filter_condition
          WITH KEY name = 'SALESORDER'
          INTO DATA(ls_filter).

        IF sy-subrc = 0.
          lr_salesorder = CORRESPONDING #( ls_filter-range ).
        ENDIF.

      CATCH cx_rap_query_filter_no_range.
        "当前练习先不处理非 Range 类型 Filter
    ENDTRY.


    "---------------------------------------------
    " 3. Count：总记录数
    "---------------------------------------------
    DATA lv_count TYPE int8.

    IF io_request->is_total_numb_of_rec_requested( ).

      SELECT COUNT( * )
        FROM vbap AS item
        INNER JOIN vbak AS header
          ON header~vbeln = item~vbeln
        WHERE item~vbeln IN @lr_salesorder
        INTO @lv_count.

    ENDIF.

    "---------------------------------------------
    " 4. SAP标准数据 + VBEP + SQL Paging
    "---------------------------------------------
    IF io_request->is_data_requested( ).

      DATA(lv_max_rows) = COND int8(
        WHEN lv_top =
          if_rap_query_paging=>page_size_unlimited
        THEN 0
        ELSE lv_top
      ).

      IF lv_top <> 0.

        SELECT FROM vbap AS item

          INNER JOIN vbak AS header
            ON header~vbeln = item~vbeln

          LEFT OUTER JOIN vbep AS schedule
            ON schedule~vbeln = item~vbeln
           AND schedule~posnr = item~posnr

          FIELDS
            item~vbeln AS SalesOrder,
            item~posnr AS SalesOrderItem,
            item~matnr AS Material,
            item~kwmeng AS Quantity,
            item~vrkme AS SalesUnit,
            MIN( schedule~edatu ) AS SapDeliveryDate

          WHERE item~vbeln IN @lr_salesorder

          GROUP BY
            item~vbeln,
            item~posnr,
            item~matnr,
            item~kwmeng,
            item~vrkme

          ORDER BY
            item~vbeln,
            item~posnr

          INTO CORRESPONDING FIELDS OF TABLE @lt_result

          OFFSET @lv_skip
          UP TO @lv_max_rows ROWS.

      ENDIF.

    ENDIF.

    "=================================================
    " IF007 Cloud Batch Read
    " 放在 Paging 后、Response 前
    "=================================================

    IF io_request->is_data_requested( )
       AND lt_result IS NOT INITIAL.

      TYPES:
        BEGIN OF ty_key,
          order_no TYPE vbeln_va,
          item_no  TYPE posnr_va,
        END OF ty_key.

      TYPES tt_keys TYPE STANDARD TABLE OF ty_key
                    WITH EMPTY KEY.

      TYPES:
        BEGIN OF ty_request,
          keys TYPE tt_keys,
        END OF ty_request.

      TYPES:
        BEGIN OF ty_cloud_row,
          order_no        TYPE vbeln_va,
          item_no         TYPE posnr_va,
          delivery_date   TYPE string,
          external_status TYPE string,
          comment         TYPE string,
        END OF ty_cloud_row.

      TYPES tt_cloud_rows TYPE STANDARD TABLE OF ty_cloud_row
                          WITH EMPTY KEY.

      TYPES:
        BEGIN OF ty_response,
          rows TYPE tt_cloud_rows,
        END OF ty_response.

      DATA ls_request TYPE ty_request.
      DATA ls_response TYPE ty_response.

      DATA lt_cloud TYPE HASHED TABLE OF ty_cloud_row
        WITH UNIQUE KEY order_no item_no.

      "1. 收集当前页的所有订单Key

      LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<ls_key>).

        APPEND VALUE #(
          order_no = <ls_key>-SalesOrder
          item_no  = <ls_key>-SalesOrderItem
        ) TO ls_request-keys.

      ENDLOOP.

      "2. 生成批量请求JSON

      DATA(lt_req_mapping) =
        VALUE /ui2/cl_json=>name_mappings(
          ( abap = 'KEYS'     json = 'keys' )
          ( abap = 'ORDER_NO' json = 'orderNo' )
          ( abap = 'ITEM_NO'  json = 'itemNo' )
        ).

      DATA(lv_request_json) =
        /ui2/cl_json=>serialize(
          data          = ls_request
          name_mappings = lt_req_mapping
          compress      = abap_true
          numc_as_string = abap_true
        ).

      "3. HTTP POST：一次发送所有Key

      DATA lo_http TYPE REF TO if_http_client.
      DATA lv_code TYPE i.
      DATA lv_json TYPE string.

      cl_http_client=>create_by_destination(
        EXPORTING
          destination = 'Z_IF007_READ'
        IMPORTING
          client      = lo_http
      ).

      IF lo_http IS NOT BOUND.
        RAISE EXCEPTION TYPE lcx_if007_http.
      ENDIF.

      lo_http->request->set_method(
        if_http_request=>co_request_method_post
      ).

      lo_http->request->set_header_field(
        name  = 'Content-Type'
        value = 'application/json'
      ).

      lo_http->request->set_cdata(
        lv_request_json
      ).

      lo_http->send( ).

      IF sy-subrc <> 0.
        lo_http->close( ).
        RAISE EXCEPTION TYPE lcx_if007_http.
      ENDIF.

      lo_http->receive( ).

      IF sy-subrc <> 0.
        lo_http->close( ).
        RAISE EXCEPTION TYPE lcx_if007_http.
      ENDIF.

      lo_http->response->get_status(
        IMPORTING code = lv_code
      ).

      lv_json = lo_http->response->get_cdata( ).

      lo_http->close( ).

      IF lv_code <> 200.
        RAISE EXCEPTION TYPE lcx_if007_http.
      ENDIF.

      "4. JSON反序列化

      DATA(lt_resp_mapping) =
        VALUE /ui2/cl_json=>name_mappings(
          ( abap = 'ROWS' json = 'rows' )
        ).

      /ui2/cl_json=>deserialize(
        EXPORTING
          json          = lv_json
          name_mappings = lt_resp_mapping
        CHANGING
          data          = ls_response
      ).

      "5. Cloud数据转为Hash Table

      LOOP AT ls_response-rows INTO DATA(ls_cloud).

        INSERT ls_cloud INTO TABLE lt_cloud.

      ENDLOOP.

      "6. 按复合Key合并SAP与Cloud

      LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<ls_out>).

        READ TABLE lt_cloud
          ASSIGNING FIELD-SYMBOL(<ls_cloud>)
          WITH TABLE KEY
            order_no = <ls_out>-SalesOrder
            item_no  = <ls_out>-SalesOrderItem.

        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        DATA(lv_date) = <ls_cloud>-delivery_date.

        REPLACE ALL OCCURRENCES OF '-'
          IN lv_date WITH ''.

        IF strlen( lv_date ) = 8
           AND lv_date CO '0123456789'.

          <ls_out>-CloudDeliveryDate =
            CONV d( lv_date ).

        ENDIF.

        <ls_out>-ExternalStatus =
          <ls_cloud>-external_status.

      ENDLOOP.

    ENDIF.


"=================================================
" IF007 SAP Add-on Data
"=================================================

IF io_request->is_data_requested( )
   AND lt_result IS NOT INITIAL.

  "1. 定义Add-on数据内表
  DATA lt_addon TYPE HASHED TABLE OF zrap_if007
    WITH UNIQUE KEY sales_order sales_order_item.

  "2. 根据当前页Key批量读取Add-on
  SELECT FROM zrap_if007
    FIELDS *
    FOR ALL ENTRIES IN @lt_result
    WHERE sales_order      = @lt_result-SalesOrder
      AND sales_order_item = @lt_result-SalesOrderItem
    INTO TABLE @lt_addon.

  "3. 根据销售订单和明细匹配
  LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<ls_addon_result>).

    READ TABLE lt_addon
      ASSIGNING FIELD-SYMBOL(<ls_addon>)
      WITH TABLE KEY
        sales_order      = <ls_addon_result>-SalesOrder
        sales_order_item = <ls_addon_result>-SalesOrderItem.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    "4. 合并Add-on数据
    <ls_addon_result>-FollowUpDate =
      <ls_addon>-follow_up_date.

    <ls_addon_result>-CommentText =
      <ls_addon>-comment_text.

    <ls_addon_result>-SapStatus =
      <ls_addon>-sap_status.

    <ls_addon_result>-CloudStatus =
      <ls_addon>-cloud_status.

    <ls_addon_result>-SyncStatus =
      <ls_addon>-sync_status.

    <ls_addon_result>-LastError =
      <ls_addon>-last_error.

  ENDLOOP.

ENDIF.
    "--------------------------------------------------
    " 7. Response
    "--------------------------------------------------
    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lv_count ).
    ENDIF.

    IF io_request->is_data_requested( ).
      io_response->set_data( lt_result ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
