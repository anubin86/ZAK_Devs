CLASS zbp_i_travel_m DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF ZI_TRAVEL_M.

ENDCLASS.

CLASS zbp_i_travel_m IMPLEMENTATION.
ENDCLASS.


CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS copyTravel   FOR MODIFY
      IMPORTING keys FOR ACTION Travel~copyTravel   RESULT result.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDates.

    METHODS validateStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateStatus.

    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~setInitialStatus.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~calculateTotalPrice.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_global_authorizations.
    AUTHORITY-CHECK OBJECT 'S_CARRID'
      ID 'ACTVT' FIELD '01'.
    IF sy-subrc = 0.
      result-%action-acceptTravel = if_abap_behv=>auth-allowed.
      result-%action-rejectTravel = if_abap_behv=>auth-allowed.
      result-%action-copyTravel   = if_abap_behv=>auth-allowed.
      result-%create              = if_abap_behv=>auth-allowed.
    ELSE.
      result-%action-acceptTravel = if_abap_behv=>auth-unauthorized.
      result-%action-rejectTravel = if_abap_behv=>auth-unauthorized.
      result-%action-copyTravel   = if_abap_behv=>auth-unauthorized.
      result-%create              = if_abap_behv=>auth-unauthorized.
    ENDIF.
  ENDMETHOD.

  METHOD acceptTravel.
    MODIFY ENTITIES OF ZI_TRAVEL_M IN LOCAL MODE
      ENTITY Travel
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys
                        ( %tky         = key-%tky
                          OverallStatus = 'A' ) ) "A = Accepted
      REPORTED DATA(update_reported).
    result = VALUE #( FOR key IN keys
                        ( %tky = key-%tky
                          %param = VALUE #( TravelUUID    = key-%key-TravelUUID
                                           OverallStatus = 'A' ) ) ).
    APPEND LINES OF update_reported-travel TO reported-travel.
  ENDMETHOD.

  METHOD rejectTravel.
    MODIFY ENTITIES OF ZI_TRAVEL_M IN LOCAL MODE
      ENTITY Travel
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys
                        ( %tky         = key-%tky
                          OverallStatus = 'X' ) ) "X = Rejected
      REPORTED DATA(update_reported).
    result = VALUE #( FOR key IN keys
                        ( %tky = key-%tky
                          %param = VALUE #( TravelUUID    = key-%key-TravelUUID
                                           OverallStatus = 'X' ) ) ).
    APPEND LINES OF update_reported-travel TO reported-travel.
  ENDMETHOD.

  METHOD copyTravel.
    READ ENTITIES OF ZI_TRAVEL_M IN LOCAL MODE
      ENTITY Travel
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(travels)
      FAILED DATA(read_failed).
    APPEND LINES OF read_failed-travel TO failed-travel.

    DATA new_travels TYPE TABLE FOR CREATE ZI_TRAVEL_M\\Travel.
    new_travels = VALUE #( FOR travel IN travels
                             ( %cid          = travel-TravelUUID
                               AgencyID      = travel-AgencyID
                               CustomerID    = travel-CustomerID
                               BeginDate     = travel-BeginDate
                               EndDate       = travel-EndDate
                               BookingFee    = travel-BookingFee
                               TotalPrice    = travel-TotalPrice
                               CurrencyCode  = travel-CurrencyCode
                               Description   = travel-Description
                               OverallStatus = 'O' ) ).

    MODIFY ENTITIES OF ZI_TRAVEL_M IN LOCAL MODE
      ENTITY Travel CREATE FROM new_travels
      MAPPED   DATA(mapped_create)
      FAILED   DATA(create_failed)
      REPORTED DATA(create_reported).

    APPEND LINES OF create_failed-travel   TO failed-travel.
    APPEND LINES OF create_reported-travel TO reported-travel.

    result = VALUE #( FOR key IN keys INDEX INTO idx
                        ( %tky   = key-%tky
                          %param = mapped_create-travel[ idx ] ) ).
  ENDMETHOD.

  METHOD validateCustomer.
    READ ENTITIES OF ZI_TRAVEL_M IN LOCAL MODE
      ENTITY Travel
        FIELDS ( CustomerID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    DATA customers TYPE SORTED TABLE OF /dmo/customer
                        WITH UNIQUE KEY customer_id.

    customers = CORRESPONDING #( travels DISCARDING DUPLICATES
                                  MAPPING customer_id = CustomerID EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.
    IF customers IS NOT INITIAL.
      SELECT FROM /dmo/customer
        FIELDS customer_id
        FOR ALL ENTRIES IN @customers
        WHERE customer_id = @customers-customer_id
        INTO TABLE @DATA(valid_customers).
    ENDIF.

    LOOP AT travels INTO DATA(travel).
      IF travel-CustomerID IS INITIAL
        OR NOT line_exists( valid_customers[ customer_id = travel-CustomerID ] ).
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky              = travel-%tky
                        %state_area       = 'VALIDATE_CUSTOMER'
                        %msg              = NEW /dmo/cx_flight_legacy(
                                              textid     = /dmo/cx_flight_legacy=>customer_unknown
                                              customer_id = travel-CustomerID )
                        %element-CustomerID = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDates.
    READ ENTITIES OF ZI_TRAVEL_M IN LOCAL MODE
      ENTITY Travel
        FIELDS ( BeginDate EndDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).
      IF travel-EndDate < travel-BeginDate.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky             = travel-%tky
                        %state_area      = 'VALIDATE_DATES'
                        %msg             = NEW /dmo/cx_flight_legacy(
                                             textid    = /dmo/cx_flight_legacy=>end_date_before_begin_date
                                             begin_date = travel-BeginDate
                                             end_date   = travel-EndDate )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on ) TO reported-travel.
      ELSEIF travel-BeginDate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky             = travel-%tky
                        %state_area      = 'VALIDATE_DATES'
                        %msg             = NEW /dmo/cx_flight_legacy(
                                             textid     = /dmo/cx_flight_legacy=>begin_date_before_system_date
                                             begin_date = travel-BeginDate )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateStatus.
    READ ENTITIES OF ZI_TRAVEL_M IN LOCAL MODE
      ENTITY Travel
        FIELDS ( OverallStatus )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).
      IF travel-OverallStatus <> 'O'  "Open
        AND travel-OverallStatus <> 'A'  "Accepted
        AND travel-OverallStatus <> 'X'. "Rejected
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky                  = travel-%tky
                        %state_area           = 'VALIDATE_STATUS'
                        %msg                  = NEW /dmo/cx_flight_legacy(
                                                  textid = /dmo/cx_flight_legacy=>status_is_not_valid
                                                  status = travel-OverallStatus )
                        %element-OverallStatus = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD setInitialStatus.
    MODIFY ENTITIES OF ZI_TRAVEL_M IN LOCAL MODE
      ENTITY Travel
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys
                        ( %tky         = key-%tky
                          OverallStatus = 'O' ) ).
  ENDMETHOD.

  METHOD calculateTotalPrice.
    READ ENTITIES OF ZI_TRAVEL_M IN LOCAL MODE
      ENTITY Travel
        FIELDS ( BookingFee CurrencyCode )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      MODIFY ENTITIES OF ZI_TRAVEL_M IN LOCAL MODE
        ENTITY Travel
          UPDATE FIELDS ( TotalPrice )
          WITH VALUE #( ( %tky       = <travel>-%tky
                          TotalPrice = <travel>-BookingFee ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
