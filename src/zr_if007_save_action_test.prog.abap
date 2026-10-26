*&---------------------------------------------------------------------*
*& Report zr_if007_save_action_test
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zr_if007_save_action_test.

DATA lv_json TYPE string.

"测试一条SAP订单，只更新SAP本地表
lv_json =
  '{"rows":[' &&
  '{"orderNo":"0000000004",' &&
  '"itemNo":"000010",' &&
  '"followUpDate":"2026-11-01",' &&
  '"commentText":"IF007 SAP Action Test",' &&
  '"sapStatus":"PROC"}' &&
  ']}'.

"1. 调用自定义 RAP Action
MODIFY ENTITIES OF zi_if007_addon
  ENTITY Addon
  EXECUTE saveBatch
  FROM VALUE #(
    (
      %cid = 'TEST_S'
      %param = VALUE #(
        SaveMode = 'S'
        RowsJson = lv_json
      )
    )
  )
  RESULT DATA(lt_result)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).

"2. 查看Action返回结果
LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<ls_result>).

  WRITE: / 'SAP Status:',
           <ls_result>-%param-SapStatus.

  WRITE: / 'SAP Message:',
           <ls_result>-%param-SapMessage.

  WRITE: / 'Cloud Status:',
           <ls_result>-%param-CloudStatus.

ENDLOOP.

"3. 检查Action是否失败
IF ls_failed IS NOT INITIAL.

  WRITE: / 'Action FAILED'.

  ROLLBACK ENTITIES.
  RETURN.

ENDIF.

"4. 正式提交Managed RAP修改
COMMIT ENTITIES RESPONSES
  FAILED DATA(ls_commit_failed)
  REPORTED DATA(ls_commit_reported).

IF ls_commit_failed IS INITIAL.

  WRITE: / 'COMMIT: SUCCESS'.

ELSE.

  WRITE: / 'COMMIT: FAILED'.

ENDIF.
