@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Managed RAP 商品维护 Interface'

define root view entity ZI_RAP_T005
  as select from zrap_t005
{
  key id                    as ID,
      name                  as Name,
      description           as Description,
      amount                as Amount,
      @Consumption.valueHelpDefinition: [
      {
      entity: {
      name   : 'ZI_RAP_T005_STATUS_VH',
      element: 'Status'
      }
      }
      ]
      status                as Status,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt
}
