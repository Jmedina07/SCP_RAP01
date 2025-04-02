CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF travel_status,
        open     TYPE c LENGTH 1 VALUE 'O',
        accepted TYPE c LENGTH 1 VALUE 'A',
        rejected TYPE c LENGTH 1 VALUE 'X',
      END OF travel_status.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE Travel.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS deductDiscount FOR MODIFY
      IMPORTING keys FOR ACTION Travel~deductDiscount RESULT result.

    METHODS reCalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION Travel~reCalcTotalPrice.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS Resume FOR MODIFY
      IMPORTING keys FOR ACTION Travel~Resume.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~calculateTotalPrice.

    METHODS setStatusToOpen FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~setStatusToOpen.

    METHODS setTravelNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~setTravelNumber.

    METHODS validateAgency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateAgency.

    METHODS validateBookingFee FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateBookingFee.

    METHODS validateCurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCurrency.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDates.

    TYPES:
      t_entities_create TYPE TABLE FOR CREATE z349_r_travel_1457\\travel,
      t_entities_update TYPE TABLE FOR UPDATE z349_r_travel_1457\\travel,
      t_failed_travel   TYPE TABLE FOR FAILED   EARLY z349_r_travel_1457\\travel,
      t_reported_travel TYPE TABLE FOR REPORTED EARLY z349_r_travel_1457\\travel.


    METHODS precheck_auth
      IMPORTING
        entities_create TYPE t_entities_create OPTIONAL
        entities_update TYPE t_entities_update OPTIONAL
      CHANGING
        failed          TYPE t_failed_travel
        reported        TYPE t_reported_travel.

    METHODS is_create_granted
      IMPORTING country_code          TYPE land1 OPTIONAL
      RETURNING VALUE(create_granted) TYPE abap_bool.

    METHODS is_update_granted
      IMPORTING country_code          TYPE land1 OPTIONAL
      RETURNING VALUE(update_granted) TYPE abap_bool.

    METHODS is_delete_granted
      IMPORTING country_code          TYPE land1 OPTIONAL
      RETURNING VALUE(delete_granted) TYPE abap_bool.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.



    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
       ENTITY Travel
        FIELDS ( OverallStatus )
       WITH CORRESPONDING #( keys )
       RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %field-BookingFee = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                THEN if_abap_behv=>fc-f-read_only
                                                ELSE if_abap_behv=>fc-f-unrestricted
                                                )
                                              %action-acceptTravel = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                THEN if_abap_behv=>fc-o-disabled
                                                ELSE if_abap_behv=>fc-o-enabled
                                                )
                                              %action-rejectTravel = COND #( WHEN travel-OverallStatus = travel_status-rejected
                                                THEN if_abap_behv=>fc-o-disabled
                                                ELSE if_abap_behv=>fc-o-enabled
                                                )
                                              %action-deductDiscount = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                THEN if_abap_behv=>fc-o-disabled
                                                ELSE if_abap_behv=>fc-o-enabled
                                                )
                                              %assoc-_Booking = COND #( WHEN travel-OverallStatus = travel_status-rejected
                                                THEN if_abap_behv=>fc-o-disabled
                                                ELSE if_abap_behv=>fc-o-enabled
                                                )
                                             )

                    ).

  ENDMETHOD.

  METHOD get_instance_authorizations.

    " NOTHING to do with the CREATE operation
    DATA: update_requested TYPE abap_bool,
          update_granted   TYPE abap_bool,
          delete_requested TYPE abap_bool,
          delete_granted   TYPE abap_bool.

    "CHECK 2 = 2.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
       ENTITY Travel
       FIELDS ( AgencyID )
       WITH CORRESPONDING #( keys )
       RESULT DATA(travels).

    update_requested  = COND #( WHEN requested_authorizations-%update      = if_abap_behv=>mk-on
                              OR requested_authorizations-%action-Edit = if_abap_behv=>mk-on
                            THEN abap_true
                            ELSE abap_false ).

    delete_requested  = COND #( WHEN requested_authorizations-%delete      = if_abap_behv=>mk-on
                            THEN abap_true
                            ELSE abap_false ).

    DATA(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

    LOOP AT travels INTO DATA(travel).

      IF  travel-AgencyID IS NOT INITIAL.

        IF update_requested EQ abap_true.

          IF lv_technical_name = 'CB9980011457' AND travel-AgencyID NE '70009'.
            update_granted = abap_true.
          ELSE .

            update_granted = abap_false.

            APPEND VALUE #( %tky = travel-%tky
                            %msg = NEW /dmo/cm_flight_messages( textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                                agency_id = travel-AgencyID
                                                                severity  = if_abap_behv_message=>severity-error )
                            %element-AgencyID = if_abap_behv=>mk-on ) TO reported-travel.

          ENDIF.

        ENDIF.

        IF delete_requested EQ abap_true.

          IF lv_technical_name = 'CB9980011457' AND travel-AgencyID NE '70009'.
            delete_granted = abap_true.
          ELSE .

            delete_granted = abap_false.

            APPEND VALUE #( %tky = travel-%tky
                            %msg = NEW /dmo/cm_flight_messages( textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                                agency_id = travel-AgencyID
                                                                severity  = if_abap_behv_message=>severity-error )
                            %element-AgencyID = if_abap_behv=>mk-on ) TO reported-travel.

          ENDIF.
        ENDIF.

      else.

        IF lv_technical_name = 'CB9980011457'.
            update_granted = abap_true.
        ENDIF.

      ENDIF.


      APPEND VALUE #( LET upd_auth = COND #( WHEN update_granted EQ abap_true
                                             THEN if_abap_behv=>auth-allowed
                                             ELSE if_abap_behv=>auth-unauthorized )
                          del_auth = COND #( WHEN delete_granted EQ abap_true
                                             THEN if_abap_behv=>auth-allowed
                                             ELSE if_abap_behv=>auth-unauthorized )
                      IN
                          %tky         = travel-%tky
                          %update      = upd_auth
                          %action-Edit = upd_auth
                          %delete      = del_auth ) TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_global_authorizations.

    CHECK 1 = 2. "Delete me please!!!!

    DATA(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

    "lv_technical_name = 'DIFFERENT'.

    IF requested_authorizations-%create EQ if_abap_behv=>mk-on.

      IF lv_technical_name = 'CB9980011457'.

        result-%create = if_abap_behv=>auth-allowed.

      ELSE.

        result-%create = if_abap_behv=>auth-unauthorized.

        APPEND VALUE #( %msg     = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>not_authorized
                                                                severity = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

    ENDIF.

    IF requested_authorizations-%update EQ if_abap_behv=>mk-on OR
       requested_authorizations-%action-Edit EQ if_abap_behv=>mk-on.


      IF lv_technical_name = 'CB9980011457'.

        result-%update      = if_abap_behv=>auth-allowed.
        result-%action-Edit = if_abap_behv=>auth-allowed.

      ELSE.

        result-%update      = if_abap_behv=>auth-unauthorized.
        result-%action-Edit = if_abap_behv=>auth-unauthorized.

        APPEND VALUE #( %msg     = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>not_authorized
                                                                severity = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

    ENDIF.

    IF requested_authorizations-%delete EQ if_abap_behv=>mk-on.


      IF lv_technical_name = 'CB9980011457'.

        result-%delete      = if_abap_behv=>auth-allowed.

      ELSE.

        result-%delete      = if_abap_behv=>auth-unauthorized.

        APPEND VALUE #( %msg     = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>not_authorized
                                                                severity = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD precheck_create.

    me->precheck_auth( EXPORTING entities_create = entities
                       CHANGING  failed          = failed-travel
                                 reported        = reported-travel ).

  ENDMETHOD.

  METHOD precheck_update.

    me->precheck_auth( EXPORTING entities_update = entities
                       CHANGING  failed          = failed-travel
                                 reported        = reported-travel ).

  ENDMETHOD.

  METHOD acceptTravel.

    MODIFY ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
           ENTITY Travel
           UPDATE FIELDS ( OverallStatus )
           WITH VALUE #( FOR key IN keys ( %tky          = key-%tky
                                           OverallStatus = travel_status-accepted ) ).

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Travel
         ALL FIELDS WITH
         CORRESPONDING #( keys )
         RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %param = travel  ) ).


  ENDMETHOD.

  METHOD deductDiscount.

    DATA travels_for_update TYPE TABLE FOR UPDATE z349_r_travel_1457.
    DATA(keys_with_valid_discount) = keys.

    LOOP AT keys_with_valid_discount ASSIGNING FIELD-SYMBOL(<key_with_valid_discount>)
            WHERE %param-discount_percent IS INITIAL
               OR %param-discount_percent > 100
               OR %param-discount_percent <= 0.

      APPEND VALUE #( %tky = <key_with_valid_discount>-%tky ) TO failed-travel.

      APPEND VALUE #( %tky                       = <key_with_valid_discount>-%tky
                      %msg                       = NEW /dmo/cm_flight_messages(
                                                       textid = /dmo/cm_flight_messages=>discount_invalid
                                                       severity = if_abap_behv_message=>severity-error )
                      %element-TotalPrice        = if_abap_behv=>mk-on
                      %op-%action-deductDiscount = if_abap_behv=>mk-on
                    ) TO reported-travel.

      DELETE keys_with_valid_discount.
    ENDLOOP.

    CHECK keys_with_valid_discount IS NOT INITIAL.

    "get total price
    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Travel
         FIELDS ( BookingFee )
         WITH CORRESPONDING #( keys_with_valid_discount )
         RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      DATA percentage TYPE decfloat16.
      DATA(discount_percent) = keys_with_valid_discount[ KEY id  %tky = <travel>-%tky ]-%param-discount_percent.
      percentage =  discount_percent / 100 .
      DATA(reduced_fee) = <travel>-BookingFee * ( 1 - percentage ) .

      APPEND VALUE #( %tky       = <travel>-%tky
                      BookingFee = reduced_fee
                    ) TO travels_for_update.
    ENDLOOP.

    "update total price with reduced price
    MODIFY ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
      ENTITY Travel
       UPDATE FIELDS ( BookingFee )
       WITH travels_for_update.

    "Read changed data for action result
    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
      ENTITY Travel
        ALL FIELDS WITH
        CORRESPONDING #( travels )
      RESULT DATA(travels_with_discount).

    result = VALUE #( FOR travel IN travels_with_discount ( %tky   = travel-%tky
                                                            %param = travel ) ).


  ENDMETHOD.

  METHOD reCalcTotalPrice.

    TYPES: BEGIN OF ty_amount_per_currencycode,
             amount        TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amount_per_currencycode.

    DATA: amount_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Travel
         FIELDS ( BookingFee CurrencyCode )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    DELETE travels WHERE CurrencyCode IS INITIAL.

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      " Set the start for the calculation by adding the booking fee.
      amount_per_currencycode = VALUE #( ( amount        = <travel>-BookingFee
                                           currency_code = <travel>-CurrencyCode ) ).

      " Read all associated bookings
      READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
           ENTITY Travel BY \_Booking
           FIELDS ( FlightPrice CurrencyCode )
           WITH VALUE #( ( %tky = <travel>-%tky ) )
           RESULT DATA(bookings).

      " Add bookings to the total price.
      LOOP AT bookings INTO DATA(booking) WHERE CurrencyCode IS NOT INITIAL.
        COLLECT VALUE ty_amount_per_currencycode( amount        = booking-FlightPrice
                                                  currency_code = booking-CurrencyCode ) INTO amount_per_currencycode.
      ENDLOOP.

      " Read all associated booking supplements
      READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
        ENTITY Booking BY \_BookingSupplement
          FIELDS ( Price CurrencyCode )
        WITH VALUE #( FOR rba_booking IN bookings ( %tky = rba_booking-%tky ) )
        RESULT DATA(bookingsupplements).

      " Add booking supplements to the total price.
      LOOP AT bookingsupplements INTO DATA(bookingsupplement) WHERE CurrencyCode IS NOT INITIAL.
        COLLECT VALUE ty_amount_per_currencycode( amount        = bookingsupplement-Price
                                                  currency_code = bookingsupplement-CurrencyCode ) INTO amount_per_currencycode.
      ENDLOOP.

      CLEAR <travel>-TotalPrice.
      LOOP AT amount_per_currencycode INTO DATA(single_amount_per_currencycode).
        " Currency Conversion
        IF single_amount_per_currencycode-currency_code = <travel>-CurrencyCode.
          <travel>-TotalPrice += single_amount_per_currencycode-amount.
        ELSE.
          /dmo/cl_flight_amdp=>convert_currency(
             EXPORTING
               iv_amount                   =  single_amount_per_currencycode-amount
               iv_currency_code_source     =  single_amount_per_currencycode-currency_code
               iv_currency_code_target     =  <travel>-CurrencyCode
               iv_exchange_rate_date       =  cl_abap_context_info=>get_system_date( )
             IMPORTING
               ev_amount                   = DATA(total_booking_price_per_curr)
            ).
          <travel>-TotalPrice += total_booking_price_per_curr.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    " update the modified total_price of travels
    MODIFY ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
      ENTITY travel
        UPDATE FIELDS ( TotalPrice )
        WITH CORRESPONDING #( travels ).

  ENDMETHOD.

  METHOD rejectTravel.

    MODIFY ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Travel
         UPDATE FIELDS ( OverallStatus )
         WITH VALUE #( FOR key IN keys ( %tky          = key-%tky
                                         OverallStatus = travel_status-rejected ) ).

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Travel
         ALL FIELDS WITH
         CORRESPONDING #( keys )
         RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels ( %tky = travel-%tky
                                              %param = travel  ) ).

  ENDMETHOD.

  METHOD Resume.

    DATA entities_update TYPE t_entities_update.
*
*    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
*         ENTITY Travel
*         FIELDS ( AgencyID )
*         WITH VALUE #( FOR key IN keys
*                        %is_draft = if_abap_behv=>mk-on
*                        ( %key = key-%key )
*                     )
*         RESULT DATA(travels).
*
*    entities_update = CORRESPONDING #( travels CHANGING CONTROL ).
*
*    IF entities_update IS NOT INITIAL.
*      precheck_auth(
*        EXPORTING
*          entities_update = entities_update
*        CHANGING
*          failed          = failed-travel
*          reported        = reported-travel
*      ).
*    ENDIF.

  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
           ENTITY Travel
           EXECUTE reCalcTotalPrice
           FROM CORRESPONDING #( keys ).

  ENDMETHOD.

  METHOD setStatusToOpen.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
           ENTITY Travel
           FIELDS ( OverallStatus )
           WITH CORRESPONDING #( keys )
           RESULT DATA(travels).

    DELETE travels WHERE OverallStatus IS NOT INITIAL.

    CHECK travels IS NOT INITIAL.

    MODIFY ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Travel
         UPDATE FIELDS ( OverallStatus )
         WITH VALUE #( FOR travel IN travels INDEX INTO i ( %tky = travel-%tky
                                                            OverallStatus = travel_status-open ) ).

  ENDMETHOD.

  METHOD setTravelNumber.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Travel
         FIELDS ( TravelID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    DELETE travels WHERE TravelID IS NOT INITIAL.

    CHECK travels IS NOT INITIAL.

    SELECT SINGLE FROM z349_r_travel_1457
            FIELDS MAX( TravelID )
            INTO @DATA(max_TravelID).

    MODIFY ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Travel
         UPDATE FIELDS ( TravelID )
         WITH VALUE #( FOR travel IN travels INDEX INTO i ( %tky = travel-%tky
                                                            TravelID = max_TravelID + i ) ).

  ENDMETHOD.

  METHOD validateAgency.

    DATA: modification_granted TYPE abap_boolean,
          agency_country_code  TYPE land1.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Travel
         FIELDS ( AgencyID
                  TravelID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    DATA agencies TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY client agency_id.

    agencies = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING agency_id = AgencyID EXCEPT * ).
    DELETE agencies WHERE agency_id IS INITIAL.

    IF agencies IS NOT INITIAL.

      SELECT FROM /dmo/agency AS db
             INNER JOIN @agencies AS it ON db~agency_id = it~agency_id
             FIELDS db~agency_id,
                    db~country_code
             INTO TABLE @DATA(valid_agencies).

    ENDIF.

    LOOP AT travels INTO DATA(travel).
      APPEND VALUE #(  %tky               = travel-%tky
                       %state_area        = 'VALIDATE_AGENCY'
                    ) TO reported-travel.

      IF travel-AgencyID IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_AGENCY'
                        %msg                = NEW /dmo/cm_flight_messages(
                                                          textid   = /dmo/cm_flight_messages=>enter_agency_id
                                                          severity = if_abap_behv_message=>severity-error )
                        %element-AgencyID   = if_abap_behv=>mk-on
                       ) TO reported-travel.

      ELSEIF travel-AgencyID IS NOT INITIAL AND NOT line_exists( valid_agencies[ agency_id = travel-AgencyID ] ).
        APPEND VALUE #(  %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #(  %tky               = travel-%tky
                         %state_area        = 'VALIDATE_AGENCY'
                         %msg               = NEW /dmo/cm_flight_messages(
                                                                agency_id = travel-agencyid
                                                                textid    = /dmo/cm_flight_messages=>agency_unkown
                                                                severity  = if_abap_behv_message=>severity-error )
                         %element-AgencyID  = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateBookingFee.
  ENDMETHOD.

  METHOD validateCurrency.
  ENDMETHOD.

  METHOD validateCustomer.


    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY client customer_id.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
       ENTITY Travel
       FIELDS ( CustomerID )
       WITH CORRESPONDING #( keys )
       RESULT DATA(travels).

    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerID EXCEPT * ).

    DELETE customers WHERE customer_id IS INITIAL.

    IF customers IS NOT INITIAL.

      SELECT FROM /dmo/customer AS db
             INNER JOIN @customers AS it ON db~customer_id = it~customer_id
             FIELDS
                  db~customer_id
             INTO TABLE @DATA(valid_customer).

    ENDIF.

    LOOP AT travels INTO DATA(travel).

      APPEND VALUE #( %tky          = travel-%tky
                       %state_area = 'VALIDATE_CUSTOMER' ) TO reported-travel.

      IF travel-CustomerID IS INITIAL.

        APPEND VALUE #( %tky          = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky            = travel-%tky
                         %state_area    = 'VALIDATE_CUSTOMER'
                         %msg          = NEW /dmo/cm_flight_messages(
                            textid = /dmo/cm_flight_messages=>enter_customer_id
                            severity = if_abap_behv_message=>severity-error
                         )
                         %element-CustomerID = if_abap_behv=>mk-on
                       ) TO reported-travel.

      ELSEIF NOT line_exists( valid_customer[ customer_id = travel-CustomerID ] ).

        APPEND VALUE #( %tky          = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky            = travel-%tky
                         %state_area    = 'VALIDATE_CUSTOMER'
                         %msg          = NEW /dmo/cm_flight_messages(
                            textid = /dmo/cm_flight_messages=>customer_unkown
                            customer_id = travel-CustomerID
                            severity = if_abap_behv_message=>severity-error
                         )
                         %element-CustomerID = if_abap_behv=>mk-on
                       ) TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateDates.

    READ ENTITIES OF z349_r_travel_1457 IN LOCAL MODE
         ENTITY Travel
         FIELDS ( BeginDate
                  EndDate
                  TravelID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).

      APPEND VALUE #(  %tky         = travel-%tky
                       %state_area  = 'VALIDATE_DATES' ) TO reported-travel.

      IF travel-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = NEW /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

      IF travel-EndDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg                = NEW /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_end_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-EndDate   = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

      IF travel-EndDate < travel-BeginDate AND travel-BeginDate IS NOT INITIAL
                                           AND travel-EndDate IS NOT INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                                textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                                                begin_date = travel-BeginDate
                                                                end_date   = travel-EndDate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

      IF travel-BeginDate < cl_abap_context_info=>get_system_date( ) AND travel-BeginDate IS NOT INITIAL.
        APPEND VALUE #( %tky               = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                         %msg              = NEW /dmo/cm_flight_messages(
                                                                begin_date = travel-BeginDate
                                                                textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD is_create_granted.

    IF country_code IS SUPPLIED.

      AUTHORITY-CHECK OBJECT '/DMO/TRVL'
                          ID '/DMO/CNTRY' FIELD country_code
                          ID 'ACTVT'      FIELD '01'.

      create_granted = COND #( WHEN sy-subrc EQ 0
                               THEN abap_true
                               ELSE abap_false ).

    ENDIF.

    "Giving Full Access
    create_granted = abap_true.

  ENDMETHOD.

  METHOD is_delete_granted.

    IF country_code IS SUPPLIED.

      AUTHORITY-CHECK OBJECT '/DMO/TRVL'
                          ID '/DMO/CNTRY' FIELD country_code
                          ID 'ACTVT'      FIELD '06'.

      delete_granted = COND #( WHEN sy-subrc EQ 0
                               THEN abap_true
                               ELSE abap_false ).

    ENDIF.

    "Giving Full Access
    delete_granted = abap_true.

  ENDMETHOD.

  METHOD is_update_granted.

    IF country_code IS SUPPLIED.

      AUTHORITY-CHECK OBJECT '/DMO/TRVL'
                          ID '/DMO/CNTRY' FIELD country_code
                          ID 'ACTVT'      FIELD '02'.

      update_granted = COND #( WHEN sy-subrc EQ 0
                               THEN abap_true
                               ELSE abap_false ).

    ENDIF.

    "Giving Full Access
    update_granted = abap_true.

  ENDMETHOD.

  METHOD precheck_auth.

    DATA: entities          TYPE t_entities_update,
          operation         TYPE if_abap_behv=>t_char01,
          agencies          TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY client agency_id,
          is_modify_granted TYPE abap_bool.

    " Either entities_create or entities_update is provided.  NOT both and at least one.
    ASSERT NOT ( entities_create IS INITIAL EQUIV entities_update IS INITIAL ).

    IF entities_create IS NOT INITIAL.
      entities = CORRESPONDING #( entities_create MAPPING %cid_ref = %cid ).
      operation = if_abap_behv=>op-m-create.
    ELSE.
      entities = entities_update.
      operation = if_abap_behv=>op-m-update.
    ENDIF.

    DELETE entities WHERE %control-AgencyID = if_abap_behv=>mk-off.

    agencies = CORRESPONDING #( entities DISCARDING DUPLICATES MAPPING agency_id = AgencyID EXCEPT * ).

    CHECK agencies IS NOT INITIAL.

    SELECT FROM /dmo/agency AS db
           INNER JOIN @agencies AS it ON db~agency_id = it~agency_id
           FIELDS db~agency_id,
                  db~country_code
           INTO TABLE @DATA(agency_country_codes).

    LOOP AT entities INTO DATA(entity).
      is_modify_granted = abap_false.

      READ TABLE agency_country_codes WITH KEY agency_id = entity-AgencyID
                   ASSIGNING FIELD-SYMBOL(<agency_country_code>).

      "If invalid or initial AgencyID -> validateAgency
      CHECK sy-subrc = 0.

      CASE operation.

        WHEN if_abap_behv=>op-m-create.
          is_modify_granted = is_create_granted( <agency_country_code>-country_code ).

        WHEN if_abap_behv=>op-m-update.
          is_modify_granted = is_update_granted( <agency_country_code>-country_code ).

      ENDCASE.

      IF is_modify_granted = abap_false.
        APPEND VALUE #(
                         %cid      = COND #( WHEN operation = if_abap_behv=>op-m-create THEN entity-%cid_ref )
                         %tky      = entity-%tky
                       ) TO failed.

        APPEND VALUE #(
                         %cid      = COND #( WHEN operation = if_abap_behv=>op-m-create THEN entity-%cid_ref )
                         %tky      = entity-%tky
                         %msg      = NEW /dmo/cm_flight_messages(
                                                 textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                 agency_id = entity-AgencyID
                                                 severity  = if_abap_behv_message=>severity-error )
                         %element-AgencyID   = if_abap_behv=>mk-on
                      ) TO reported.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
