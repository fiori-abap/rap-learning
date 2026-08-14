CLASS lcl_buffer DEFINITION FINAL.
  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_item,
        sales_order      TYPE zrap_t003_addon-sales_order,
        sales_order_item TYPE zrap_t003_addon-sales_order_item,
        item_note        TYPE zrap_t003_addon-item_note,
      END OF ty_item,

      tt_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

    CLASS-DATA gt_item TYPE tt_item.

ENDCLASS.

CLASS lcl_buffer IMPLEMENTATION.
ENDCLASS.

CLASS lhc_SalesOrderHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE SalesOrderHeader.

    METHODS read FOR READ
      IMPORTING keys FOR READ SalesOrderHeader RESULT result.

    METHODS rba_Items FOR READ
      IMPORTING keys_rba FOR READ SalesOrderHeader\_Items FULL result_requested RESULT result LINK association_links.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR SalesOrderHeader RESULT result.

ENDCLASS.

CLASS lhc_SalesOrderHeader IMPLEMENTATION.

  METHOD update.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD rba_Items.
  ENDMETHOD.

  METHOD get_global_authorizations.
    IF requested_authorizations-%update
       = if_abap_behv=>mk-on.

      result-%update =
        if_abap_behv=>auth-unauthorized.

    ENDIF.


*    IF requested_authorizations-%update
*       = if_abap_behv=>mk-on.
*
*      AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
*        ID 'ACTVT' FIELD '02'.
*
*      IF sy-subrc = 0.
*        result-%update =
*          if_abap_behv=>auth-allowed.
*      ELSE.
*        result-%update =
*          if_abap_behv=>auth-unauthorized.
*      ENDIF.
*
*    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_SalesOrderItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE SalesOrderItem.

    METHODS read FOR READ
      IMPORTING keys FOR READ SalesOrderItem RESULT result.

    METHODS rba_Header FOR READ
      IMPORTING keys_rba FOR READ SalesOrderItem\_Header FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_SalesOrderItem IMPLEMENTATION.

  METHOD update.

    LOOP AT entities INTO DATA(ls_entity).

      "只处理前台实际修改过的 ItemNote
      CHECK ls_entity-%control-ItemNote = if_abap_behv=>mk-on.

      "同一个明细在一次事务中可能被多次修改
      READ TABLE lcl_buffer=>gt_item
        ASSIGNING FIELD-SYMBOL(<ls_buffer>)
        WITH KEY
          sales_order      = ls_entity-SalesOrder
          sales_order_item = ls_entity-SalesOrderItem.

      IF sy-subrc = 0.

        "缓冲区已有记录时，用最新值覆盖
        <ls_buffer>-item_note = ls_entity-ItemNote.

      ELSE.

        "首次修改时加入缓冲区
        APPEND VALUE #(
          sales_order      = ls_entity-SalesOrder
          sales_order_item = ls_entity-SalesOrderItem
          item_note        = ls_entity-ItemNote
        ) TO lcl_buffer=>gt_item.

      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD rba_Header.
    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<ls_item>).

      INSERT VALUE #(
        source-%tky = <ls_item>-%tky
        target-%tky = VALUE #(
          SalesOrder = <ls_item>-SalesOrder
        )
      ) INTO TABLE association_links.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_RAP_T003_HEADER DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_RAP_T003_HEADER IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
    "没有前台修改数据，不检查
    IF lcl_buffer=>gt_item IS INITIAL.
      RETURN.
    ENDIF.

    "直接在DB层判断：
    "是否存在 销售订单 + 明细 + 备注 全部相同的数据
    SELECT sales_order,
           sales_order_item
      FROM zrap_t003_addon
      FOR ALL ENTRIES IN @lcl_buffer=>gt_item
      WHERE sales_order      = @lcl_buffer=>gt_item-sales_order
        AND sales_order_item = @lcl_buffer=>gt_item-sales_order_item
        AND item_note        = @lcl_buffer=>gt_item-item_note
      INTO TABLE @DATA(lt_same).

    "只要有一条完全相同，本次保存全部停止
    IF lt_same IS NOT INITIAL.

      DATA(ls_same) = lt_same[ 1 ].

      APPEND VALUE #(
        SalesOrder     = ls_same-sales_order
        SalesOrderItem = ls_same-sales_order_item
        %fail = VALUE #(
          cause = if_abap_behv=>cause-unspecific
        )
      ) TO failed-SalesOrderItem.

      APPEND VALUE #(
        SalesOrder     = ls_same-sales_order
        SalesOrderItem = ls_same-sales_order_item
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = '存在与数据库相同的数据，本次未执行保存'
        )
      ) TO reported-SalesOrderItem.

    ENDIF.

  ENDMETHOD.

  METHOD save.

    "没有明细发生修改时，不进行数据库处理
    IF lcl_buffer=>gt_item IS INITIAL.
      RETURN.
    ENDIF.

    DATA lv_timestamp TYPE abp_locinst_lastchange_tstmpl.

    GET TIME STAMP FIELD lv_timestamp.

    DATA lt_addon TYPE STANDARD TABLE OF zrap_t003_addon
                  WITH EMPTY KEY.

    lt_addon = VALUE #(
      FOR ls_item IN lcl_buffer=>gt_item
      (
        client                 = sy-mandt
        sales_order            = ls_item-sales_order
        sales_order_item       = ls_item-sales_order_item
        item_note              = ls_item-item_note
        local_last_changed_at  = lv_timestamp
      )
    ).

    MODIFY zrap_t003_addon FROM TABLE @lt_addon.

  ENDMETHOD.

  METHOD cleanup.
    CLEAR lcl_buffer=>gt_item.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
