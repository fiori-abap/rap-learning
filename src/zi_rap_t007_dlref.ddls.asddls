@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T007 Delivery Sales Order Reference'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_RAP_T007_DLREF
  as select distinct from lips as Item

    inner join            vbak as SalesOrder on SalesOrder.vbeln = Item.vgbel

{
  key Item.vbeln        as DeliveryNo,

      min( Item.vgbel ) as SalesOrderNo
}
group by
  Item.vbeln
