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

    " Parent UUIDs
    READ ENTITIES OF z349_r_travel_1457  IN LOCAL MODE
         ENTITY Booking BY \_Travel
         FIELDS ( TravelUUID  )
         WITH CORRESPONDING #(  keys  )
         RESULT DATA(travels).

    " Trigger Re-Calculation on Root Node
    MODIFY ENTITIES OF z349_r_travel_1457  IN LOCAL MODE
      ENTITY Travel
        EXECUTE reCalcTotalPrice
          FROM CORRESPONDING  #( travels ).

  ENDMETHOD.

  METHOD setBookingDate.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
       ENTITY Booking
         FIELDS ( BookingDate )
         WITH CORRESPONDING #( keys )
       RESULT DATA(bookings).

    DELETE bookings WHERE BookingDate IS NOT INITIAL.
    CHECK bookings IS NOT INITIAL.

    LOOP AT bookings ASSIGNING FIELD-SYMBOL(<booking>).
      <booking>-BookingDate = cl_abap_context_info=>get_system_date( ).
    ENDLOOP.

    MODIFY ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
      ENTITY Booking
        UPDATE  FIELDS ( BookingDate )
        WITH CORRESPONDING #( bookings ).

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

    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY client customer_id.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Booking
         FIELDS (  CustomerID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(bookings).

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Booking BY \_Travel
         FROM CORRESPONDING #( bookings )
         LINK DATA(travel_booking_links).

    customers = CORRESPONDING #( bookings DISCARDING DUPLICATES MAPPING customer_id = CustomerID EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.


    IF customers IS NOT INITIAL.

      SELECT FROM /dmo/customer AS db
             INNER JOIN @customers AS it ON db~customer_id = it~customer_id
             FIELDS db~customer_id
             INTO TABLE @DATA(valid_customers).

    ENDIF.

    LOOP AT bookings INTO DATA(booking).

      APPEND VALUE #( %tky        = booking-%tky
                      %state_area = 'VALIDATE_CUSTOMER' ) TO reported-booking.

      IF booking-CustomerID IS INITIAL.

        APPEND VALUE #( %tky = booking-%tky ) TO failed-booking.

        APPEND VALUE #( %tky                = booking-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                                           severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on ) TO reported-booking.

      ELSEIF NOT line_exists( valid_customers[ customer_id = booking-CustomerID ] ).

        APPEND VALUE #( %tky = booking-%tky ) TO failed-booking.

        APPEND VALUE #( %tky                = booking-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>customer_unkown
                                                                           customer_id = booking-CustomerID
                                                                           severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on ) TO reported-booking.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateFlightPrice.
  ENDMETHOD.

  METHOD validateStatus.
  ENDMETHOD.

ENDCLASS.
