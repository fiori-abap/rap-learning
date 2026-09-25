CLASS zcl_if006_preview_qp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_if006_preview_qp IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    "1. 定义 iFlow 返回的 JSON 结构
    TYPES:
      BEGIN OF ty_json,
        orders TYPE STANDARD TABLE OF zce_if006_preview
             WITH EMPTY KEY,
      END OF ty_json.

    DATA: lo_client TYPE REF TO if_http_client,
          ls_json   TYPE ty_json,
          lt_result TYPE STANDARD TABLE OF zce_if006_preview
                    WITH EMPTY KEY,
          lv_status TYPE i.

    "2. 通过 SM59 创建 HTTP Client
    cl_http_client=>create_by_destination(
      EXPORTING
        destination = 'Z_IF006_READ_HANA'
      IMPORTING
        client      = lo_client
      EXCEPTIONS
        OTHERS      = 1 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_if006_query_error.
    ENDIF.

    "3. 调用 iFlow
    lo_client->request->set_method(
      if_http_request=>co_request_method_get ).

    lo_client->request->set_header_field(
      name  = 'Accept'
      value = 'application/json' ).

    "Fiori Filter → HANA Cloud Filter
    DATA(lv_cloud_filter) =
      io_request->get_filter( )->get_as_sql_string( ).

    REPLACE ALL OCCURRENCES OF
      'EXTERNALORDERNO'
      IN lv_cloud_filter
      WITH '"ORDER_NO"'.

    IF lv_cloud_filter IS NOT INITIAL.

      lo_client->request->set_header_field(
        name  = 'X-Filter-SQL'
        value = lv_cloud_filter ).

    ENDIF.


    lo_client->send(
      EXCEPTIONS
        OTHERS = 1 ).

    IF sy-subrc <> 0.
      lo_client->close( ).
      RAISE EXCEPTION TYPE zcx_if006_query_error.
    ENDIF.

    lo_client->receive(
      EXCEPTIONS
        OTHERS = 1 ).

    IF sy-subrc <> 0.
      lo_client->close( ).
      RAISE EXCEPTION TYPE zcx_if006_query_error.
    ENDIF.

    "4. 检查 HTTP Status，取得 JSON
    lo_client->response->get_status(
      IMPORTING
        code = lv_status ).

    DATA(lv_json) = lo_client->response->get_cdata( ).

    lo_client->close( ).

    IF lv_status <> 200.
      RAISE EXCEPTION TYPE zcx_if006_query_error.
    ENDIF.

    "5. JSON 字段名称与 ABAP 字段对应
    DATA(lt_mapping) = VALUE /ui2/cl_json=>name_mappings(
      ( abap = 'EXTERNALORDERNO' json = 'ExternalOrderNo' )
      ( abap = 'EXTERNALITEMNO'  json = 'ExternalItemNo'  )
      ( abap = 'MATERIAL'        json = 'Material'        )
      ( abap = 'AMOUNT'          json = 'Amount'          )
      ( abap = 'CURRENCY'        json = 'Currency'        )
    ).

    /ui2/cl_json=>deserialize(
      EXPORTING
        json          = lv_json
        name_mappings = lt_mapping
      CHANGING
        data          = ls_json ).

"6. 接收 HANA Cloud 查询结果
DATA lt_orders TYPE STANDARD TABLE OF zce_if006_preview
               WITH EMPTY KEY.

lt_orders = ls_json-orders.


    "7. 保证分页时记录顺序稳定
    SORT lt_orders BY ExternalOrderNo ExternalItemNo.


    "8. 返回筛选后的总记录数（分页前）
    IF io_request->is_total_numb_of_rec_requested( ).

      io_response->set_total_number_of_records(
        CONV int8( lines( lt_orders ) ) ).

    ENDIF.


    "9. 根据 Fiori 的分页要求返回数据
    IF io_request->is_data_requested( ).

      DATA(lv_offset) =
        io_request->get_paging( )->get_offset( ).

      DATA(lv_top) =
        io_request->get_paging( )->get_page_size( ).

      DATA(lv_first) = CONV i( lv_offset ) + 1.

      DATA(lv_last) = COND i(
        WHEN lv_top = if_rap_query_paging=>page_size_unlimited
        THEN lines( lt_orders )
        ELSE lv_first + CONV i( lv_top ) - 1 ).

      LOOP AT lt_orders INTO DATA(ls_order)
           FROM lv_first TO lv_last.

        APPEND ls_order TO lt_result.

      ENDLOOP.

      io_response->set_data( lt_result ).

    ENDIF.
  ENDMETHOD.

ENDCLASS.
