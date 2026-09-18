@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T006 Processing Batch Item Interface'

define view entity ZI_RAP_T006_I
  as select from zrap_t006_i association to parent ZI_RAP_T006_H as _Header
  on $projection.BatchID = _Header.BatchID
{
  key batch_id               as BatchID,
  key item_id                as ItemID,

      source_type            as SourceType,
      document_no            as DocumentNo,
      document_item          as DocumentItem,
      document_type          as DocumentType,
      document_date          as DocumentDate,

      sales_organization     as SalesOrganization,
      distribution_channel  as DistributionChannel,
      division               as Division,
      customer               as Customer,

      material               as Material,
      material_description   as MaterialDescription,
      plant                  as Plant,
      storage_location       as StorageLocation,

      @Semantics.quantity.unitOfMeasure: 'Unit'
      quantity               as Quantity,

      unit                   as Unit,

      @Semantics.amount.currencyCode: 'Currency'
      net_amount             as NetAmount,

      currency               as Currency,

      reference_document     as ReferenceDocument,
      reference_item         as ReferenceItem,

      process_status         as ProcessStatus,
      comment_text           as CommentText,

      @Semantics.user.createdBy: true
      created_by             as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at             as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by        as LastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at  as LocalLastChangedAt,
      
      _Header
}
