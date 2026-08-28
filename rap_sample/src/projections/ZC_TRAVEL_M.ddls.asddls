@EndUserText.label: 'Travel Projection View (Consumer)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Search.searchable: true
@Metadata.allowExtensions: true

define root view entity ZC_TRAVEL_M
  provider contract transactional_query
  as projection on ZI_TRAVEL_M
{
  key TravelUUID,

  @Search.defaultSearchElement: true
  TravelID,

  @ObjectModel.text.element: ['AgencyName']
  AgencyID,
  _Agency.Name       as AgencyName,

  @ObjectModel.text.element: ['CustomerName']
  CustomerID,
  _Customer.LastName as CustomerName,

  BeginDate,
  EndDate,
  BookingFee,
  TotalPrice,
  CurrencyCode,

  @Search.defaultSearchElement: true
  Description,

  @ObjectModel.text.element: ['OverallStatusText']
  OverallStatus,
  cast( case OverallStatus
          when 'O' then 'Open'
          when 'A' then 'Accepted'
          when 'X' then 'Rejected'
          else 'Unknown'
        end as /dmo/description ) as OverallStatusText,

  LocalCreatedBy,
  LocalCreatedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  LastChangedAt
}
