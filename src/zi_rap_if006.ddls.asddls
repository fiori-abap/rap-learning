@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IF006 External Data'
@Metadata.allowExtensions: true

define root view entity ZI_RAP_IF006
  as select from zrap_if006
{
  key external_order_no     as ExternalOrderNo,
  key external_item_no      as ExternalItemNo,

      material              as Material,

      @Semantics.amount.currencyCode: 'Currency'
      amount                as Amount,

      currency              as Currency,

      status                as Status,
      source_system         as SourceSystem,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt
}
