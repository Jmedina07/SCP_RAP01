@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel - Consumption Entity'
@Metadata.ignorePropagatedAnnotations: true

@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity z349_c_travel_1457
provider contract transactional_query
  as projection on z349_r_travel_1457
{
  key TravelUUID,
       
      @Search.defaultSearchElement: true
      TravelId,
      
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'AgencyName' ]
      @Consumption.valueHelpDefinition: [{ entity : { name: '/DMO/I_Agency_StdVH',
                                                      element: 'AgencyID' },
                                           useForValidation: true }]
      AgencyID,
      _Agency.Name as AgencyName,
      
      CustomerID,
      BeginDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalPrice,
      CurrencyCode,
      Description,
      OverallStatus,
      
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      
      /* Associations */
      _Agency,
      _Booking,
      _Currency,
      _Customer,
      _OverallStatus
}
