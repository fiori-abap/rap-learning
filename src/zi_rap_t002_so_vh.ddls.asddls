@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Value Help'
@Search.searchable: true
define view entity ZI_RAP_T002_SO_VH
  as select from vbak
{
  @Search.defaultSearchElement: true
  key vbeln as SalesOrder,

  @Search.defaultSearchElement: true
      auart as SalesOrderType,

      audat as SalesOrderDate,
      vkorg as SalesOrganization,

  @Search.defaultSearchElement: true
      kunnr as SoldToParty
}
