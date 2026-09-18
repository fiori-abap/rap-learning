@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T006 Unified Document Source'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_RAP_T006_SOURCE
  as select from vbap as Item
    inner join   vbak as Header on Header.vbeln = Item.vbeln
{
  key cast( 'SO' as abap.char(2) ) as SourceType,

  key Item.vbeln                   as DocumentNo,
  key Item.posnr                   as DocumentItem,

      Header.auart                 as DocumentType,
      Header.audat                 as DocumentDate,
      Header.vkorg                 as SalesOrganization,
      Header.vtweg                 as DistributionChannel,
      Header.spart                 as Division,
      Header.kunnr                 as Customer,

      Item.matnr                   as Material,
      Item.arktx                   as MaterialDescription,
      Item.werks                   as Plant,
      Item.lgort                   as StorageLocation,

      @Semantics.quantity.unitOfMeasure: 'Unit'
      Item.kwmeng                  as Quantity,

      Item.vrkme                   as Unit,

      @Semantics.amount.currencyCode: 'Currency'
      Item.netwr                   as NetAmount,

      Header.waerk                 as Currency,

      cast( '' as abap.char(10) )  as ReferenceDocument,
      cast( '' as abap.char(6) )   as ReferenceItem
}

union all

select from       lips as Item
  inner join      likp as Header    on Header.vbeln = Item.vbeln
  left outer join vbak as RefHeader on RefHeader.vbeln = Item.vgbel

  left outer join vbap as RefItem   on  RefItem.vbeln = Item.vgbel
                                    and RefItem.posnr = Item.vgpos
{
  key cast( 'DL' as abap.char(2) ) as SourceType,

  key Item.vbeln                   as DocumentNo,
  key Item.posnr                   as DocumentItem,

      Header.lfart                 as DocumentType,
      Header.wadat_ist             as DocumentDate,
      Header.vkorg                 as SalesOrganization,
RefHeader.vtweg            as DistributionChannel,
RefHeader.spart            as Division,
      Header.kunnr                 as Customer,

      Item.matnr                   as Material,
      Item.arktx                   as MaterialDescription,
      Item.werks                   as Plant,
      Item.lgort                   as StorageLocation,

      Item.lfimg                   as Quantity,

      Item.vrkme                   as Unit,

      RefItem.netwr                as NetAmount,

      RefHeader.waerk              as Currency,

      Item.vgbel                   as ReferenceDocument,
      Item.vgpos                   as ReferenceItem
}
