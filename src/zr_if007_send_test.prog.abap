*&---------------------------------------------------------------------*
*& Report ZR_IF007_SEND_TEST
*&---------------------------------------------------------------------*
REPORT zr_if007_send_test.

DATA: lo_http   TYPE REF TO if_http_client,
      lv_json   TYPE string,
      lv_code   TYPE i,
      lv_reason TYPE string,
      lv_result TYPE string.

*--------------------------------------------------------------------*
* 1. 通过 SM59 建立 HTTP 连接
*--------------------------------------------------------------------*
cl_http_client=>create_by_destination(
  EXPORTING
    destination = 'Z_IF007_WRITE_TEST'
  IMPORTING
    client      = lo_http
  EXCEPTIONS
    OTHERS      = 1
).

IF sy-subrc <> 0 OR lo_http IS NOT BOUND.
  WRITE: / 'SM59 Connection Error:', sy-subrc.
  RETURN.
ENDIF.

*--------------------------------------------------------------------*
* 2. 禁止自动弹出登录窗口
*--------------------------------------------------------------------*
lo_http->propertytype_logon_popup =
  if_http_client=>co_disabled.

*--------------------------------------------------------------------*
* 3. 准备 READ 测试 JSON
*--------------------------------------------------------------------*
lv_json =
  '{"rows":[' &&
  '{"orderNo":"9900000001",' &&
  '"itemNo":"000010",' &&
  '"followUpDate":"2026-11-01",' &&
  '"commentText":"SM59 WRITE TEST A",' &&
  '"sapStatus":"DONE"},' &&
  '{"orderNo":"9900000002",' &&
  '"itemNo":"000010",' &&
  '"followUpDate":"2026-11-02",' &&
  '"commentText":"SM59 WRITE TEST B",' &&
  '"sapStatus":"DONE"}' &&
  ']}'.

*--------------------------------------------------------------------*
* 4. 设置 HTTP POST
*--------------------------------------------------------------------*
lo_http->request->set_method(
  if_http_request=>co_request_method_post
).

lo_http->request->set_header_field(
  name  = 'Content-Type'
  value = 'application/json'
).

lo_http->request->set_header_field(
  name  = 'Accept'
  value = 'application/json'
).

lo_http->request->set_cdata(
  lv_json
).

*--------------------------------------------------------------------*
* 5. 发送 HTTP 请求
*--------------------------------------------------------------------*
lo_http->send( ).

IF sy-subrc <> 0.
  WRITE: / 'HTTP Send Error:', sy-subrc.
  lo_http->close( ).
  RETURN.
ENDIF.

*--------------------------------------------------------------------*
* 6. 接收 HTTP 响应
*--------------------------------------------------------------------*
lo_http->receive( ).

IF sy-subrc <> 0.
  WRITE: / 'HTTP Receive Error:', sy-subrc.
  lo_http->close( ).
  RETURN.
ENDIF.

*--------------------------------------------------------------------*
* 7. 获取 HTTP Status
*--------------------------------------------------------------------*
lo_http->response->get_status(
  IMPORTING
    code   = lv_code
    reason = lv_reason
).

*--------------------------------------------------------------------*
* 8. 获取响应 Body
*--------------------------------------------------------------------*
lv_result = lo_http->response->get_cdata( ).

*--------------------------------------------------------------------*
* 9. 关闭连接
*--------------------------------------------------------------------*
lo_http->close( ).

*--------------------------------------------------------------------*
* 10. 显示结果
*--------------------------------------------------------------------*
WRITE: / 'HTTP Status:', lv_code, lv_reason.
WRITE: / 'Response:'.
WRITE: / lv_result.
