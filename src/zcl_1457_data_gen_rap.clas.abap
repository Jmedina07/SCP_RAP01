CLASS zcl_1457_data_gen_rap DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_1457_data_gen_rap IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.


    out->write( 'Adding Travel data' ).

    DELETE FROM z349_travel_1457.

    INSERT z349_travel_1457 FROM (
    SELECT FROM /dmo/travel
      FIELDS
        " client
        uuid( ) AS travel_uuid,
        travel_id,
        agency_id,
        customer_id,
        begin_date,
        end_date,
        booking_fee,
        total_price,
        currency_code,
        description,
        CASE status WHEN 'B' THEN 'A'
                    WHEN 'P' THEN 'O'
                    WHEN 'N' THEN 'O'
                    ELSE 'X' END AS overall_status,
        createdby AS local_created_by,
        createdat AS local_created_at,
        lastchangedby AS local_last_changed_by,
        lastchangedat AS local_last_changed_at,
        lastchangedat AS last_changed_at

    ).

    out->write( 'Adding Booking data' ).

    DELETE FROM z349_booking_457.

    INSERT z349_booking_457 FROM (

        SELECT
          FROM /dmo/booking
          JOIN z349_travel_1457 ON /dmo/booking~travel_id = z349_travel_1457~travel_id
          JOIN /dmo/travel ON /dmo/travel~travel_id = /dmo/booking~travel_id
          FIELDS  "client,
                  uuid( ) AS booking_uuid,
                  z349_travel_1457~travel_uuid AS parent_uuid,
                  /dmo/booking~booking_id,
                  /dmo/booking~booking_date,
                  /dmo/booking~customer_id,
                  /dmo/booking~carrier_id,
                  /dmo/booking~connection_id,
                  /dmo/booking~flight_date,
                  /dmo/booking~flight_price,
                  /dmo/booking~currency_code,
                  CASE /dmo/travel~status WHEN 'P' THEN 'N'
                                                   ELSE /dmo/travel~status END AS booking_status,
                  z349_travel_1457~last_changed_at AS local_last_changed_at ).


    DELETE FROM z349_bksuppl_457.

    out->write( 'Adding Booking Supplements data' ).

    INSERT z349_bksuppl_457 FROM (
       SELECT FROM /dmo/book_suppl AS supp
              JOIN z349_travel_1457  AS trvl ON trvl~travel_id = supp~travel_id
              JOIN z349_booking_457 AS book ON book~parent_uuid = trvl~travel_uuid
                                         AND book~booking_id = supp~booking_id
              FIELDS
              uuid( )                 AS booksuppl_uuid,
              trvl~travel_uuid        AS root_uuid,
              book~booking_uuid       AS parent_uuid,
              supp~booking_supplement_id,
              supp~supplement_id,
              supp~price,
              supp~currency_code,
              trvl~last_changed_at    AS local_last_changed_at

    ).



  ENDMETHOD.
ENDCLASS.
