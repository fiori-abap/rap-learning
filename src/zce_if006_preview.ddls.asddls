@EndUserText.label: 'IF006 HANA Cloud Preview'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_IF006_PREVIEW_QP'

define custom entity ZCE_IF006_PREVIEW
{
  @UI.lineItem: [{ position: 10, label: '外部订单号' }]
  key ExternalOrderNo : abap.char(20);

  @UI.lineItem: [{ position: 20, label: '外部明细号' }]
  key ExternalItemNo  : abap.char(10);

  @UI.lineItem: [{ position: 30, label: '物料' }]
  Material            : abap.char(40);

  @UI.lineItem: [{ position: 40, label: '金额' }]
  @Semantics.amount.currencyCode: 'Currency'
  Amount              : abap.dec(15,2);

  @UI.lineItem: [{ position: 50, label: '货币' }]
  @Semantics.currencyCode: true
  Currency            : abap.cuky(5);
}
