@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T007 Unified Document Projection'
@Metadata.allowExtensions: true

define root view entity ZC_RAP_T007_DOC
  provider contract transactional_query
  as projection on ZI_RAP_T007_DOC
{
  key SourceType,
  key DocumentNo,
      SalesOrderNo,
      DocumentType,
      DocumentDate,
      SalesOrganization,
      Customer,
      CustomerName,
      CreatedDate,
      CreatedBy,
      DistributionChannel,
      Division,
      ShippingPoint,
      PlannedDate,
      SourceDescription,
      SourceSort,
      RelationSort,
      @Consumption.valueHelpDefinition: [
        {
          entity: {
            name   : 'ZI_RAP_T007_PARTNER_VH',
            element: 'PartnerNo'
          },
          additionalBinding: [
            {
              localElement: 'SourceType',
              element     : 'SourceType',
              usage       : #FILTER
            },
            {
              localElement: 'PartnerName',
              element     : 'PartnerName',
              usage       : #RESULT
            },
            {
              localElement: 'AddressNumber',
              element     : 'AddressNumber',
              usage       : #RESULT
            },
            {
              localElement: 'PostalCode',
              element     : 'PostalCode',
              usage       : #RESULT
            },
            {
              localElement: 'Region',
              element     : 'Region',
              usage       : #RESULT
            },
            {
              localElement: 'City',
              element     : 'City',
              usage       : #RESULT
            },
            {
              localElement: 'Street',
              element     : 'Street',
              usage       : #RESULT
            },
            {
              localElement: 'HouseNumber',
              element     : 'HouseNumber',
              usage       : #RESULT
            },
            {
              localElement: 'Country',
              element     : 'Country',
              usage       : #RESULT
            }
          ]
        }
      ]
      PartnerNo,
      PartnerName,
      AddressNumber,
      PostalCode,
      Region,
      City,
      Street,
      HouseNumber,
      Country,
      CommentText,

      AddonCreatedBy,
      AddonCreatedAt,
      AddonLastChangedBy,
      AddonLastChangedAt,
      LocalLastChangedAt
}
