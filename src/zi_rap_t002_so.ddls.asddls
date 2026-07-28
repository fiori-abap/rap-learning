@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Addon Interface View'
define root view entity ZI_RAP_T002_SO
  as select from vbap

    inner join vbak
      on vbak.vbeln = vbap.vbeln

    left outer join zrap_t002_addon as Addon
      on  Addon.sales_order      = vbap.vbeln
      and Addon.sales_order_item = vbap.posnr

{
  key vbap.vbeln                as SalesOrder,
  key vbap.posnr                as SalesOrderItem,

      vbak.auart                as SalesOrderType,
      vbak.audat                as SalesOrderDate,
      vbak.vkorg                as SalesOrganization,
      vbak.vtweg                as DistributionChannel,
      vbak.spart                as Division,
      vbak.kunnr                as SoldToParty,

      vbap.matnr                as Material,
      vbap.arktx                as MaterialDescription,
      vbap.werks                as Plant,

      @Semantics.quantity.unitOfMeasure: 'SalesUnit'
      vbap.kwmeng               as OrderQuantity,

      vbap.vrkme                as SalesUnit,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      vbap.netwr                as NetAmount,

      vbak.waerk                as TransactionCurrency,

      Addon.addon_status        as AddonStatus,
      Addon.addon_remark        as AddonRemark,

      Addon.created_by          as CreatedBy,
      Addon.created_at          as CreatedAt,
      Addon.last_changed_by     as LastChangedBy,
      Addon.last_changed_at     as LastChangedAt,
      Addon.local_last_changed_at
                                  as LocalLastChangedAt
}
