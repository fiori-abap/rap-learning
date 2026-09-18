@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T007 SO Delivery Unified Source'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_RAP_T007_DOCSRC

  as select from    vbak as SalesOrder

    left outer join kna1 as Customer on Customer.kunnr = SalesOrder.kunnr

{
  key cast( 'SO' as abap.char(2) ) as SourceType,
  key SalesOrder.vbeln             as DocumentNo,
      SalesOrder.vbeln             as SalesOrderNo,
      SalesOrder.auart             as DocumentType,
      SalesOrder.audat             as DocumentDate,
      SalesOrder.vkorg             as SalesOrganization,
      SalesOrder.kunnr             as Customer,

      Customer.name1               as CustomerName,

      SalesOrder.erdat             as CreatedDate,
      SalesOrder.ernam             as CreatedBy,

      SalesOrder.vtweg             as DistributionChannel,
      SalesOrder.spart             as Division,

      cast( '' as abap.char(4) )   as ShippingPoint,

      SalesOrder.vdatu             as PlannedDate,

      cast( 'Sales Order'
        as abap.char(20) )         as SourceDescription,
      cast( 1 as abap.int1 )       as SourceSort,
      cast( '0' as abap.char(1) )  as RelationSort
}

union all

select from       likp              as Delivery

  left outer join kna1              as Customer  on Customer.kunnr = Delivery.kunnr

  left outer join ZI_RAP_T007_DLREF as Reference on Reference.DeliveryNo = Delivery.vbeln

{
  key cast( 'DL' as abap.char(2) ) as SourceType,
  key Delivery.vbeln               as DocumentNo,
      Reference.SalesOrderNo       as SalesOrderNo,
      Delivery.lfart               as DocumentType,
      Delivery.wadat_ist           as DocumentDate,
      Delivery.vkorg               as SalesOrganization,
      Delivery.kunnr               as Customer,

      Customer.name1               as CustomerName,

      Delivery.erdat               as CreatedDate,
      Delivery.ernam               as CreatedBy,

      cast( '' as abap.char(2) )   as DistributionChannel,
      cast( '' as abap.char(2) )   as Division,

      Delivery.vstel               as ShippingPoint,

      Delivery.lfdat               as PlannedDate,

      cast( 'Delivery'
        as abap.char(20) )         as SourceDescription,
      cast( 2 as abap.int1 )       as SourceSort,
      case
      when Reference.SalesOrderNo is null
      then '1'
      else '0'
      end                          as RelationSort
}
