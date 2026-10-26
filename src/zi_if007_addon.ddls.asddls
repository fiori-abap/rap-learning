@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'IF007 Add-on Root View'

define root view entity ZI_IF007_ADDON
  as select from zrap_if007
{
  key sales_order       as SalesOrder,
  key sales_order_item  as SalesOrderItem,

      follow_up_date    as FollowUpDate,
      comment_text      as CommentText,
      sap_status        as SapStatus,
      cloud_status      as CloudStatus,
      sync_status       as SyncStatus,
      last_error        as LastError,
      last_processed_at as LastProcessedAt
}
