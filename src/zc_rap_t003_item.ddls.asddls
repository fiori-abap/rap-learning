@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '销售订单明细附加投影视图'
@Metadata.allowExtensions: true

define view entity ZC_RAP_T003_ITEM
  as projection on ZI_RAP_T003_ITEM
{
  key SalesOrder,
  key SalesOrderItem,

      Material,
      MaterialDescription,
      Plant,
      StorageLocation,
      OrderQuantity,
      SalesUnit,
      ItemNote,
      LocalLastChangedAt,

      _Header : redirected to parent ZC_RAP_T003_HEADER
}
