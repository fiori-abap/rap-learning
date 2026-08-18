class ZCL_ZCAP_T002_DPC_EXT definition
  public
  inheriting from ZCL_ZCAP_T002_DPC
  create public .

public section.
protected section.

  methods SALESORDERHEADER_READ_LIST
    redefinition .
  methods SALESORDERHE_READ_REF_KEY_LIST
    redefinition .
  methods SALESORDERITEMSE_READ_LIST
    redefinition .
  methods SALESORDERHEADER_READ
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZCAP_T002_DPC_EXT IMPLEMENTATION.


  method SALESORDERHEADER_READ.
**TRY.
*CALL METHOD SUPER->SALESORDERHEADER_READ
*  EXPORTING
*    IO_RESPONSE =
*    IO_REQUEST  =
*    .
**  CATCH /iwbep/cx_gateway.
**ENDTRY.
  DATA ls_salesorderheader
    TYPE zcl_zcap_t002_mpc=>ts_salesorderheader.

  DATA ls_key
    TYPE zcl_zcap_t002_mpc=>ts_salesorderheader.

  DATA ls_todo_list
    TYPE /iwbep/if_v4_requ_basic_read=>ty_s_todo_list.

  DATA ls_done_list
    TYPE /iwbep/if_v4_requ_basic_read=>ty_s_todo_process_list.

  DATA lv_vbeln TYPE vbak-vbeln.


  "------------------------------------------------------------
  " 1. 取得本次请求需要处理的内容
  "------------------------------------------------------------
  io_request->get_todos(
    IMPORTING
      es_todo_list = ls_todo_list
  ).


  "------------------------------------------------------------
  " 2. 取得 URL 中的 Key
  "    例如 SalesOrderHeaderSet('321')
  "------------------------------------------------------------
  IF ls_todo_list-process-key_data = abap_true.

    io_request->get_key_data(
      IMPORTING
        es_key_data = ls_key
    ).

    "非常重要：
    "告诉 Gateway：Key Data 已经处理
    ls_done_list-key_data = abap_true.

  ENDIF.


  "------------------------------------------------------------
  " 3. 转换成 VBAK 内部格式
  "    321 -> 0000000321
  "------------------------------------------------------------
  lv_vbeln = |{ ls_key-vbeln ALPHA = IN }|.


  "------------------------------------------------------------
  " 4. 取得单条 Header
  "------------------------------------------------------------
  IF ls_todo_list-return-busi_data = abap_true.

    SELECT SINGLE
        vbeln,
        erdat,
        ernam,
        audat,
        auart,
        netwr,
        waerk,
        vkorg,
        vtweg,
        spart,
        bstnk,
        kunnr
      FROM vbak
      WHERE vbeln = @lv_vbeln
      INTO CORRESPONDING FIELDS OF @ls_salesorderheader.


    "----------------------------------------------------------
    " 5. 返回单条 Entity
    "----------------------------------------------------------
    io_response->set_busi_data(
      is_busi_data = ls_salesorderheader
    ).

  ENDIF.


  "------------------------------------------------------------
  " 6. 告诉 Gateway 已处理完成
  "------------------------------------------------------------
  io_response->set_is_done(
    ls_done_list
  ).


  endmethod.


  method SALESORDERHEADER_READ_LIST.
**TRY.
*CALL METHOD SUPER->SALESORDERHEADER_READ_LIST
*  EXPORTING
*    IO_REQUEST  =
*    IO_RESPONSE =
*    .
**  CATCH /iwbep/cx_gateway.
**ENDTRY.
  DATA lt_header TYPE zcl_zcap_t002_mpc=>tt_salesorderheader.

  DATA ls_todo_list
    TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list.

  DATA ls_done_list
    TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list.

  DATA lv_where_clause TYPE string.
  DATA lv_count        TYPE i.


  "------------------------------------------------------------
  " 1. 取得本次 OData 请求需要后台处理的内容
  "------------------------------------------------------------
  io_request->get_todos(
    IMPORTING
      es_todo_list = ls_todo_list
  ).


  "------------------------------------------------------------
  " 2. $filter
  " 例如：
  " SalesOrder eq '321'
  "------------------------------------------------------------
  IF ls_todo_list-process-filter = abap_true.

    io_request->get_filter_osql_where_clause(
      IMPORTING
        ev_osql_where_clause = lv_where_clause
    ).

    ls_done_list-filter = abap_true.

  ENDIF.


  "------------------------------------------------------------
  " 3. 返回业务数据
  "------------------------------------------------------------
  IF ls_todo_list-return-busi_data = abap_true.

    IF lv_where_clause IS INITIAL.

      SELECT
          vbeln,
          erdat,
          ernam,
          audat,
          auart,
          netwr,
          waerk,
          vkorg,
          vtweg,
          spart,
          bstnk,
          kunnr
        FROM vbak
        INTO CORRESPONDING FIELDS OF TABLE @lt_header
        UP TO 100 ROWS.

    ELSE.

      SELECT
          vbeln,
          erdat,
          ernam,
          audat,
          auart,
          netwr,
          waerk,
          vkorg,
          vtweg,
          spart,
          bstnk,
          kunnr
        FROM vbak
        WHERE (lv_where_clause)
        INTO CORRESPONDING FIELDS OF TABLE @lt_header
        UP TO 100 ROWS.

    ENDIF.


    io_response->set_busi_data(
      it_busi_data = lt_header
    ).

  ENDIF.


  "------------------------------------------------------------
  " 4. 返回 $count
  " 注意：count 和业务数据可能在同一个请求中同时需要，
  " 所以这里必须是独立 IF，不能写 ELSEIF
  "------------------------------------------------------------
  IF ls_todo_list-return-count = abap_true.

    IF lv_where_clause IS INITIAL.

      SELECT COUNT( * )
        FROM vbak
        INTO @lv_count.

    ELSE.

      SELECT COUNT( * )
        FROM vbak
        WHERE (lv_where_clause)
        INTO @lv_count.

    ENDIF.


    io_response->set_count(
      lv_count
    ).

  ENDIF.


  "------------------------------------------------------------
  " 5. 告诉 Gateway：应用程序已经处理了哪些 Query Option
  "------------------------------------------------------------
  io_response->set_is_done(
    ls_done_list
  ).


  endmethod.


  method SALESORDERHE_READ_REF_KEY_LIST.
**TRY.
*CALL METHOD SUPER->SALESORDERHE_READ_REF_KEY_LIST
*  EXPORTING
*    IO_RESPONSE =
*    IO_REQUEST  =
*    .
**  CATCH /iwbep/cx_gateway.
**ENDTRY.

  DATA lt_header_key TYPE zcl_zcap_t002_mpc=>tt_salesorderheader.
  DATA ls_header_key LIKE LINE OF lt_header_key.

  DATA lt_item_key TYPE zcl_zcap_t002_mpc=>tt_salesorderitem.

  DATA ls_todo_list
    TYPE /iwbep/if_v4_requ_basic_ref_l=>ty_s_todo_list.

  DATA ls_done_list
    TYPE /iwbep/if_v4_requ_basic_ref_l=>ty_s_todo_process_list.


  "本次Reference请求需要处理什么
  io_request->get_todos(
    IMPORTING
      es_todo_list = ls_todo_list
  ).


  "取得来源Header的Key
  IF ls_todo_list-process-source_key_data = abap_true.

    io_request->get_source_key_data(
      IMPORTING
        es_source_key_data = ls_header_key
    ).

    ls_done_list-source_key_data = abap_true.

  ENDIF.


  "根据Header的VBELN找到所有Item的Key
  SELECT
      vbeln,
      posnr
    FROM vbap
    WHERE vbeln = @ls_header_key-vbeln
    INTO CORRESPONDING FIELDS OF TABLE @lt_item_key.


  "告诉Gateway：这些就是Navigation目标的Key
  io_response->set_target_key_data(
    lt_item_key
  ).


  "告诉Gateway：本次该处理的步骤已经处理完成
  io_response->set_is_done(
    ls_done_list
  ).
  endmethod.


  method SALESORDERITEMSE_READ_LIST.
**TRY.
*CALL METHOD SUPER->SALESORDERITEMSE_READ_LIST
*  EXPORTING
*    IO_REQUEST  =
*    IO_RESPONSE =
*    .
**  CATCH /iwbep/cx_gateway.
**ENDTRY.
DATA lt_item TYPE zcl_zcap_t002_mpc=>tt_salesorderitem.

  DATA ls_todo_list
    TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_list.

  DATA ls_done_list
    TYPE /iwbep/if_v4_requ_basic_list=>ty_s_todo_process_list.

  "Navigation 来源：SalesOrderHeader
  DATA lt_key_header
    TYPE zcl_zcap_t002_mpc=>tt_salesorderheader.

  DATA lv_vbeln TYPE vbak-vbeln.
  DATA lv_count TYPE i.


  "------------------------------------------------------------
  " 1. 本次请求需要后台处理什么
  "------------------------------------------------------------
  io_request->get_todos(
    IMPORTING
      es_todo_list = ls_todo_list
  ).


  "------------------------------------------------------------
  " 2. Header -> Items Navigation 的 Key
  "    例如：
  "    SalesOrderHeaderSet('321')/Items
  "------------------------------------------------------------
  IF ls_todo_list-process-key_data = abap_true.

    io_request->get_key_data(
      IMPORTING
        et_key_data = lt_key_header
    ).

    READ TABLE lt_key_header
      INTO DATA(ls_key_header)
      INDEX 1.

    IF sy-subrc = 0.

      "321 -> 0000000321
      lv_vbeln = |{ ls_key_header-vbeln ALPHA = IN }|.

    ENDIF.

    "Key Data 已处理
    ls_done_list-key_data = abap_true.

  ENDIF.


  "------------------------------------------------------------
  " 3. 返回业务数据
  "------------------------------------------------------------
  IF ls_todo_list-return-busi_data = abap_true.

    "----------------------------------------------------------
    " 普通 SalesOrderItemSet 一览
    "----------------------------------------------------------
    IF lv_vbeln IS INITIAL.

      SELECT
          vbeln,
          posnr,
          matnr,
          arktx,
          pstyv,
          abgru,
          netwr,
          kwmeng,
          vrkme,
          werks,
          lgort
        FROM vbap
        INTO CORRESPONDING FIELDS OF TABLE @lt_item
        UP TO 100 ROWS.

    "----------------------------------------------------------
    " Header -> Items
    " 只取得当前销售订单的明细
    "----------------------------------------------------------
    ELSE.

      SELECT
          vbeln,
          posnr,
          matnr,
          arktx,
          pstyv,
          abgru,
          netwr,
          kwmeng,
          vrkme,
          werks,
          lgort
        FROM vbap
        WHERE vbeln = @lv_vbeln
        INTO CORRESPONDING FIELDS OF TABLE @lt_item
        UP TO 100 ROWS.

    ENDIF.


    io_response->set_busi_data(
      it_busi_data = lt_item
    ).

  ENDIF.


  "------------------------------------------------------------
  " 4. 返回 $count
  " Fiori Items Table 会同时要求总件数
  "------------------------------------------------------------
  IF ls_todo_list-return-count = abap_true.

    "普通 Item 一览
    IF lv_vbeln IS INITIAL.

      SELECT COUNT( * )
        FROM vbap
        INTO @lv_count.

    "Header -> Items
    ELSE.

      SELECT COUNT( * )
        FROM vbap
        WHERE vbeln = @lv_vbeln
        INTO @lv_count.

    ENDIF.


    io_response->set_count(
      lv_count
    ).

  ENDIF.


  "------------------------------------------------------------
  " 5. 告诉 Gateway 已处理哪些请求项目
  "------------------------------------------------------------
  io_response->set_is_done(
    ls_done_list
  ).

  endmethod.
ENDCLASS.
