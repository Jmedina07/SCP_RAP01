CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Booking RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Booking RESULT result.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calculateTotalPrice.

    METHODS setBookingDate FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~setBookingDate.

    METHODS setBookingNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~setBookingNumber.

    METHODS validateConnection FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateConnection.

    METHODS validateCurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateCurrency.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateCustomer.

    METHODS validateFlightPrice FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateFlightPrice.

    METHODS validateStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateStatus.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD calculateTotalPrice.
  ENDMETHOD.

  METHOD setBookingDate.
  ENDMETHOD.

  METHOD setBookingNumber.

    DATA:
      bookings_u  TYPE TABLE FOR UPDATE  z349_r_travel_1457\\Booking, "Internal table
      max_book_id TYPE /dmo/booking_id.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
       ENTITY Booking BY \_Travel
       FIELDS ( TravelUUID )
       WITH CORRESPONDING #( keys )
       RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).
      READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
           ENTITY Travel BY  \_Booking
           FIELDS ( BookingId )
           WITH VALUE #( ( %tky = travel-%tky ) )
           RESULT DATA(bookings).
      max_book_id = '0000'.
      LOOP AT bookings INTO DATA(booking).
        IF booking-BookingId > max_book_id.
          max_book_id = booking-BookingId.
        ENDIF.
      ENDLOOP.
      LOOP AT bookings INTO booking WHERE BookingId IS INITIAL.
        max_book_id += 1.
        APPEND VALUE #(
            %tky    = booking-%tky
            BookingId = max_book_id
         ) TO bookings_u.
      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
           ENTITY Booking
           UPDATE FIELDS ( BookingId )
           WITH bookings_u.

  ENDMETHOD.

  METHOD validateConnection.
  ENDMETHOD.

  METHOD validateCurrency.
  ENDMETHOD.

  METHOD validateCustomer.
  ENDMETHOD.

  METHOD validateFlightPrice.
  ENDMETHOD.

  METHOD validateStatus.
  ENDMETHOD.

ENDCLASS.
