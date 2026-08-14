@EndUserText.label: '销售订单出荷查询'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_RAP_T004_QUERY'
define custom entity ZCE_RAP_T004
{
  @EndUserText.label: '销售订单'
  @UI.selectionField: [{ position: 10 }]
  @UI.lineItem:       [{ position: 10 }]
  key SalesOrder              : vbeln_va;

  @EndUserText.label: '销售订单明细'
  @UI.lineItem: [{ position: 20 }]
  key SalesOrderItem          : posnr_va;

  @EndUserText.label: '销售组织'
  @UI.selectionField: [{ position: 20 }]
  @UI.lineItem:       [{ position: 30 }]
      SalesOrganization       : vkorg;

  @EndUserText.label: '受注日'
  @UI.selectionField: [{ position: 40 }]
  @UI.lineItem:       [{ position: 40 }]
      SalesOrderDate          : audat;

  @EndUserText.label: '得意先'
  @UI.selectionField: [{ position: 30 }]
  @UI.lineItem:       [{ position: 50 }]
      SoldToParty             : kunnr;

  @EndUserText.label: '得意先名称'
  @UI.lineItem: [{ position: 60 }]
      CustomerName            : name1_gp;

  @EndUserText.label: '物料'
  @UI.selectionField: [{ position: 50 }]
  @UI.lineItem:       [{ position: 70 }]
      Material                : matnr;

  @EndUserText.label: '销售单位'
  @Semantics.unitOfMeasure: true
  @UI.lineItem: [{ position: 90 }]
      SalesUnit               : vrkme;

  @EndUserText.label: '受注数量'
  @Semantics.quantity.unitOfMeasure: 'SalesUnit'
  @UI.lineItem: [{ position: 80 }]
      OrderQuantity           : kwmeng;

  @EndUserText.label: '纳入日程日'
  @UI.lineItem: [{ position: 100 }]
      ScheduleLineDate        : edatu;

  @EndUserText.label: '出荷番号'
  @UI.lineItem: [{ position: 110 }]
      DeliveryDocument        : vbeln_vl;

  @EndUserText.label: '实际出库日'
  @UI.lineItem: [{ position: 120 }]
      ActualGoodsMovementDate : wadat_ist;

  @EndUserText.label: '出荷状态'
  @UI.lineItem: [{ position: 130 }]
      DeliveryStatus          : abap.char(10);
}
