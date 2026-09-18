CLASS lcl_buffer DEFINITION FINAL.

  PUBLIC SECTION.

    CLASS-DATA gt_addon
      TYPE HASHED TABLE OF zrap_t007_a
      WITH UNIQUE KEY source_type document_no.

ENDCLASS.

CLASS lcl_buffer IMPLEMENTATION.
ENDCLASS.
CLASS lhc_Document DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Document RESULT result.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Document.

    METHODS read FOR READ
      IMPORTING keys FOR READ Document RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Document.

ENDCLASS.

CLASS lhc_Document IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD update.
    LOOP AT entities INTO DATA(ls_entity).

      DATA ls_addon TYPE zrap_t007_a.

      "同一次事务中已经改过的话，先从 Buffer 取
      READ TABLE lcl_buffer=>gt_addon
        INTO ls_addon
        WITH TABLE KEY
          source_type = ls_entity-SourceType
          document_no = ls_entity-DocumentNo.

      IF sy-subrc <> 0.

        "没有 Buffer 数据，再查正式 Addon 表
        SELECT SINGLE *
          FROM zrap_t007_a
          WHERE source_type = @ls_entity-SourceType
            AND document_no = @ls_entity-DocumentNo
          INTO @ls_addon.

        "第一次维护这张单据
        IF sy-subrc <> 0.

          ls_addon-client      = sy-mandt.
          ls_addon-source_type = ls_entity-SourceType.
          ls_addon-document_no = ls_entity-DocumentNo.

          ls_addon-created_by = sy-uname.

          GET TIME STAMP FIELD ls_addon-created_at.

        ENDIF.

      ENDIF.


      "只修改这次真正传进来的字段
      IF ls_entity-%control-PartnerNo = if_abap_behv=>mk-on.
        ls_addon-partner_no = ls_entity-PartnerNo.
      ENDIF.

      IF ls_entity-%control-PartnerName = if_abap_behv=>mk-on.
        ls_addon-partner_name = ls_entity-PartnerName.
      ENDIF.

      IF ls_entity-%control-AddressNumber = if_abap_behv=>mk-on.
        ls_addon-address_number = ls_entity-AddressNumber.
      ENDIF.

      IF ls_entity-%control-PostalCode = if_abap_behv=>mk-on.
        ls_addon-postal_code = ls_entity-PostalCode.
      ENDIF.

      IF ls_entity-%control-Region = if_abap_behv=>mk-on.
        ls_addon-region = ls_entity-Region.
      ENDIF.

      IF ls_entity-%control-City = if_abap_behv=>mk-on.
        ls_addon-city = ls_entity-City.
      ENDIF.

      IF ls_entity-%control-Street = if_abap_behv=>mk-on.
        ls_addon-street = ls_entity-Street.
      ENDIF.

      IF ls_entity-%control-HouseNumber = if_abap_behv=>mk-on.
        ls_addon-house_number = ls_entity-HouseNumber.
      ENDIF.

      IF ls_entity-%control-Country = if_abap_behv=>mk-on.
        ls_addon-country = ls_entity-Country.
      ENDIF.

      IF ls_entity-%control-CommentText = if_abap_behv=>mk-on.
        ls_addon-comment_text = ls_entity-CommentText.
      ENDIF.


      ls_addon-last_changed_by = sy-uname.

      GET TIME STAMP FIELD ls_addon-last_changed_at.

      ls_addon-local_last_changed_at =
        ls_addon-last_changed_at.


      "同一个 Key 如果 Buffer 已经有旧版本，先替换掉
      DELETE TABLE lcl_buffer=>gt_addon
        WITH TABLE KEY
          source_type = ls_entity-SourceType
          document_no = ls_entity-DocumentNo.

      INSERT ls_addon
        INTO TABLE lcl_buffer=>gt_addon.

    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    SELECT FROM zi_rap_t007_doc
    FIELDS *
    FOR ALL ENTRIES IN @keys
    WHERE SourceType = @keys-SourceType
      AND DocumentNo = @keys-DocumentNo
    INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_RAP_T007_DOC DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_RAP_T007_DOC IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    IF lcl_buffer=>gt_addon IS NOT INITIAL.

      MODIFY zrap_t007_a
        FROM TABLE @lcl_buffer=>gt_addon.

    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR lcl_buffer=>gt_addon.
  ENDMETHOD.

  METHOD cleanup_finalize.
    CLEAR lcl_buffer=>gt_addon.
  ENDMETHOD.

ENDCLASS.
