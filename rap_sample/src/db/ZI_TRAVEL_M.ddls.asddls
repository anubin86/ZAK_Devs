@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Travel Root CDS View'
define root view entity ZI_TRAVEL_M
  as select from ztraveldb

  association [0..1] to /dmo/I_Agency   as _Agency   on $projection.AgencyID   = _Agency.AgencyID
  association [0..1] to /dmo/I_Customer as _Customer on $projection.CustomerID = _Customer.CustomerID

{
  key travel_uuid       as TravelUUID,
      travel_id         as TravelID,
      agency_id         as AgencyID,
      customer_id       as CustomerID,
      begin_date        as BeginDate,
      end_date          as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee       as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price       as TotalPrice,
      currency_code     as CurrencyCode,
      description       as Description,
      overall_status    as OverallStatus,

      local_created_by      as LocalCreatedBy,
      local_created_at      as LocalCreatedAt,
      local_last_changed_by as LocalLastChangedBy,
      local_last_changed_at as LocalLastChangedAt,
      last_changed_at       as LastChangedAt,

      /* Associations */
      _Agency,
      _Customer
}
