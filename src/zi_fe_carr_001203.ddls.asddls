@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Carrier view entity'
@Search.searchable: true
define view entity zi_fe_carr_001203
  as select from zfe_acarr_001203 as Airline
  association [0..1] to I_Currency as _Currency on $projection.CurrencyCode = _Currency.Currency
{
  @Search.defaultSearchElement: true
  @ObjectModel.text.element: [ 'Name' ]
  key Airline.carrier_id as AirlineID,
  @Search.defaultSearchElement: true
  @Search.fuzzinessThreshold: 0.7 
  @Semantics.text: true
  Airline.name as Name,
  @Semantics.imageUrl: true
  Airline.carrier_pic_url as AirlinePicURL,
  Airline.currency_code as CurrencyCode,
  _Currency
  
}
