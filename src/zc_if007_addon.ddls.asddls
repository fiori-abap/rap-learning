@EndUserText.label: 'IF007 Add-on Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED

define root view entity ZC_IF007_ADDON
  provider contract transactional_query
  as projection on ZI_IF007_ADDON
{
  key SalesOrder,
  key SalesOrderItem,

      FollowUpDate,
      CommentText,
      SapStatus,
      CloudStatus,
      SyncStatus,
      LastError,
      LastProcessedAt
}
