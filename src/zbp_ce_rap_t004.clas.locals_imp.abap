CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_update,
        sales_order      TYPE vbeln_va,
        sales_order_item TYPE posnr_va,
        process_status   TYPE c LENGTH 10,
      END OF ty_update,

      tt_update TYPE STANDARD TABLE OF ty_update WITH EMPTY KEY.

    CLASS-DATA gt_update TYPE tt_update.

ENDCLASS.

CLASS lhc_ZCE_RAP_T004 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zce_rap_t004.

    METHODS read FOR READ
      IMPORTING keys FOR READ zce_rap_t004 RESULT result.

ENDCLASS.

CLASS lhc_ZCE_RAP_T004 IMPLEMENTATION.

  METHOD update.
    DATA:
      ls_entity  TYPE STRUCTURE FOR UPDATE zce_rap_t004,
      ls_update  TYPE lcl_buffer=>ty_update,
      lo_query   TYPE REF TO zcl_rap_t004_query,
      lv_success TYPE abap_bool,
      lv_message TYPE string.

    LOOP AT entities INTO ls_entity.

      IF ls_entity-%control-ProcessStatus = if_abap_behv=>mk-on.

        DELETE lcl_buffer=>gt_update
          WHERE sales_order      = ls_entity-SalesOrder
            AND sales_order_item = ls_entity-SalesOrderItem.

        CLEAR ls_update.

        ls_update-sales_order      = ls_entity-SalesOrder.
        ls_update-sales_order_item = ls_entity-SalesOrderItem.
        ls_update-process_status   = ls_entity-ProcessStatus.

        APPEND ls_update TO lcl_buffer=>gt_update.

        APPEND new_message_with_text(
          severity = if_abap_behv_message=>severity-success
          text     = '处理状态更新成功'
        ) TO reported-%other.


      ENDIF.

      IF ls_entity-%control-CommentText = if_abap_behv=>mk-on.

        CLEAR:
          lv_success,
          lv_message.

        CREATE OBJECT lo_query.

        CALL METHOD lo_query->update_comment
          EXPORTING
            iv_sales_order      = ls_entity-SalesOrder
            iv_sales_order_item = ls_entity-SalesOrderItem
            iv_comment_text     = ls_entity-CommentText
          IMPORTING
            ev_success          = lv_success
            ev_message          = lv_message.


        IF lv_success = abap_true.

          APPEND new_message_with_text(
            severity = if_abap_behv_message=>severity-success
            text     = lv_message
          ) TO reported-%other.

        ELSE.

*          APPEND VALUE #(
*            %tky = ls_entity-%tky
*          ) TO failed-zce_rap_t004.

          APPEND new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = lv_message
          ) TO reported-%other.

        ENDIF.

      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZCE_RAP_T004 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZCE_RAP_T004 IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    DATA:
      ls_update TYPE lcl_buffer=>ty_update,
      ls_db     TYPE zrap_t004_d.

    LOOP AT lcl_buffer=>gt_update INTO ls_update.

      "先尝试更新已有数据
      UPDATE zrap_t004_d
        SET process_status = ls_update-process_status
        WHERE sales_order      = ls_update-sales_order
          AND sales_order_item = ls_update-sales_order_item.

      "没有数据时，新建一条
      IF sy-subrc <> 0.

        CLEAR ls_db.

        ls_db-client           = sy-mandt.
        ls_db-sales_order      = ls_update-sales_order.
        ls_db-sales_order_item = ls_update-sales_order_item.
        ls_db-process_status   = ls_update-process_status.

        INSERT zrap_t004_d FROM ls_db.

      ENDIF.

*      APPEND new_message_with_text(
*          severity = if_abap_behv_message=>severity-success
*          text     = '处理状态更新成功'
*        ) TO reported-%other.

    ENDLOOP.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR lcl_buffer=>gt_update.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
