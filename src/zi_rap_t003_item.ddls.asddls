@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '销售订单明细附加接口视图'
@Metadata.allowExtensions: true

define view entity ZI_RAP_T003_ITEM
  as select from vbap as Item

    left outer join zrap_t003_addon as Addon
      on  Addon.sales_order      = Item.vbeln
      and Addon.sales_order_item = Item.posnr

  association to parent ZI_RAP_T003_HEADER as _Header
    on $projection.SalesOrder = _Header.SalesOrder

{
  key Item.vbeln                   as SalesOrder,
  key Item.posnr                   as SalesOrderItem,

      Item.matnr                   as Material,
      Item.arktx                   as MaterialDescription,
      Item.werks                   as Plant,
      Item.lgort                   as StorageLocation,
      Item.kwmeng                  as OrderQuantity,
      Item.vrkme                   as SalesUnit,

      Addon.item_note              as ItemNote,
      Addon.local_last_changed_at  as LocalLastChangedAt,

      _Header
}
