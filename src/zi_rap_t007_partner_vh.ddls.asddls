@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'T007 Partner Address Value Help'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_RAP_T007_PARTNER_VH

  as select from lfa1 as Vendor

    left outer join adrc as Address
      on Address.addrnumber = Vendor.adrnr

{
  key cast( 'SO' as abap.char(2) ) as SourceType,
  key Vendor.lifnr                 as PartnerNo,

      Vendor.name1                 as PartnerName,
      Vendor.adrnr                 as AddressNumber,

      Address.post_code1           as PostalCode,
      Address.region               as Region,
      Address.city1                as City,
      Address.street               as Street,
      Address.house_num1           as HouseNumber,
      Address.country              as Country
}

union all

select from kna1 as Customer

  left outer join adrc as Address
    on Address.addrnumber = Customer.adrnr

{
  key cast( 'DL' as abap.char(2) ) as SourceType,
  key Customer.kunnr               as PartnerNo,

      Customer.name1               as PartnerName,
      Customer.adrnr               as AddressNumber,

      Address.post_code1           as PostalCode,
      Address.region               as Region,
      Address.city1                as City,
      Address.street               as Street,
      Address.house_num1           as HouseNumber,
      Address.country              as Country
}
