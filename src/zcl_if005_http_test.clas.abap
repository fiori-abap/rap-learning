CLASS zcl_if005_http_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES ty_sales_order_range TYPE RANGE OF vbak-vbeln.

    TYPES:
      BEGIN OF ty_send_result,
        status_code TYPE i,
        response    TYPE string,
      END OF ty_send_result.

    CLASS-METHODS send_orders
      IMPORTING
        it_sales_order   TYPE ty_sales_order_range
      RETURNING
        VALUE(rs_result) TYPE ty_send_result.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_if005_http_test IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DATA lt_sales_order TYPE ty_sales_order_range.
    DATA(ls_result) = send_orders(
      it_sales_order = lt_sales_order
    ).

    out->write( |HTTP Status: { ls_result-status_code }| ).
    out->write( ls_result-response ).

  ENDMETHOD.

  METHOD send_orders.
    DATA lo_http_client TYPE REF TO if_http_client.
    DATA lv_response    TYPE string.
    DATA lv_auth TYPE string.

    TYPES:
      BEGIN OF ty_order,
        order_no TYPE vbak-vbeln,
        item_no  TYPE vbap-posnr,
        material TYPE vbap-matnr,
        amount   TYPE vbap-netwr,
        currency TYPE vbak-waerk,
      END OF ty_order.

    TYPES ty_order_tab TYPE STANDARD TABLE OF ty_order WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_payload,
        orders TYPE ty_order_tab,
      END OF ty_payload.

    DATA lt_order   TYPE ty_order_tab.
    DATA ls_payload TYPE ty_payload.
    DATA lv_json    TYPE string.

    cl_http_client=>create_by_url(
      EXPORTING
        url    = 'https://1d4e2304trial.it-cpitrial03-rt.cfapps.ap21.hana.ondemand.com/http/if005/sap'
      IMPORTING
        client = lo_http_client
      EXCEPTIONS
        argument_not_found = 1
        plugin_not_active  = 2
        internal_error     = 3
        OTHERS             = 4 ).

    IF sy-subrc <> 0.

      RETURN.
    ENDIF.

    lv_auth = |P2007873612:Jy@05498563|.

    lv_auth = cl_http_utility=>encode_base64(
      unencoded = lv_auth
    ).

    lo_http_client->request->set_header_field(
      name  = 'Authorization'
      value = |Basic { lv_auth }|
    ).


    lo_http_client->request->set_method( 'POST' ).

    lo_http_client->request->set_header_field(
      name  = 'Content-Type'
      value = 'application/json'
    ).

    SELECT
           a~vbeln AS order_no,
           b~posnr AS item_no,
           b~matnr AS material,
           b~netwr AS amount,
           a~waerk AS currency
      FROM vbak AS a
      INNER JOIN vbap AS b
        ON b~vbeln = a~vbeln
WHERE a~vbeln IN @it_sales_order
  AND b~matnr IS NOT INITIAL
ORDER BY a~vbeln, b~posnr
INTO TABLE @lt_order.

    ls_payload-orders = lt_order.

    lv_json = /ui2/cl_json=>serialize(
      data        = ls_payload
      pretty_name = /ui2/cl_json=>pretty_mode-camel_case
    ).

    lo_http_client->request->set_cdata(
      lv_json
    ).

    lo_http_client->send(
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        http_invalid_timeout       = 4
        OTHERS                     = 5 ).

    IF sy-subrc <> 0.

      RETURN.
    ENDIF.

    lo_http_client->receive(
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4 ).

    IF sy-subrc <> 0.

      DATA lv_error_code    TYPE sy-subrc.
      DATA lv_error_message TYPE string.

      lo_http_client->get_last_error(
        IMPORTING
          code    = lv_error_code
          message = lv_error_message
      ).

      RETURN.

    ENDIF.

    lo_http_client->response->get_status(
      IMPORTING
        code = rs_result-status_code
    ).

    rs_result-response =
      lo_http_client->response->get_cdata( ).
    lo_http_client->close( ).
  ENDMETHOD.

ENDCLASS.
