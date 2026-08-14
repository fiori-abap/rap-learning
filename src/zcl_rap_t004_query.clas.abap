CLASS zcl_rap_t004_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES ty_t_sales_order TYPE STANDARD TABLE OF zce_rap_t004 WITH EMPTY KEY.
    METHODS get_sales_order
      IMPORTING
        im_filter_condition TYPE if_rap_query_filter=>tt_name_range_pairs
        im_top              TYPE int8
        im_skip             TYPE int8
      EXPORTING
        ex_sales_order      TYPE ty_t_sales_order
        ex_count            TYPE int8.
ENDCLASS.



CLASS zcl_rap_t004_query IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    DATA(lv_top)  = io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip) = io_request->get_paging( )->get_offset( ).

    DATA lt_sales_order TYPE STANDARD TABLE OF zce_rap_t004 WITH EMPTY KEY.
    DATA lv_count TYPE int8.

    TRY.

        DATA(lt_filter_condition) =
          io_request->get_filter( )->get_as_ranges( ).

        IF lt_filter_condition IS NOT INITIAL.

          me->get_sales_order(
            EXPORTING
              im_filter_condition = lt_filter_condition
              im_top              = lv_top
              im_skip             = lv_skip
            IMPORTING
              ex_sales_order      = lt_sales_order
              ex_count            = lv_count
          ).

        ENDIF.

        IF io_request->is_total_numb_of_rec_requested( ).
          io_response->set_total_number_of_records( lv_count ).
        ENDIF.

        IF io_request->is_data_requested( ).
          io_response->set_data( lt_sales_order ).
        ENDIF.

      CATCH cx_root INTO DATA(lx_exception) ##CATCH_ALL.

        RAISE EXCEPTION TYPE cx_rap_query_cond
          EXPORTING
            previous = lx_exception.

    ENDTRY.
  ENDMETHOD.


  METHOD get_sales_order.

    DATA lr_sales_order TYPE RANGE OF vbak-vbeln.
    DATA lr_sales_org   TYPE RANGE OF vbak-vkorg.
    DATA lr_customer    TYPE RANGE OF vbak-kunnr.
    DATA lr_order_date  TYPE RANGE OF vbak-audat.
    DATA lr_material    TYPE RANGE OF vbap-matnr.


* 销售订单
    READ TABLE im_filter_condition
      WITH KEY name = 'SALESORDER'
      INTO DATA(ls_sales_order_filter).

    IF sy-subrc = 0.
      lr_sales_order = CORRESPONDING #( ls_sales_order_filter-range ).
    ENDIF.


* 销售组织
    READ TABLE im_filter_condition
      WITH KEY name = 'SALESORGANIZATION'
      INTO DATA(ls_sales_org_filter).

    IF sy-subrc = 0.
      lr_sales_org = CORRESPONDING #( ls_sales_org_filter-range ).
    ENDIF.


* 得意先
    READ TABLE im_filter_condition
      WITH KEY name = 'SOLDTOPARTY'
      INTO DATA(ls_customer_filter).

    IF sy-subrc = 0.
      lr_customer = CORRESPONDING #( ls_customer_filter-range ).
    ENDIF.


* 受注日
    READ TABLE im_filter_condition
      WITH KEY name = 'SALESORDERDATE'
      INTO DATA(ls_order_date_filter).

    IF sy-subrc = 0.
      lr_order_date = CORRESPONDING #( ls_order_date_filter-range ).
    ENDIF.


* 物料
    READ TABLE im_filter_condition
      WITH KEY name = 'MATERIAL'
      INTO DATA(ls_material_filter).

    IF sy-subrc = 0.
      lr_material = CORRESPONDING #( ls_material_filter-range ).
    ENDIF.

* 当前页数据
    DATA(lv_top) = COND int8(
      WHEN im_top < 0
      THEN 0
      ELSE im_top
    ).

* 总件数
    SELECT COUNT( * )
      FROM vbak AS a
      INNER JOIN vbap AS b
        ON b~vbeln = a~vbeln
      WHERE a~vbeln IN @lr_sales_order
        AND a~vkorg IN @lr_sales_org
        AND a~kunnr IN @lr_customer
        AND a~audat IN @lr_order_date
        AND b~matnr IN @lr_material
      INTO @ex_count.

* 销售订单 + 明细 + 得意先
    SELECT
      a~vbeln  AS SalesOrder,
      b~posnr  AS SalesOrderItem,
      a~vkorg  AS SalesOrganization,
      a~audat  AS SalesOrderDate,
      a~kunnr  AS SoldToParty,
      c~name1  AS CustomerName,
      b~matnr  AS Material,
      b~kwmeng AS OrderQuantity,
      b~vrkme  AS SalesUnit
      FROM vbak AS a
      INNER JOIN vbap AS b
        ON b~vbeln = a~vbeln
      LEFT OUTER JOIN kna1 AS c
        ON c~kunnr = a~kunnr
      WHERE a~vbeln IN @lr_sales_order
        AND a~vkorg IN @lr_sales_org
        AND a~kunnr IN @lr_customer
        AND a~audat IN @lr_order_date
        AND b~matnr IN @lr_material
      ORDER BY a~vbeln, b~posnr
      INTO CORRESPONDING FIELDS OF TABLE @ex_sales_order
      UP TO @lv_top ROWS
      OFFSET @im_skip.

* 纳入日程日
    IF ex_sales_order IS NOT INITIAL.

      SELECT
        vbeln,
        posnr,
        edatu
        FROM vbep
        FOR ALL ENTRIES IN @ex_sales_order
        WHERE vbeln = @ex_sales_order-SalesOrder
          AND posnr = @ex_sales_order-SalesOrderItem
        INTO TABLE @DATA(lt_vbep).

*   同一订单明细可能存在多个Schedule Line
*   按日期排序后保留最早的一条
      SORT lt_vbep BY vbeln posnr edatu.

      DELETE ADJACENT DUPLICATES FROM lt_vbep
        COMPARING vbeln posnr.

*   把纳入日程日写回最终结果内表
      LOOP AT ex_sales_order ASSIGNING FIELD-SYMBOL(<ls_sales_order>).

        READ TABLE lt_vbep
          WITH KEY
            vbeln = <ls_sales_order>-SalesOrder
            posnr = <ls_sales_order>-SalesOrderItem
          INTO DATA(ls_vbep)
          BINARY SEARCH.

        IF sy-subrc = 0.
          <ls_sales_order>-ScheduleLineDate = ls_vbep-edatu.
        ENDIF.

      ENDLOOP.

    ENDIF.

* 出荷信息
    IF ex_sales_order IS NOT INITIAL.

      SELECT
        d~vgbel     AS SalesOrder,
        d~vgpos     AS SalesOrderItem,
        d~vbeln     AS DeliveryDocument,
        h~wadat_ist AS ActualGoodsMovementDate
        FROM lips AS d
        INNER JOIN likp AS h
          ON h~vbeln = d~vbeln
        FOR ALL ENTRIES IN @ex_sales_order
        WHERE d~vgbel = @ex_sales_order-SalesOrder
          AND d~vgpos = @ex_sales_order-SalesOrderItem
        INTO TABLE @DATA(lt_delivery).


*   同一销售订单明细可能存在多个出荷
*   优先保留已经实际出库、且实际出库日最新的一条
      SORT lt_delivery BY
        SalesOrder
        SalesOrderItem
        ActualGoodsMovementDate DESCENDING
        DeliveryDocument DESCENDING.

      DELETE ADJACENT DUPLICATES FROM lt_delivery
        COMPARING SalesOrder SalesOrderItem.


*   把出荷信息写回最终结果
      LOOP AT ex_sales_order ASSIGNING FIELD-SYMBOL(<ls_sales_order_delivery>).

        READ TABLE lt_delivery
          WITH KEY
            SalesOrder     = <ls_sales_order_delivery>-SalesOrder
            SalesOrderItem = <ls_sales_order_delivery>-SalesOrderItem
          INTO DATA(ls_delivery)
          BINARY SEARCH.

        IF sy-subrc = 0.

          <ls_sales_order_delivery>-DeliveryDocument =
            ls_delivery-DeliveryDocument.

          <ls_sales_order_delivery>-ActualGoodsMovementDate =
            ls_delivery-ActualGoodsMovementDate.

          IF ls_delivery-ActualGoodsMovementDate IS NOT INITIAL.
            <ls_sales_order_delivery>-DeliveryStatus = '已出库'.
          ELSE.
            <ls_sales_order_delivery>-DeliveryStatus = '未出库'.
          ENDIF.

        ELSE.

          <ls_sales_order_delivery>-DeliveryStatus = '未出库'.

        ENDIF.

      ENDLOOP.

    ENDIF.
  ENDMETHOD.

ENDCLASS.
