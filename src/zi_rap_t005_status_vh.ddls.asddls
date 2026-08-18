@Metadata.ignorePropagatedAnnotations: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T005 Status Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_RAP_T005_STATUS_VH
  as select from I_Language
{
  key cast( 'OPEN' as abap.char(10) ) as Status
}
where Language = $session.system_language

union all

select from I_Language
{
  key cast( 'CLOSED' as abap.char(10) ) as Status
}
where Language = $session.system_language

union all

select from I_Language
{
  key cast( 'HOLD' as abap.char(10) ) as Status
}
where Language = $session.system_language
