@EndUserText.label: 'IF006 Batch Send Parameters'
define root abstract entity ZA_IF006_BATCH_PARAM
{
  key BatchId : abap.char(1);

  WriteMode : abap.char(1);

  _Items : composition [0..*] of ZA_IF006_BATCH_ITEM;
}
