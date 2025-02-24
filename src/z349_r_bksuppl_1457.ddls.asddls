@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplements - Root Entity'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity z349_r_bksuppl_1457
  as select from z349_bksuppl_457
  
  association to parent z349_r_booking_1457 as _Booking on $projection.BookingUUID = _Booking.BookingUUID
  
{
  key booksuppl_uuid        as BooksupplUUID,
      root_uuid             as TravelUUID,
      parent_uuid           as BookingUUID,
      booking_supplement_id as BookingSupplementID,
      supplement_id         as SupplementID,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      currency_code         as CurrencyCode,
      
      //local ETag field
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      
      _Booking
      
}
