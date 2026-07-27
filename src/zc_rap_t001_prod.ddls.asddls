@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RAP Product Projection View'
@Metadata.allowExtensions: true
define root view entity ZC_RAP_T001_PROD
  provider contract transactional_query
  as projection on ZI_RAP_T001_PROD
{
  key ProductUuid,

      ProductId,
      ProductName,
      Price,
      CurrencyCode,
      Stock,
      Status,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
