CLASS zcl_rap_t001_fill DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.


CLASS zcl_rap_t001_fill IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA lv_now TYPE timestampl.

    GET TIME STAMP FIELD lv_now.

    DELETE FROM zrap_t001_prod.

    TRY.
        DATA(lv_uuid1) = cl_system_uuid=>create_uuid_x16_static( ).
        DATA(lv_uuid2) = cl_system_uuid=>create_uuid_x16_static( ).
        DATA(lv_uuid3) = cl_system_uuid=>create_uuid_x16_static( ).

      CATCH cx_uuid_error INTO DATA(lx_uuid).
        out->write( lx_uuid->get_text( ) ).
        RETURN.
    ENDTRY.

    DATA lt_products TYPE STANDARD TABLE OF zrap_t001_prod.

    lt_products = VALUE #(
      (
        client                 = sy-mandt
        product_uuid           = lv_uuid1
        product_id             = 'P001'
        product_name           = 'Notebook PC'
        price                  = 120000
        currency_code          = 'JPY'
        stock                  = 10
        status                 = 'A'
        created_by             = sy-uname
        created_at             = lv_now
        last_changed_by        = sy-uname
        last_changed_at        = lv_now
        local_last_changed_at  = lv_now
      )
      (
        client                 = sy-mandt
        product_uuid           = lv_uuid2
        product_id             = 'P002'
        product_name           = 'Monitor'
        price                  = 35000
        currency_code          = 'JPY'
        stock                  = 25
        status                 = 'A'
        created_by             = sy-uname
        created_at             = lv_now
        last_changed_by        = sy-uname
        last_changed_at        = lv_now
        local_last_changed_at  = lv_now
      )
      (
        client                 = sy-mandt
        product_uuid           = lv_uuid3
        product_id             = 'P003'
        product_name           = 'Keyboard'
        price                  = 8000
        currency_code          = 'JPY'
        stock                  = 50
        status                 = 'A'
        created_by             = sy-uname
        created_at             = lv_now
        last_changed_by        = sy-uname
        last_changed_at        = lv_now
        local_last_changed_at  = lv_now
      )
    ).

    INSERT zrap_t001_prod FROM TABLE @lt_products.

    DATA(lv_count) = sy-dbcnt.

    COMMIT WORK.

    out->write( |Inserted { lv_count } product records.| ).

  ENDMETHOD.

ENDCLASS.
