CLASS lhc_BookingSupplement DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR BookingSupplement RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR BookingSupplement RESULT result.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR BookingSupplement~calculateTotalPrice.

    METHODS setBookSupplNumber FOR DETERMINE ON MODIFY
      IMPORTING keys FOR BookingSupplement~setBookSupplNumber.

    METHODS validateCurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR BookingSupplement~validateCurrency.

    METHODS validatePrice FOR VALIDATE ON SAVE
      IMPORTING keys FOR BookingSupplement~validatePrice.

    METHODS validateSupplement FOR VALIDATE ON SAVE
      IMPORTING keys FOR BookingSupplement~validateSupplement.

ENDCLASS.

CLASS lhc_BookingSupplement IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD calculateTotalPrice.

    " Parent UUIDs
    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY BookingSupplement BY \_Travel
         FIELDS ( TravelUUID  )
         WITH CORRESPONDING #(  keys  )
         RESULT DATA(travels).

    " Re-Calculation on Root Node
    MODIFY ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
           ENTITY Travel
           EXECUTE reCalcTotalPrice
           FROM CORRESPONDING  #( travels ).

  ENDMETHOD.

  METHOD setBookSupplNumber.

    DATA: bookingsupplements_u TYPE TABLE FOR UPDATE z349_r_travel_1457\\BookingSupplement,
          max_bookingsuppl_id  TYPE /dmo/booking_supplement_id.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
      ENTITY BookingSupplement BY \_Booking
        FIELDS (  BookingUUID  )
        WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    LOOP AT bookings INTO DATA(ls_booking).
      READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
        ENTITY Booking BY \_BookingSupplement
          FIELDS ( BookingSupplementID )
          WITH VALUE #( ( %tky = ls_booking-%tky ) )
        RESULT DATA(bookingsupplements).

      " max bookingID
      max_bookingsuppl_id = '00'.
      LOOP AT bookingsupplements INTO DATA(bookingsupplement).
        IF bookingsupplement-BookingSupplementID > max_bookingsuppl_id.
          max_bookingsuppl_id = bookingsupplement-BookingSupplementID.
        ENDIF.
      ENDLOOP.

      "Provide a booking supplement ID for all booking supplement of this booking that have none.
      LOOP AT bookingsupplements INTO bookingsupplement WHERE BookingSupplementID IS INITIAL.
        max_bookingsuppl_id += 1.
        APPEND VALUE #( %tky                = bookingsupplement-%tky
                        bookingsupplementid = max_bookingsuppl_id
                      ) TO bookingsupplements_u.

      ENDLOOP.
    ENDLOOP.

    MODIFY ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
      ENTITY BookingSupplement
        UPDATE FIELDS ( BookingSupplementID ) WITH bookingsupplements_u.

  ENDMETHOD.

  METHOD validateCurrency.
  ENDMETHOD.

  METHOD validatePrice.
  ENDMETHOD.

  METHOD validateSupplement.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY BookingSupplement
         FIELDS ( SupplementID )
         WITH CORRESPONDING #(  keys )
         RESULT DATA(bookingsupplements)
         FAILED DATA(read_failed).

    failed = CORRESPONDING #( DEEP read_failed ).

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY BookingSupplement BY \_Booking
         FROM CORRESPONDING #( bookingsupplements )
         LINK DATA(booksuppl_booking_links).

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY BookingSupplement BY \_Travel
         FROM CORRESPONDING #( bookingsupplements )
         LINK DATA(booksuppl_travel_links).

    DATA supplements TYPE SORTED TABLE OF /dmo/supplement WITH UNIQUE KEY supplement_id.

    supplements = CORRESPONDING #( bookingsupplements DISCARDING DUPLICATES MAPPING supplement_id = SupplementID EXCEPT * ).
    DELETE supplements WHERE supplement_id IS INITIAL.

    IF  supplements IS NOT INITIAL.
      " Check if customer ID exists
      SELECT FROM /dmo/supplement FIELDS supplement_id
                                  FOR ALL ENTRIES IN @supplements
                                  WHERE supplement_id = @supplements-supplement_id
      INTO TABLE @DATA(valid_supplements).
    ENDIF.

    LOOP AT bookingsupplements ASSIGNING FIELD-SYMBOL(<bookingsupplement>).

      APPEND VALUE #(  %tky        = <bookingsupplement>-%tky
                       %state_area = 'VALIDATE_SUPPLEMENT'
                    ) TO reported-bookingsupplement.

      IF <bookingsupplement>-SupplementID IS  INITIAL.
        APPEND VALUE #( %tky = <bookingsupplement>-%tky ) TO failed-bookingsupplement.

        APPEND VALUE #( %tky                  = <bookingsupplement>-%tky
                        %state_area           = 'VALIDATE_SUPPLEMENT'
                        %msg                  = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>enter_supplement_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                 = VALUE #( booking-%tky = booksuppl_booking_links[ KEY id  source-%tky = <bookingsupplement>-%tky ]-target-%tky
                                                         travel-%tky  = booksuppl_travel_links[  KEY id  source-%tky = <bookingsupplement>-%tky ]-target-%tky )
                        %element-SupplementID = if_abap_behv=>mk-on
                       ) TO reported-bookingsupplement.


      ELSEIF <bookingsupplement>-SupplementID IS NOT INITIAL AND NOT line_exists( valid_supplements[ supplement_id = <bookingsupplement>-SupplementID ] ).
        APPEND VALUE #(  %tky = <bookingsupplement>-%tky ) TO failed-bookingsupplement.

        APPEND VALUE #( %tky                  = <bookingsupplement>-%tky
                        %state_area           = 'VALIDATE_SUPPLEMENT'
                        %msg                  = NEW /dmo/cm_flight_messages(
                                                                textid = /dmo/cm_flight_messages=>supplement_unknown
                                                                severity = if_abap_behv_message=>severity-error )
                        %path                 = VALUE #( booking-%tky = booksuppl_booking_links[ KEY id  source-%tky = <bookingsupplement>-%tky ]-target-%tky
                                                          travel-%tky = booksuppl_travel_links[  KEY id  source-%tky = <bookingsupplement>-%tky ]-target-%tky )
                        %element-SupplementID = if_abap_behv=>mk-on
                       ) TO reported-bookingsupplement.
      ENDIF.

    ENDLOOP.


  ENDMETHOD.

ENDCLASS.
