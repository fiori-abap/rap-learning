class ZCL_ZCAP_T002_MPC definition
  public
  inheriting from /IWBEP/CL_V4_ABS_MODEL_PROV
  create public .

public section.

  types:
     TS_SALESORDERHEADER type VBAK .
  types:
     TT_SALESORDERHEADER type standard table of TS_SALESORDERHEADER .
  types:
     TS_SALESORDERITEM type VBAP .
  types:
     TT_SALESORDERITEM type standard table of TS_SALESORDERITEM .

  methods /IWBEP/IF_V4_MP_BASIC~DEFINE
    redefinition .
protected section.
private section.

  methods DEFINE_SALESORDERHEADER
    importing
      !IO_MODEL type ref to /IWBEP/IF_V4_MED_MODEL
    raising
      /IWBEP/CX_GATEWAY .
  methods DEFINE_SALESORDERITEM
    importing
      !IO_MODEL type ref to /IWBEP/IF_V4_MED_MODEL
    raising
      /IWBEP/CX_GATEWAY .
ENDCLASS.



CLASS ZCL_ZCAP_T002_MPC IMPLEMENTATION.


  method /IWBEP/IF_V4_MP_BASIC~DEFINE.
*&----------------------------------------------------------------------------------------------*
*&* This class has been generated on 2026/08/17 10:51:35 in client 110
*&*
*&*       WARNING--> NEVER MODIFY THIS CLASS <--WARNING
*&*   If you want to change the MPC implementation, use the
*&*   generated methods inside MPC subclass - ZCL_ZCAP_T002_MPC_EXT
*&-----------------------------------------------------------------------------------------------*
  define_salesorderheader( io_model ).
  define_salesorderitem( io_model ).
  endmethod.


  method DEFINE_SALESORDERHEADER.
*&----------------------------------------------------------------------------------------------*
*&* This class has been generated on 2026/08/17 10:51:35 in client 110
*&*
*&*       WARNING--> NEVER MODIFY THIS CLASS <--WARNING
*&*   If you want to change the MPC implementation, use the
*&*   generated methods inside MPC subclass - ZCL_ZCAP_T002_MPC_EXT
*&-----------------------------------------------------------------------------------------------*

 DATA lo_entity_type    TYPE REF TO /iwbep/if_v4_med_entity_type.
 DATA lo_property       TYPE REF TO /iwbep/if_v4_med_prim_prop.
 DATA lo_entity_set     TYPE REF TO /iwbep/if_v4_med_entity_set.
 DATA lo_nav_prop       TYPE REF TO /iwbep/if_v4_med_nav_prop.
 DATA lv_SALESORDERHEADER  TYPE vbak.
***********************************************************************************************************************************
*   ENTITY - SalesOrderHeader
***********************************************************************************************************************************
 lo_entity_type = io_model->create_entity_type_by_struct( iv_entity_type_name = 'SALESORDERHEADER' is_structure = lv_SALESORDERHEADER
                                                          iv_add_conv_to_prim_props = abap_true ). "#EC NOTEXT

 lo_entity_type->set_edm_name( 'SalesOrderHeader' ).        "#EC NOTEXT

***********************************************************************************************************************************
*   Properties
***********************************************************************************************************************************
 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'VBELN' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'SalesOrder' ).                 "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_is_key( ).
 lo_property->set_max_length( iv_max_length = '10' ).       "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'ERDAT' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'CreatedOn' ).                  "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'Date' ).         "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'ERNAM' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'CreatedBy' ).                  "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '12' ).       "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'AUDAT' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'DocumentDate' ).               "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'Date' ).         "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'AUART' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'SalesOrderType' ).             "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '4' ).        "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'NETWR' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'NetValue' ).                   "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'Decimal' ).      "#EC NOTEXT
 lo_property->set_precision( iv_precision = '16' ).         "#EC NOTEXT
 lo_property->set_scale( iv_scale = '3' ).                  "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'WAERK' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'Currency' ).                   "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '5' ).        "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'VKORG' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'SalesOrganization' ).          "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '4' ).        "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'VTWEG' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'DistributionChannel' ).        "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '2' ).        "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'SPART' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'Division' ).                   "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '2' ).        "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'BSTNK' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'CustomerPO' ).                 "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '20' ).       "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'KUNNR' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'SoldToParty' ).                "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '10' ).       "#EC NOTEXT


***********************************************************************************************************************************
*   Navigation Properties
***********************************************************************************************************************************
 lo_nav_prop = lo_entity_type->create_navigation_property( iv_property_name = 'ITEMS' ). "#EC NOTEXT
 lo_nav_prop->set_edm_name( 'Items' ).                      "#EC NOTEXT
 lo_nav_prop->set_target_entity_type_name( 'SALESORDERITEM' ).
 lo_nav_prop->set_target_multiplicity( 'N' ).
 lo_nav_prop->set_on_delete_action( 'None' ).               "#EC NOTEXT


***********************************************************************************************************************************
*   ENTITY SETS
***********************************************************************************************************************************
 lo_entity_set = lo_entity_type->create_entity_set( 'SALESORDERHEADERSET' ). "#EC NOTEXT
 lo_entity_set->set_edm_name( 'SalesOrderHeaderSet' ).      "#EC NOTEXT

 lo_entity_set->add_navigation_prop_binding( iv_navigation_property_path = 'ITEMS'
                                                              iv_target_entity_set = 'SALESORDERITEMSET' ). "#EC NOTEXT
  endmethod.


  method DEFINE_SALESORDERITEM.
*&----------------------------------------------------------------------------------------------*
*&* This class has been generated on 2026/08/17 10:51:35 in client 110
*&*
*&*       WARNING--> NEVER MODIFY THIS CLASS <--WARNING
*&*   If you want to change the MPC implementation, use the
*&*   generated methods inside MPC subclass - ZCL_ZCAP_T002_MPC_EXT
*&-----------------------------------------------------------------------------------------------*

 DATA lo_entity_type    TYPE REF TO /iwbep/if_v4_med_entity_type.
 DATA lo_property       TYPE REF TO /iwbep/if_v4_med_prim_prop.
 DATA lo_entity_set     TYPE REF TO /iwbep/if_v4_med_entity_set.
 DATA lv_SALESORDERITEM  TYPE vbap.
***********************************************************************************************************************************
*   ENTITY - SalesOrderItem
***********************************************************************************************************************************
 lo_entity_type = io_model->create_entity_type_by_struct( iv_entity_type_name = 'SALESORDERITEM' is_structure = lv_SALESORDERITEM
                                                          iv_add_conv_to_prim_props = abap_true ). "#EC NOTEXT

 lo_entity_type->set_edm_name( 'SalesOrderItem' ).          "#EC NOTEXT

***********************************************************************************************************************************
*   Properties
***********************************************************************************************************************************
 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'VBELN' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'SalesOrder' ).                 "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_is_key( ).
 lo_property->set_max_length( iv_max_length = '10' ).       "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'POSNR' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'ItemNumber' ).                 "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_is_key( ).
 lo_property->set_max_length( iv_max_length = '6' ).        "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'MATNR' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'Material' ).                   "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '40' ).       "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'ARKTX' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'Description' ).                "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '40' ).       "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'PSTYV' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'ItemCategory' ).               "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '4' ).        "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'ABGRU' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'RejectionReason' ).            "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '2' ).        "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'NETWR' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'NetValue' ).                   "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'Decimal' ).      "#EC NOTEXT
 lo_property->set_precision( iv_precision = '16' ).         "#EC NOTEXT
 lo_property->set_scale( iv_scale = '3' ).                  "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'KWMENG' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'OrderQuantity' ).              "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'Decimal' ).      "#EC NOTEXT
 lo_property->set_precision( iv_precision = '15' ).         "#EC NOTEXT
 lo_property->set_scale( iv_scale = '3' ).                  "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'VRKME' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'OrderUnit' ).                  "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '3' ).        "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'WERKS' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'Plant' ).                      "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '4' ).        "#EC NOTEXT

 lo_property = lo_entity_type->create_prim_property( iv_property_name = 'LGORT' ). "#EC NOTEXT
 lo_property->set_add_annotations( abap_true ).
 lo_property->set_edm_name( 'StorageLocation' ).            "#EC NOTEXT
 lo_property->set_edm_type( iv_edm_type = 'String' ).       "#EC NOTEXT
 lo_property->set_max_length( iv_max_length = '4' ).        "#EC NOTEXT


***********************************************************************************************************************************
*   ENTITY SETS
***********************************************************************************************************************************
 lo_entity_set = lo_entity_type->create_entity_set( 'SALESORDERITEMSET' ). "#EC NOTEXT
 lo_entity_set->set_edm_name( 'SalesOrderItemSet' ).        "#EC NOTEXT
  endmethod.
ENDCLASS.
