@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IF006 External Data Projection'
@Metadata.allowExtensions: true

define root view entity ZC_RAP_IF006
  provider contract transactional_query
  as projection on ZI_RAP_IF006
{
  key ExternalOrderNo,
  key ExternalItemNo,

      Material,
      Amount,
      Currency,
      Status,
      SourceSystem,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
