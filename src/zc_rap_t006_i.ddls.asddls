@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T006 Processing Batch Item Projection'
@Metadata.allowExtensions: true

define view entity ZC_RAP_T006_I
  as projection on ZI_RAP_T006_I
{
  key BatchID,
  key ItemID,

      SourceType,
      @Consumption.valueHelpDefinition: [
        {
          entity: {
            name   : 'ZI_RAP_T006_SOURCE',
            element: 'DocumentNo'
          },
          additionalBinding: [
            {
              localElement: 'SourceType',
              element     : 'SourceType',
              usage       : #RESULT
            },
            {
              localElement: 'DocumentItem',
              element     : 'DocumentItem',
              usage       : #RESULT
            },
            {
              localElement: 'DocumentType',
              element     : 'DocumentType',
              usage       : #RESULT
            },
            {
              localElement: 'DocumentDate',
              element     : 'DocumentDate',
              usage       : #RESULT
            },
            {
              localElement: 'SalesOrganization',
              element     : 'SalesOrganization',
              usage       : #RESULT
            },
            {
              localElement: 'DistributionChannel',
              element     : 'DistributionChannel',
              usage       : #RESULT
            },
            {
              localElement: 'Division',
              element     : 'Division',
              usage       : #RESULT
            },
            {
              localElement: 'Customer',
              element     : 'Customer',
              usage       : #RESULT
            },
            {
              localElement: 'Material',
              element     : 'Material',
              usage       : #RESULT
            },
            {
              localElement: 'MaterialDescription',
              element     : 'MaterialDescription',
              usage       : #RESULT
            },
            {
              localElement: 'Plant',
              element     : 'Plant',
              usage       : #RESULT
            },
            {
              localElement: 'StorageLocation',
              element     : 'StorageLocation',
              usage       : #RESULT
            },
            {
              localElement: 'Quantity',
              element     : 'Quantity',
              usage       : #RESULT
              },
            {
              localElement: 'Unit',
              element     : 'Unit',
              usage       : #RESULT
              },
            {
              localElement: 'NetAmount',
              element     : 'NetAmount',
              usage       : #RESULT
            },
            {
              localElement: 'Currency',
              element     : 'Currency',
              usage       : #RESULT
            },
            {
              localElement: 'ReferenceDocument',
              element     : 'ReferenceDocument',
              usage       : #RESULT
            },
            {
              localElement: 'ReferenceItem',
              element     : 'ReferenceItem',
              usage       : #RESULT
            }
          ]
        }
      ]
      DocumentNo,
      DocumentItem,
      DocumentType,
      DocumentDate,

      SalesOrganization,
      DistributionChannel,
      Division,
      Customer,

      Material,
      MaterialDescription,
      Plant,
      StorageLocation,

      Quantity,
      Unit,

      NetAmount,
      Currency,

      ReferenceDocument,
      ReferenceItem,

      ProcessStatus,
      CommentText,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _Header : redirected to parent ZC_RAP_T006_H
}
