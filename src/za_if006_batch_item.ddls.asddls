@EndUserText.label: 'IF006 Batch Send Order Keys'
define abstract entity ZA_IF006_BATCH_ITEM
{
  key BatchId         : abap.char(1);
  key ExternalOrderNo : abap.char(20);
  key ExternalItemNo  : abap.char(6);
  
    _Header : association to parent za_if006_batch_param
    on $projection.batchid = _Header.batchid;
}
