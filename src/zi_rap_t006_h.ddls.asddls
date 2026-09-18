@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T006 Processing Batch Header Interface'

define root view entity ZI_RAP_T006_H
  as select from zrap_t006_h
  
   composition [0..*] of ZI_RAP_T006_I as _Items
   
{
  key batch_id              as BatchID,

      batch_name            as BatchName,
      description           as Description,
      status                as Status,
      processing_date       as ProcessingDate,
      responsible_person    as ResponsiblePerson,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      
      _Items
}
