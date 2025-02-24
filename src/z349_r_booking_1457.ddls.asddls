@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking - Root Entity'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity z349_r_booking_1457
  as select from z349_booking_457
  
  association to parent z349_r_travel_1457 as _Travel on $projection.TravelUUID = _Travel.TravelUUID
  
  
  composition [0..*] of z349_r_bksuppl_1457 as _BookingSupplement
{
  key booking_uuid         as BookingUUID,
      parent_uuid          as TravelUUID,
      
      booking_id           as BookingId,
      booking_date         as BookingDate,
      customer_id          as CustomerID,
      carrier_id           as CarrierID,
      connection_id        as ConnectionID,
      flight_date          as FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price         as FlightPrice,
      currency_code        as CurrencyCode,
      booking_status       as BookingStatus,

      //local ETag field
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_change_at as LocalLastChangeAt,
      
      
      _Travel,
      _BookingSupplement
}
