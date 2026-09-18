@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T006 Processing Batch Header Projection'
@Metadata.allowExtensions: true

define root view entity ZC_RAP_T006_H
  provider contract transactional_query
  as projection on ZI_RAP_T006_H
{
  key BatchID,

      BatchName,
      Description,
      Status,
      ProcessingDate,
      ResponsiblePerson,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,

      _Items : redirected to composition child ZC_RAP_T006_I
}
