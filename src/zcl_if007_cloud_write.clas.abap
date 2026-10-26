CLASS zcl_if007_cloud_write DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CLASS-METHODS send_json
      IMPORTING
        iv_json      TYPE string
      EXPORTING
        ev_http_code TYPE i
        ev_response  TYPE string.

ENDCLASS.


CLASS zcl_if007_cloud_write IMPLEMENTATION.

  METHOD send_json.

    DATA lo_http TYPE REF TO if_http_client.

    CLEAR: ev_http_code, ev_response.

    IF iv_json IS INITIAL.
      ev_response = 'Request JSON is empty'.
      RETURN.
    ENDIF.

    "1. 使用已经测试成功的 SM59
    cl_http_client=>create_by_destination(
      EXPORTING
        destination = 'Z_IF007_WRITE_TEST'
      IMPORTING
        client      = lo_http
      EXCEPTIONS
        OTHERS      = 1
    ).

    IF sy-subrc <> 0 OR lo_http IS NOT BOUND.
      ev_response = 'SM59 connection failed'.
      RETURN.
    ENDIF.

    "2. 禁止认证弹窗
    lo_http->propertytype_logon_popup =
      if_http_client=>co_disabled.

    "3. HTTP POST
    lo_http->request->set_method(
      if_http_request=>co_request_method_post
    ).

    lo_http->request->set_header_field(
      name  = 'Content-Type'
      value = 'application/json'
    ).

    "4. 设置请求 JSON
    lo_http->request->set_cdata(
      iv_json
    ).

    "5. 发送请求
    lo_http->send(
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4
    ).

    IF sy-subrc <> 0.
      ev_response = 'HTTP send failed'.
      lo_http->close( ).
      RETURN.
    ENDIF.

    "6. 接收响应
    lo_http->receive(
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4
    ).

    IF sy-subrc <> 0.
      ev_response = 'HTTP receive failed'.
      lo_http->close( ).
      RETURN.
    ENDIF.

    "7. 取得 HTTP 状态及响应
    lo_http->response->get_status(
      IMPORTING
        code = ev_http_code
    ).

    ev_response =
      lo_http->response->get_cdata( ).

    lo_http->close( ).

  ENDMETHOD.

ENDCLASS.
