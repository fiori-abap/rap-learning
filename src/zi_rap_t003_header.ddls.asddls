@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '销售订单抬头接口视图'
@Metadata.allowExtensions: true

define root view entity ZI_RAP_T003_HEADER
  as select from vbak as Header

  composition [0..*] of ZI_RAP_T003_ITEM as _Items

{
      @Consumption.valueHelpDefinition: [
        {
          entity: {
            name: 'ZI_RAP_T002_SO_VH',
            element: 'SalesOrder'
          }
        }
      ]
  key Header.vbeln as SalesOrder,

      Header.auart as SalesOrderType,
      Header.erdat as CreatedOn,
      Header.vkorg as SalesOrganization,
      @EndUserText.label: '分销渠道'
      Header.vtweg as DistributionChannel,
      @EndUserText.label: '产品组'
      Header.spart as Division,
      Header.kunnr as SoldToParty,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      Header.netwr as NetValue,
      @EndUserText.label: '订单货币'
      Header.waerk as TransactionCurrency,

      _Items
}
