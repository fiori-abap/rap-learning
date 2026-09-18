@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T007 Unified Document'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true

define root view entity ZI_RAP_T007_DOC
  as select from    ZI_RAP_T007_DOCSRC as Source

    left outer join zrap_t007_a        as Addon on  Addon.source_type = Source.SourceType
                                                and Addon.document_no = Source.DocumentNo
{
      /* UNION 标准数据 */
  key Source.SourceType,
  key Source.DocumentNo,
      Source.SalesOrderNo,
      Source.DocumentType,
      Source.DocumentDate,
      Source.SalesOrganization,
      Source.Customer,
      Source.CustomerName,
      Source.CreatedDate,
      Source.CreatedBy,
      Source.DistributionChannel,
      Source.Division,
      Source.ShippingPoint,
      Source.PlannedDate,
      Source.SourceDescription,
      Source.SourceSort,
      Source.RelationSort,

      /* Addon 可维护数据 */
      Addon.partner_no            as PartnerNo,
      Addon.partner_name          as PartnerName,
      Addon.address_number        as AddressNumber,
      Addon.postal_code           as PostalCode,
      Addon.region                as Region,
      Addon.city                  as City,
      Addon.street                as Street,
      Addon.house_number          as HouseNumber,
      Addon.country               as Country,
      Addon.comment_text          as CommentText,

      Addon.created_by            as AddonCreatedBy,
      Addon.created_at            as AddonCreatedAt,
      Addon.last_changed_by       as AddonLastChangedBy,
      Addon.last_changed_at       as AddonLastChangedAt,
      Addon.local_last_changed_at as LocalLastChangedAt
}
