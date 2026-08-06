@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '销售订单抬头投影视图'
@Metadata.allowExtensions: true

define root view entity ZC_RAP_T003_HEADER
  provider contract transactional_query
  as projection on ZI_RAP_T003_HEADER
{
  key SalesOrder,

      SalesOrderType,
      CreatedOn,
      SalesOrganization,
      DistributionChannel,
      Division,
      SoldToParty,
      NetValue,
      TransactionCurrency,

      _Items : redirected to composition child ZC_RAP_T003_ITEM
}
