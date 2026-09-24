*&---------------------------------------------------------------------*
*& Report ZR_IF006_SEND_TEST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zr_if006_send_test.

PARAMETERS:
  p_order TYPE zrap_if006-external_order_no OBLIGATORY,
  p_item  TYPE zrap_if006-external_item_no  OBLIGATORY.

TYPES:
  BEGIN OF ty_payload,
    external_order_no TYPE zrap_if006-external_order_no,
    external_item_no  TYPE zrap_if006-external_item_no,
    material          TYPE zrap_if006-material,
    amount            TYPE zrap_if006-amount,
    currency          TYPE zrap_if006-currency,
  END OF ty_payload.

START-OF-SELECTION.

  "1. 从 SAP DB 读取真实数据
  SELECT SINGLE *
    FROM zrap_if006
    WHERE external_order_no = @p_order
      AND external_item_no  = @p_item
    INTO @DATA(ls_db).

  IF sy-subrc <> 0.
    WRITE: / 'SAP DB 中找不到指定记录'.
    RETURN.
  ENDIF.

  "2. 准备发送数据
  DATA(ls_payload) = VALUE ty_payload(
    external_order_no = ls_db-external_order_no
    external_item_no  = ls_db-external_item_no
    material          = ls_db-material
    amount            = ls_db-amount
    currency          = ls_db-currency
  ).

  "3. 转换成 iFlow 接收的 JSON 格式
  DATA(lt_mapping) = VALUE /ui2/cl_json=>name_mappings(
    ( abap = 'EXTERNAL_ORDER_NO' json = 'ExternalOrderNo' )
    ( abap = 'EXTERNAL_ITEM_NO'  json = 'ExternalItemNo'  )
    ( abap = 'MATERIAL'          json = 'Material'        )
    ( abap = 'AMOUNT'            json = 'Amount'          )
    ( abap = 'CURRENCY'          json = 'Currency'        )
  ).

  DATA(lv_json) = /ui2/cl_json=>serialize(
    data          = ls_payload
    name_mappings = lt_mapping ).

  "4. 创建 HTTP Client
  DATA lo_client TYPE REF TO if_http_client.

  cl_http_client=>create_by_destination(
    EXPORTING
      destination = 'Z_IF006_WRITE_HANA'
    IMPORTING
      client      = lo_client
    EXCEPTIONS
      OTHERS      = 1 ).

  IF sy-subrc <> 0.
    WRITE: / 'HTTP Client 创建失败'.
    RETURN.
  ENDIF.

  "5. POST JSON
  lo_client->request->set_method(
    if_http_request=>co_request_method_post ).

  lo_client->request->set_content_type(
    'application/json; charset=utf-8' ).

  lo_client->request->set_cdata( lv_json ).

  lo_client->send(
    EXCEPTIONS
      OTHERS = 1 ).

  IF sy-subrc <> 0.
    WRITE: / 'HTTP 发送失败'.
    lo_client->close( ).
    RETURN.
  ENDIF.

  lo_client->receive(
    EXCEPTIONS
      OTHERS = 1 ).

  IF sy-subrc <> 0.
    WRITE: / 'HTTP 接收失败'.
    lo_client->close( ).
    RETURN.
  ENDIF.

  "6. 获取 iFlow 返回结果
  lo_client->response->get_status(
    IMPORTING
      code = DATA(lv_status) ).

  DATA(lv_response) =
    lo_client->response->get_cdata( ).

  lo_client->close( ).

  WRITE: / 'HTTP Status:', lv_status.
  WRITE: / 'SAP 发送内容:', lv_json.
  WRITE: / 'iFlow 返回内容:', lv_response.
