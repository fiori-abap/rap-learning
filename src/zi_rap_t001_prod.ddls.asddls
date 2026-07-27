@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RAP Product Interface View'
define root view entity ZI_RAP_T001_PROD
  as select from zrap_t001_prod
{
  key product_uuid          as ProductUuid,

      product_id            as ProductId,
      product_name          as ProductName,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,

      currency_code         as CurrencyCode,

      stock                 as Stock,
      status                as Status,

      created_by            as CreatedBy,
      created_at            as CreatedAt,
      last_changed_by       as LastChangedBy,
      last_changed_at       as LastChangedAt,
      local_last_changed_at as LocalLastChangedAt
}
