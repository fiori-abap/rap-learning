CLASS zcl_rap_t002_eml_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

ENDCLASS.


CLASS zcl_rap_t002_eml_test IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

*
* 画面中显示：
*
* Sales Order = 2
* Item        = 10
*
* ABAP 内部格式为：
*
* 0000000002
* 000010
*/
    MODIFY ENTITIES OF zi_rap_t002_so
      ENTITY SalesOrderItem
        UPDATE FIELDS (
          AddonStatus
          AddonRemark
        )
        WITH VALUE #(
          (
            SalesOrder =
              '0000000002'

            SalesOrderItem =
              '000010'

            AddonStatus =
              '1'

            AddonRemark =
              'EML backend save test'
          )
        )
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

*
* MODIFY 阶段失败时，
* 不进入 Save。
*/
    IF ls_failed-SalesOrderItem
         IS NOT INITIAL.

    out->write(
      'MODIFY ENTITIES failed'
    ).

    out->write(
      ls_failed-SalesOrderItem
    ).

    IF ls_reported-SalesOrderItem
         IS NOT INITIAL.

      out->write(
        ls_reported-SalesOrderItem
      ).

    ENDIF.

    ROLLBACK ENTITIES.

    RETURN.

  ENDIF.

  out->write(
    'MODIFY ENTITIES succeeded'
  ).

*
* 当前代码位于 Behavior Pool 外部，
* 所以必须显式触发 rap Save Sequence。
*
* 这里不要使用 COMMIT work。
*/
  COMMIT ENTITIES.

  IF sy-subrc <> 0.

    out->write(
      'COMMIT ENTITIES failed'
    ).

    RETURN.

  ENDIF.

  out->write(
    'COMMIT ENTITIES succeeded'
  ).

*
* 保存结束后直接读取 Addon 表，
* 确认数据库中已经产生记录。
*/
  SELECT SINGLE FROM zrap_t002_addon
  FIELDS
  sales_order,
  sales_order_item,
  addon_status,
  addon_remark,
  created_by,
  created_at,
  last_changed_by,
  last_changed_at,
  local_last_changed_at
WHERE sales_order =
        '0000000002'
  AND sales_order_item =
        '000010'
INTO @DATA(ls_saved_addon).

  IF sy-subrc <> 0.

    out->write(
      'ZRAP_T002_ADDON record was not found'
    ).

    RETURN.

  ENDIF.

  out->write(
    'ZRAP_T002_ADDON record:'
  ).

  out->write(
    ls_saved_addon
  ).

ENDMETHOD.

ENDCLASS.
