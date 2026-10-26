CLASS lhc_Addon DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Addon RESULT result.
    METHODS saveBatch FOR MODIFY
      IMPORTING keys FOR ACTION Addon~saveBatch RESULT result.

ENDCLASS.

CLASS lhc_Addon IMPLEMENTATION.

  METHOD get_global_authorizations.
    "允许新增
    IF requested_authorizations-%create =
       if_abap_behv=>mk-on.

      result-%create = if_abap_behv=>auth-allowed.

    ENDIF.

    "允许修改
    IF requested_authorizations-%update =
       if_abap_behv=>mk-on.

      result-%update = if_abap_behv=>auth-allowed.

    ENDIF.
  ENDMETHOD.

  METHOD saveBatch.
    "--------------------------------------------
    " JSON 请求结构
    "--------------------------------------------
    TYPES:
      BEGIN OF ty_row,
        order_no       TYPE c LENGTH 10,
        item_no        TYPE c LENGTH 6,
        follow_up_date TYPE string,
        comment_text   TYPE string,
        sap_status     TYPE string,
      END OF ty_row.

    TYPES ty_rows
      TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_request,
        rows TYPE ty_rows,
      END OF ty_request.

    "--------------------------------------------
    " Cloud 返回结构
    "--------------------------------------------
    TYPES:
      BEGIN OF ty_cloud_result,
        RequestedCount TYPE i,
        ProcessedCount TYPE i,
        SuccessCount   TYPE i,
      END OF ty_cloud_result.

    DATA ls_request TYPE ty_request.
    DATA ls_cloud_result TYPE ty_cloud_result.

    DATA lt_create TYPE TABLE FOR CREATE zi_if007_addon.
    DATA lt_update TYPE TABLE FOR UPDATE zi_if007_addon.

    DATA lv_mode          TYPE c LENGTH 1.
    DATA lv_sap_status    TYPE c LENGTH 1.
    DATA lv_cloud_status  TYPE c LENGTH 1.
    DATA lv_sap_message   TYPE string.
    DATA lv_cloud_message TYPE string.
    DATA lv_details_json  TYPE string.

    DATA lv_error         TYPE string.
    DATA lv_date_text     TYPE string.
    DATA lv_date          TYPE dats.
    DATA lv_http_code     TYPE i.
    DATA lv_response      TYPE string.

    DATA lv_total         TYPE i.
    DATA lv_failed_count  TYPE i.
    DATA lv_success_count TYPE i.
    DATA lv_index         TYPE i.

    "--------------------------------------------
    " 每次 Action 接收一批 RowsJson
    "--------------------------------------------
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      CLEAR:
        ls_request,
        ls_cloud_result,
        lt_create,
        lt_update,
        lv_error,
        lv_http_code,
        lv_response,
        lv_details_json,
        lv_total,
        lv_failed_count,
        lv_success_count,
        lv_index.

      lv_mode = <ls_key>-%param-SaveMode.

      lv_sap_status    = 'N'.
      lv_cloud_status  = 'N'.
      lv_sap_message   = 'SAP not executed'.
      lv_cloud_message = 'Cloud not executed'.

      "------------------------------------------
      " 1. 检查保存模式
      "------------------------------------------
      IF lv_mode <> 'A'
         AND lv_mode <> 'S'
         AND lv_mode <> 'C'.

        lv_error = 'Invalid SaveMode'.

      ENDIF.

      "------------------------------------------
      " 2. 解析 JSON
      "------------------------------------------
      IF lv_error IS INITIAL.

        IF <ls_key>-%param-RowsJson IS INITIAL.

          lv_error = 'RowsJson is empty'.

        ELSE.

          TRY.

              /ui2/cl_json=>deserialize(
                EXPORTING
                  json = <ls_key>-%param-RowsJson
                  pretty_name =
                    /ui2/cl_json=>pretty_mode-camel_case
                CHANGING
                  data = ls_request
              ).

            CATCH cx_root INTO DATA(lx_json).

              lv_error = lx_json->get_text( ).

          ENDTRY.

        ENDIF.

      ENDIF.

      lv_total = lines( ls_request-rows ).

      IF lv_error IS INITIAL AND lv_total = 0.

        lv_error = 'No rows to save'.

      ENDIF.

      "------------------------------------------
      " 3. 检查请求数据
      "------------------------------------------
      IF lv_error IS INITIAL.

        LOOP AT ls_request-rows INTO DATA(ls_check).

          IF ls_check-order_no IS INITIAL
             OR ls_check-item_no IS INITIAL.

            lv_error = 'SalesOrder key is empty'.
            EXIT.

          ENDIF.

          IF strlen( ls_check-comment_text ) > 255.

            lv_error = 'CommentText exceeds 255 characters'.
            EXIT.

          ENDIF.

          IF ls_check-sap_status IS NOT INITIAL
             AND ls_check-sap_status <> 'OPEN'
             AND ls_check-sap_status <> 'PROC'
             AND ls_check-sap_status <> 'DONE'.

            lv_error = 'Invalid SapStatus'.
            EXIT.

          ENDIF.

          lv_date_text = ls_check-follow_up_date.

          REPLACE ALL OCCURRENCES OF '-'
            IN lv_date_text WITH ''.

          IF lv_date_text IS NOT INITIAL.

            IF strlen( lv_date_text ) <> 8
               OR lv_date_text CN '0123456789'.

              lv_error = 'Invalid FollowUpDate format'.
              EXIT.

            ENDIF.

            lv_date = lv_date_text.

            CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
              EXPORTING
                date                      = lv_date
              EXCEPTIONS
                plausibility_check_failed = 1
                OTHERS                    = 2.

            IF sy-subrc <> 0.
              lv_error = 'Invalid FollowUpDate value'.
              EXIT.
            ENDIF.

          ENDIF.

        ENDLOOP.

      ENDIF.

      "------------------------------------------
      " 4. 数据检查失败
      "------------------------------------------
      IF lv_error IS NOT INITIAL.

        IF lv_mode = 'A' OR lv_mode = 'S'.
          lv_sap_status  = 'F'.
          lv_sap_message = lv_error.
        ENDIF.

        IF lv_mode = 'A' OR lv_mode = 'C'.
          lv_cloud_status  = 'F'.
          lv_cloud_message = lv_error.
        ENDIF.

      ELSE.

        "========================================
        " 5. SAP 保存：A / S
        "========================================
        IF lv_mode = 'A' OR lv_mode = 'S'.

          LOOP AT ls_request-rows INTO DATA(ls_row).

            lv_index = lv_index + 1.

            CLEAR lv_date.
            lv_date_text = ls_row-follow_up_date.

            REPLACE ALL OCCURRENCES OF '-'
              IN lv_date_text WITH ''.

            IF lv_date_text IS NOT INITIAL.
              lv_date = lv_date_text.
            ENDIF.

            "读取 Managed RAP 中现有的数据
            READ ENTITIES OF zi_if007_addon IN LOCAL MODE
              ENTITY Addon
              FIELDS ( SalesOrder SalesOrderItem )
              WITH VALUE #(
                (
                  SalesOrder     = ls_row-order_no
                  SalesOrderItem = ls_row-item_no
                )
              )
              RESULT DATA(lt_existing).

            IF lt_existing IS INITIAL.

              "不存在：CREATE
              APPEND VALUE #(
                %cid = |IF007_{ lv_index }|
                SalesOrder     = ls_row-order_no
                SalesOrderItem = ls_row-item_no
                FollowUpDate   = lv_date
                CommentText    = ls_row-comment_text
                SapStatus      = ls_row-sap_status
              ) TO lt_create.

            ELSE.

              "存在：UPDATE
              APPEND VALUE #(
                SalesOrder     = ls_row-order_no
                SalesOrderItem = ls_row-item_no
                FollowUpDate   = lv_date
                CommentText    = ls_row-comment_text
                SapStatus      = ls_row-sap_status
              ) TO lt_update.

            ENDIF.

          ENDLOOP.

          "一次 EML 处理本批次新增和更新
          MODIFY ENTITIES OF zi_if007_addon IN LOCAL MODE
            ENTITY Addon

            CREATE FIELDS (
              SalesOrder
              SalesOrderItem
              FollowUpDate
              CommentText
              SapStatus
            )
            WITH lt_create

            UPDATE FIELDS (
              FollowUpDate
              CommentText
              SapStatus
            )
            WITH lt_update

            MAPPED DATA(ls_sap_mapped)
            FAILED DATA(ls_sap_failed)
            REPORTED DATA(ls_sap_reported).

          lv_failed_count =
            lines( ls_sap_failed-Addon ).

          lv_success_count =
            lv_total - lv_failed_count.

          IF lv_failed_count = 0.

            lv_sap_status = 'S'.

          ELSEIF lv_success_count > 0.

            lv_sap_status = 'P'.

          ELSE.

            lv_sap_status = 'F'.

          ENDIF.

          lv_sap_message =
            |RAP accepted { lv_success_count }/{ lv_total } rows; commit pending|.

        ENDIF.

        "========================================
        " 6. Cloud 保存：A / C
        "========================================
        IF lv_mode = 'A' OR lv_mode = 'C'.

          CLEAR:
            lv_http_code,
            lv_response,
            ls_cloud_result.

          "整批调用一次 iFlow
          zcl_if007_cloud_write=>send_json(
            EXPORTING
              iv_json      = <ls_key>-%param-RowsJson
            IMPORTING
              ev_http_code = lv_http_code
              ev_response  = lv_response
          ).

          lv_details_json = lv_response.

          IF lv_http_code = 200.

            TRY.

                /ui2/cl_json=>deserialize(
                  EXPORTING
                    json = lv_response
                  CHANGING
                    data = ls_cloud_result
                ).

                IF ls_cloud_result-RequestedCount = lv_total
                   AND ls_cloud_result-ProcessedCount = lv_total
                   AND ls_cloud_result-SuccessCount = lv_total.

                  lv_cloud_status = 'S'.

                ELSEIF ls_cloud_result-SuccessCount > 0
                   AND ls_cloud_result-SuccessCount < lv_total.

                  lv_cloud_status = 'P'.

                ELSE.

                  lv_cloud_status = 'F'.

                ENDIF.

                lv_cloud_message =
                  |Cloud success: {
                    ls_cloud_result-SuccessCount
                  }/{ lv_total }|.

              CATCH cx_root INTO DATA(lx_cloud).

                lv_cloud_status = 'F'.
                lv_cloud_message =
                  lx_cloud->get_text( ).

            ENDTRY.

          ELSE.

            lv_cloud_status = 'F'.

            lv_cloud_message =
              |HTTP { lv_http_code }: { lv_response }|.

          ENDIF.

        ENDIF.

      ENDIF.

      "------------------------------------------
      " 7. 返回两个独立状态
      "------------------------------------------
      APPEND VALUE #(
        %cid = <ls_key>-%cid
        %param = VALUE #(
          SapStatus    = lv_sap_status
          CloudStatus  = lv_cloud_status
          SapMessage   = lv_sap_message
          CloudMessage = lv_cloud_message
          DetailsJson  = lv_details_json
        )
      ) TO result.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
