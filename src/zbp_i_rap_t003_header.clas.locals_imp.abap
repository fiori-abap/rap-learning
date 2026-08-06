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

ENDCLASS.

CLASS lhc_SalesOrderHeader IMPLEMENTATION.

  METHOD update.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD rba_Items.
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
