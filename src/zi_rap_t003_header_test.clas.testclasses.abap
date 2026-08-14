"!@testing ZI_RAP_T003_HEADER
CLASS ltc_ZI_RAP_T003_HEADER
  DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CLASS-DATA:
      environment TYPE REF TO if_cds_test_environment.

    CLASS-METHODS:
      class_setup RAISING cx_static_check,
      class_teardown.

    DATA:
      act_results TYPE STANDARD TABLE OF zi_rap_t003_header
                  WITH EMPTY KEY,

      lt_vbak     TYPE STANDARD TABLE OF vbak
                  WITH EMPTY KEY.

    METHODS:
      setup RAISING cx_static_check,

      prepare_testdata_set,

      aunit_for_cds_method
        FOR TESTING
        RAISING cx_static_check.

ENDCLASS.


CLASS ltc_ZI_RAP_T003_HEADER IMPLEMENTATION.


  METHOD class_setup.

    environment =
      cl_cds_test_environment=>create(
        i_for_entity = 'ZI_RAP_T003_HEADER'
      ).

  ENDMETHOD.


  METHOD setup.

    environment->clear_doubles( ).

  ENDMETHOD.


  METHOD class_teardown.

    environment->destroy( ).

  ENDMETHOD.


  METHOD prepare_testdata_set.

    "测试数据：
    "订单1属于H100
    "订单2属于H200
    lt_vbak = VALUE #(
      (
        mandt = sy-mandt
        vbeln = '0000000001'
        auart = 'OR'
        vkorg = 'H100'
      )
      (
        mandt = sy-mandt
        vbeln = '0000000002'
        auart = 'OR'
        vkorg = 'H200'
      )
    ).

    environment->insert_test_data(
      i_data = lt_vbak
    ).

  ENDMETHOD.


  METHOD aunit_for_cds_method.

    "--------------------------------------------------
    "1. 准备假的VBAK数据
    "--------------------------------------------------
    prepare_testdata_set( ).


    "--------------------------------------------------
    "2. 模拟当前用户的PFCG权限
    "
    "V_VBAK_VKO
    "VKORG = H100
    "ACTVT = 03
    "--------------------------------------------------
    DATA(access_control_data) =
      cl_cds_test_data=>create_access_control_data(

        i_role_authorizations = VALUE #(

          (
            object = 'V_VBAK_VKO'

            authorizations = VALUE #(

              (
                VALUE #(

                  (
                    fieldname = 'VKORG'

                    fieldvalues = VALUE #(
                      (
                        lower_value = 'H100'
                      )
                    )
                  )

                  (
                    fieldname = 'ACTVT'

                    fieldvalues = VALUE #(
                      (
                        lower_value = '03'
                      )
                    )
                  )

                )
              )

            )
          )

        )
      ).


    "--------------------------------------------------
    "3. 启用DCL，并使用上面的假权限
    "--------------------------------------------------
    DATA(lo_access_control) =
      environment->get_access_control_double( ).

    lo_access_control->enable_access_control(
      i_access_control_data = access_control_data
    ).


    "--------------------------------------------------
    "4. 正常SELECT CDS
    "--------------------------------------------------
    SELECT *
      FROM zi_rap_t003_header
      INTO TABLE @act_results.


    "--------------------------------------------------
    "5. 验证结果
    "
    "H200应该被DCL过滤掉
    "所以只能剩1条H100
    "--------------------------------------------------
    cl_abap_unit_assert=>assert_equals(
      act = lines( act_results )
      exp = 1
    ).


    cl_abap_unit_assert=>assert_equals(
      act = act_results[ 1 ]-SalesOrganization
      exp = 'H100'
    ).

  ENDMETHOD.


ENDCLASS.
