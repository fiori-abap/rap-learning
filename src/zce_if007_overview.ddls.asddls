@EndUserText.label: 'IF007 Overview'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_IF007_QUERY'
define root custom entity ZCE_IF007_OVERVIEW
{

      @UI.selectionField: [{ position: 10 }]
      @UI.lineItem      : [{ position: 10, label: '受注番号' }]
  key SalesOrder        : vbeln_va;

      @UI.lineItem      : [{ position: 20, label: '明細番号' }]
  key SalesOrderItem    : posnr_va;

      @UI.lineItem      : [{ position: 30, label: '品目' }]
      Material          : matnr;

      @Semantics.quantity.unitOfMeasure: 'SalesUnit'
      @UI.lineItem      : [{ position: 40, label: '数量' }]
      Quantity          : abap.quan(13,3);

      @UI.lineItem      : [{ position: 50, label: '販売単位' }]
      SalesUnit         : vrkme;

      @UI.lineItem      : [{ position: 60, label: 'SAP納入予定日' }]
      SapDeliveryDate   : abap.dats;
      @UI.lineItem      : [{ position: 70, label: 'Cloud納入予定日' }]
      CloudDeliveryDate : abap.dats;
      @UI.lineItem      : [{ position: 80, label: '外部ステータス' }]
      ExternalStatus    : abap.char(20);
      @EndUserText.label: '跟进日期'
      FollowUpDate      : abap.dats;
      @EndUserText.label: '备注'
      CommentText       : abap.char(255);
      @EndUserText.label: 'SAP状态'
      SapStatus         : abap.char(20);
      @EndUserText.label: 'Cloud状态'
      @UI.lineItem      : [{ position: 100 }]
      CloudStatus       : abap.char(20);
      @EndUserText.label: '同步状态'
      @UI.lineItem      : [{ position: 110 }]
      SyncStatus        : abap.char(20);
      @EndUserText.label: '错误信息'
      @UI.lineItem      : [{ position: 120 }]
      LastError         : abap.char(255);

}
