@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Managed RAP 商品维护 Projection'
@Metadata.allowExtensions: true

define root view entity ZC_RAP_T005
  provider contract transactional_query
  as projection on ZI_RAP_T005
{
  key ID,
      Name,
      Description,
      Amount,
      Status,
      LocalLastChangedAt,
      LastChangedAt
}
