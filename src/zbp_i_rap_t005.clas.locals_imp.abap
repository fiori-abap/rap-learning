CLASS lsc_zi_rap_t005 DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zi_rap_t005 IMPLEMENTATION.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_zi_rap_t005 DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateAmount FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_rap_t005~validateAmount.
    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zi_rap_t005~setInitialStatus.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zi_rap_t005 RESULT result.
    METHODS closeproduct FOR MODIFY
      IMPORTING keys FOR ACTION zi_rap_t005~closeproduct RESULT result.
    METHODS validatemandatoryfields FOR VALIDATE ON SAVE
      IMPORTING keys FOR zi_rap_t005~validatemandatoryfields.

ENDCLASS.

CLASS lhc_zi_rap_t005 IMPLEMENTATION.

  METHOD validateAmount.

    READ ENTITIES OF zi_rap_t005 IN LOCAL MODE
    ENTITY zi_rap_t005
      FIELDS ( Amount )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_product).

    LOOP AT lt_product INTO DATA(ls_product)
         WHERE Amount < 0.

      APPEND VALUE #(
        %tky = ls_product-%tky
      ) TO failed-zi_rap_t005.

      APPEND VALUE #(
        %tky = ls_product-%tky

        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = '金额不能小于0'
        )

        %element-Amount = if_abap_behv=>mk-on
      ) TO reported-zi_rap_t005.

    ENDLOOP.
  ENDMETHOD.

  METHOD setInitialStatus.

    DATA(lt_keys) = keys.

    DELETE lt_keys
      WHERE %is_draft = if_abap_behv=>mk-off.

    CHECK lt_keys IS NOT INITIAL.

    READ ENTITIES OF zi_rap_t005 IN LOCAL MODE
    ENTITY zi_rap_t005
      FIELDS ( Status )
      WITH CORRESPONDING #( lt_keys )
    RESULT DATA(lt_product).

    DELETE lt_product WHERE Status IS NOT INITIAL.

    CHECK lt_product IS NOT INITIAL.

    LOOP AT lt_product ASSIGNING FIELD-SYMBOL(<ls_product>).
      <ls_product>-Status = 'OPEN'.
    ENDLOOP.

    MODIFY ENTITIES OF zi_rap_t005 IN LOCAL MODE
      ENTITY zi_rap_t005
        UPDATE FIELDS ( Status )
        WITH CORRESPONDING #( lt_product ).

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zi_rap_t005 IN LOCAL MODE
    ENTITY zi_rap_t005
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_product).

    result = VALUE #(
      FOR ls_product IN lt_product
      (
        %tky = ls_product-%tky

        %field-Amount =
          COND #(
            WHEN ls_product-Status = 'CLOSED'
            THEN if_abap_behv=>fc-f-read_only
            ELSE if_abap_behv=>fc-f-unrestricted
          )

        %features-%action-CloseProduct =
          COND #(
            WHEN ls_product-Status = 'CLOSED'
            THEN if_abap_behv=>fc-o-disabled
            ELSE if_abap_behv=>fc-o-enabled
          )
      )
    ).

  ENDMETHOD.

  METHOD CloseProduct.

    MODIFY ENTITIES OF zi_rap_t005 IN LOCAL MODE
      ENTITY zi_rap_t005
        UPDATE FIELDS ( Status )
        WITH VALUE #(
          FOR key IN keys
          (
            %tky   = key-%tky
            Status = 'CLOSED'
          )
        )
      FAILED failed
      REPORTED reported.

    READ ENTITIES OF zi_rap_t005 IN LOCAL MODE
      ENTITY zi_rap_t005
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_product).

    result = VALUE #(
      FOR ls_product IN lt_product
      (
        %tky   = ls_product-%tky
        %param = ls_product
      )
    ).
  ENDMETHOD.

  METHOD validateMandatoryFields.
    READ ENTITIES OF zi_rap_t005 IN LOCAL MODE
    ENTITY zi_rap_t005
      FIELDS ( Name Status )
      WITH CORRESPONDING #( keys )
    RESULT DATA(lt_product).

    LOOP AT lt_product INTO DATA(ls_product).

      "只要有一个必填字段为空，就阻止保存
      IF ls_product-Name IS INITIAL
      OR ls_product-Status IS INITIAL.

        APPEND VALUE #(
          %tky = ls_product-%tky
        ) TO failed-zi_rap_t005.

      ENDIF.


      "商品名称为空
      IF ls_product-Name IS INITIAL.

        APPEND VALUE #(
          %tky = ls_product-%tky

          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = '商品名称不能为空'
          )

          %element-Name = if_abap_behv=>mk-on
        ) TO reported-zi_rap_t005.

      ENDIF.


      "状态为空
      IF ls_product-Status IS INITIAL.

        APPEND VALUE #(
          %tky = ls_product-%tky

          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = '状态不能为空'
          )

          %element-Status = if_abap_behv=>mk-on
        ) TO reported-zi_rap_t005.

      ENDIF.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
