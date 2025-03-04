@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplements - Consumption Entity'
@Metadata.ignorePropagatedAnnotations: true

@Metadata.allowExtensions: true
@Search.searchable: true


define view entity z349_c_bksuppl_1457
  as projection on z349_r_bksuppl_1457
{
  key BooksupplUUID,
      TravelUUID,
      BookingUUID,

      @Search.defaultSearchElement: true
      BookingSupplementID,

      @ObjectModel.text.element: [ 'SupplementDescription' ]
      @Consumption.valueHelpDefinition: [{ entity : { name: '/DMO/I_Supplement_StdVH',
                                                      element: 'SupplementID' },
                                           additionalBinding: [
                                                                { localElement: 'Price' ,
                                                                 element: 'Price',
                                                                 usage:#RESULT },
                                                                { localElement: 'CurrencyCode' ,
                                                                 element: 'CurrencyCode',
                                                                 usage:#RESULT }                                                                 
                                                                 ],
                                           useForValidation: true }]
      SupplementID,
      _SupplementText.Description as SupplementDescription : localized,
      
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Price,
      @Consumption.valueHelpDefinition: [{ entity: {
          name: 'I_CurrencyStdVH',
          element: 'Currency'},
          useForValidation: true }]        
      CurrencyCode,
      
      LocalLastChangedAt,

      /* Associations */
      _Booking : redirected to parent z349_c_booking_1457,
      _Product,
      _SupplementText,
      _Travel  : redirected to z349_c_travel_1457
}
