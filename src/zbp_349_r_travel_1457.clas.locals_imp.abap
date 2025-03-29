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

*      else.
*
*        IF lv_technical_name = 'CB9980011457'.
*            update_granted = abap_true.
*        ENDIF.

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
  ENDMETHOD.

  METHOD reCalcTotalPrice.
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
  ENDMETHOD.

  METHOD calculateTotalPrice.
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
  ENDMETHOD.

ENDCLASS.
