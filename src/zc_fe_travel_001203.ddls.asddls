@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View forTravel'
@ObjectModel.semanticKey: [ 'TravelID', 'AgencyID' ]
@Search.searchable: true
define root view entity ZC_FE_Travel_001203
  as projection on ZI_FE_Travel_001203
{
  key TravelUUID,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.90
      @EndUserText.label: 'Travel'
      @ObjectModel.text.element: [ 'Description' ]
      TravelID,
      @Consumption.valueHelpDefinition: [ {
        entity: {
          name: '/DMO/I_Agency',
          element: 'AgencyID'
        }
      } ]
      @ObjectModel.text.element: [ 'AgencyName' ]
      AgencyID,
      _Agency.Name                   as AgencyName,

      @EndUserText.label: 'Customer ID'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.90
      @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_CUSTOMER', element: 'CustomerID'} } ]
      CustomerID,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      @Consumption.valueHelpDefinition: [ {
        entity: {
          name: 'I_Currency',
          element: 'Currency'
        }
      } ]
      CurrencyCode,
      Description,
      @ObjectModel.text.element: [ 'StatusText' ]
      @UI.textArrangement: #TEXT_ONLY
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_FE_STAT_001203', element: 'TravelStatusId'} } ]
      OverallStatus,

      /* case OverallStatus
         when 'O' then 2  --Open: | Yellow
         when 'A' then 3
         when 'X' then 1
         else 0
         end as OverallStatusCriticality, */  --not supported in Projection view - reason ?

      OverallStatusCriticality,

      _TravelStatus.TravelStatusText as StatusText,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      _Booking : redirected to composition child ZC_FE_Booking_001203,
      _Agency,
      _Currency,
      _Customer,
      _TravelStatus

}
