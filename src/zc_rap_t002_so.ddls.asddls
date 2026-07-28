@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Addon Projection View'
@Metadata.allowExtensions: true
define root view entity ZC_RAP_T002_SO
  provider contract transactional_query
  as projection on ZI_RAP_T002_SO
{
      @Consumption.valueHelpDefinition: [
        {
          entity: {
            name: 'ZI_RAP_T002_SO_VH',
            element: 'SalesOrder'
          }
        }
      ]
  key SalesOrder,
      @Consumption.valueHelpDefinition: [
              {
                entity: {
                  name: 'ZI_RAP_T002_ITEM_VH',
                  element: 'SalesOrderItem'
                },
                additionalBinding: [
                  {
                    localElement: 'SalesOrder',
                    element: 'SalesOrder',
                    usage: #FILTER_AND_RESULT
                  }
                ]
              }
            ]
  key SalesOrderItem,
      SalesOrderType,
      SalesOrderDate,
      SalesOrganization,
      DistributionChannel,
      Division,
      SoldToParty,

      Material,
      MaterialDescription,
      Plant,
      OrderQuantity,
      SalesUnit,
      NetAmount,
      TransactionCurrency,

      AddonStatus,
      AddonRemark,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
