@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Item Value Help'
@Search.searchable: true
define view entity ZI_RAP_T002_ITEM_VH
  as select from vbap
{
  key vbeln as SalesOrder,
  key posnr as SalesOrderItem,

  @Search.defaultSearchElement: true
      matnr as Material,

  @Search.defaultSearchElement: true
      arktx as MaterialDescription
}
