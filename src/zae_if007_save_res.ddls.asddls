@EndUserText.label: 'IF007 Batch Save Result'
define abstract entity ZAE_IF007_SAVE_RES
{
  SapStatus       : abap.char(1);
  CloudStatus     : abap.char(1);

  SapMessage      : abap.string(0);
  CloudMessage    : abap.string(0);

  DetailsJson     : abap.string(0);
}
