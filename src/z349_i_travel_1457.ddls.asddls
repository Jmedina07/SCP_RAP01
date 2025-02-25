@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel - Interface Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity z349_i_travel_1457
provider contract transactional_interface
  as projection on z349_r_travel_1457
{
  key TravelUUID,
      TravelId,
      AgencyID,
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
      
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,
      
      /* Associations */
      _Agency,
      _Booking : redirected to composition child z349_i_booking_1457,
      _Currency,
      _Customer,
      _OverallStatus
}
