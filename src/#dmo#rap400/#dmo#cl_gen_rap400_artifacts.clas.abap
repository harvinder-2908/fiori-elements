CLASS /dmo/cl_gen_rap400_artifacts DEFINITION

PUBLIC
  INHERITING FROM cl_xco_cp_adt_simple_classrun
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS constructor.

  PROTECTED SECTION.
    METHODS main REDEFINITION.

  PRIVATE SECTION.

    CONSTANTS:
      co_prefix         TYPE string       VALUE 'ZRAP400_',
      co_zlocal_package TYPE sxco_package VALUE 'ZLOCAL',
      co_session_name   TYPE string       VALUE 'RAP400'.

    DATA:
      package_name              TYPE sxco_package,
      unique_group_id           TYPE string,
      dev_system_environment    TYPE REF TO if_xco_cp_gen_env_dev_system,
      transport                 TYPE sxco_transport,
      transport_request         TYPE sxco_transport,
      table_name_root           TYPE sxco_dbt_object_name,
      table_name_child          TYPE sxco_dbt_object_name,
      data_generator_class_name TYPE sxco_ad_object_name.

    TYPES:
      BEGIN OF t_table_fields,
        field                  TYPE sxco_ad_field_name,
        is_key                 TYPE abap_bool,
        not_null               TYPE abap_bool,
        currencyCode           TYPE sxco_cds_field_name,
        unitOfMeasure          TYPE sxco_cds_field_name,
        data_element           TYPE sxco_ad_object_name,
        built_in_type          TYPE cl_xco_ad_built_in_type=>tv_type,
        built_in_type_length   TYPE cl_xco_ad_built_in_type=>tv_length,
        built_in_type_decimals TYPE cl_xco_ad_built_in_type=>tv_decimals,
      END OF t_table_fields,

      tt_fields TYPE STANDARD TABLE OF t_table_fields WITH KEY field.

    "methods
    METHODS generate_table  IMPORTING io_put_operation        TYPE REF TO if_xco_cp_gen_d_o_put
                                      table_fields            TYPE tt_fields
                                      table_name              TYPE sxco_dbt_object_name
                                      table_short_description TYPE if_xco_cp_gen_tabl_dbt_s_form=>tv_short_description.

    METHODS get_root_table_fields         RETURNING VALUE(root_table_fields)  TYPE tt_fields.
    METHODS get_child_table_fields        RETURNING VALUE(child_table_fields) TYPE tt_fields.
    METHODS get_json_string               RETURNING VALUE(json_string)        TYPE string.
    METHODS generate_cds_mde              IMPORTING VALUE(io_rap_bo_node)     TYPE REF TO /dmo/cl_rap_node.
    METHODS get_unique_suffix             IMPORTING VALUE(s_prefix)           TYPE string RETURNING VALUE(s_unique_suffix) TYPE string.
    METHODS create_transport              RETURNING VALUE(lo_transport)       TYPE sxco_transport.
    METHODS create_package                IMPORTING VALUE(lo_transport)       TYPE sxco_transport.
    METHODS generate_data_generator_class IMPORTING VALUE(lo_transport)       TYPE sxco_transport io_put_operation TYPE REF TO if_xco_cp_gen_d_o_put .
    METHODS release_data_generator_class  IMPORTING VALUE(lo_transport)       TYPE sxco_transport.

ENDCLASS.



CLASS /DMO/CL_GEN_RAP400_ARTIFACTS IMPLEMENTATION.


  METHOD constructor.
    super->constructor( ).

    unique_group_id           = get_unique_suffix( co_prefix ).            "your group ID/suffix
    package_name              = |{ co_prefix }TRAVEL_{ unique_group_id }|. "your package name
    table_name_root           = |{ co_prefix }trav{ unique_group_id }|.
    table_name_child          = |{ co_prefix }book{ unique_group_id }|.
    data_generator_class_name = |{ co_prefix }CL_GEN_DATA_{ unique_group_id }|.
  ENDMETHOD.


  METHOD create_package.
    DATA(lo_put_operation) = xco_cp_generation=>environment->dev_system( lo_transport )->for-devc->create_put_operation( ).
    DATA(lo_specification) = lo_put_operation->add_object( package_name )->create_form_specification( ).
    lo_specification->set_short_description( |{ co_session_name } tutorial package - { unique_group_id }|  ).
    lo_specification->properties->set_super_package( co_zlocal_package )->set_software_component( co_zlocal_package ).
    lo_put_operation->execute( ).
  ENDMETHOD.


  METHOD create_transport.
    DATA(ls_package) = xco_cp_abap_repository=>package->for( co_zlocal_package )->read( ).
    DATA(lv_transport_layer) = ls_package-property-transport_layer->value.
    DATA(lv_transport_target) = ls_package-property-transport_layer->get_transport_target( )->value.
    DATA(lo_transport_request) = xco_cp_cts=>transports->workbench( lv_transport_target )->create_request( |{ co_session_name } generated request - { unique_group_id }| ).
*    "IF lo_transport_request->get_status(  ) = xco_cp_transport=>filter->status( xco_cp_transport=>status->modifiable ).
*    "    DATA(lo_transport_modifiable) = abap_true.
*    "ENDIF.
    lo_transport = lo_transport_request->value.
  ENDMETHOD.


  METHOD generate_cds_mde.
    DATA: pos              TYPE i VALUE 0,
          lo_field         TYPE REF TO if_xco_gen_ddlx_s_fo_field,
          lv_del_transport TYPE sxco_transport.

    DATA(cts_obj) = xco_cp_abap_repository=>object->for(
    EXPORTING
    iv_type = 'DDLX'
    iv_name = to_upper( io_rap_bo_node->root_node->rap_node_objects-meta_data_extension )
    )->if_xco_cts_changeable~get_object( ).
    lv_del_transport = cts_obj->get_lock( )->get_transport( ).
    lv_del_transport = xco_cp_cts=>transport->for( lv_del_transport )->get_request( )->value.

    DATA(mo_environment)   = xco_cp_generation=>environment->dev_system( lv_del_transport ).
    DATA(mo_put_operation) = mo_environment->create_put_operation( ).
    DATA(lv_package)       = io_rap_bo_node->root_node->package.

    DATA(lo_specification) = mo_put_operation->for-ddlx->add_object(  io_rap_bo_node->rap_node_objects-meta_data_extension
      )->set_package( lv_package
      )->create_form_specification( ).

    lo_specification->set_short_description( |MDE for { io_rap_bo_node->rap_node_objects-alias }|
      )->set_layer( xco_cp_metadata_extension=>layer->customer
      )->set_view( io_rap_bo_node->rap_node_objects-cds_view_p ). .

    lo_specification->add_annotation( 'UI' )->value->build(
    )->begin_record(
        )->add_member( 'headerInfo'
         )->begin_record(
          )->add_member( 'typeName' )->add_string( io_rap_bo_node->rap_node_objects-alias && ''
          )->add_member( 'typeNamePlural' )->add_string( io_rap_bo_node->rap_node_objects-alias && 's'
          )->add_member( 'title'
            )->begin_record(
              )->add_member( 'type' )->add_enum( 'STANDARD'
              )->add_member( 'label' )->add_string( io_rap_bo_node->rap_node_objects-alias && ''
              )->add_member( 'value' )->add_string( io_rap_bo_node->object_id_cds_field_name && ''
        )->end_record(
        )->end_record(
      "presentationVariant: [ { sortOrder: [{ by: 'TravelID', direction:  #DESC }], visualizations: [{type: #AS_LINEITEM}] }] }
      )->add_member( 'presentationVariant'
        )->begin_array(
          )->begin_record(
          )->add_member( 'sortOrder'
            )->begin_array(
             )->begin_record(
               )->add_member( 'by' )->add_string( 'TravelID'
               )->add_member( 'direction' )->add_enum( 'DESC'
             )->end_record(
            )->end_array(
          )->add_member( 'visualizations'
          )->begin_array(
             )->begin_record(
               )->add_member( 'type' )->add_enum( 'AS_LINEITEM'
             )->end_record(
            )->end_array(
          )->end_record(
          )->end_array(
          )->end_record(  ).


    LOOP AT io_rap_bo_node->lt_fields INTO  DATA(ls_header_fields) WHERE name <> io_rap_bo_node->field_name-client.
      "increase position
      pos += 10.
      lo_field = lo_specification->add_field( ls_header_fields-cds_view_field ).

      "put facet annotation in front of the first
      IF pos = 10.
        IF io_rap_bo_node->is_root(  ) = abap_true.
          IF io_rap_bo_node->has_childs(  ).
            lo_field->add_annotation( 'UI.facet' )->value->build(
              )->begin_array(
                )->begin_record(
                  )->add_member( 'id' )->add_string( 'idCollection'
                  )->add_member( 'type' )->add_enum( 'COLLECTION'
                  )->add_member( 'label' )->add_string( io_rap_bo_node->rap_node_objects-alias && ''
                  )->add_member( 'position' )->add_number( 10
                )->end_record(
                )->begin_record(
                  )->add_member( 'id' )->add_string( 'idIdentification'
                  )->add_member( 'parentId' )->add_string( 'idCollection'
                  )->add_member( 'type' )->add_enum( 'IDENTIFICATION_REFERENCE'
                  )->add_member( 'label' )->add_string( 'General Information'
                  )->add_member( 'position' )->add_number( 10
                )->end_record(
                )->begin_record(
                  )->add_member( 'id' )->add_string( 'idLineitem'
                  )->add_member( 'type' )->add_enum( 'LINEITEM_REFERENCE'
                  )->add_member( 'label' )->add_string( io_rap_bo_node->childnodes[ 1 ]->rap_node_objects-alias && ''
                  )->add_member( 'position' )->add_number( 20
                  )->add_member( 'targetElement' )->add_string( '_' && io_rap_bo_node->childnodes[ 1 ]->rap_node_objects-alias
                )->end_record(
              )->end_array( ).
          ELSE.
            lo_field->add_annotation( 'UI.facet' )->value->build(
              )->begin_array(
                )->begin_record(
                  )->add_member( 'id' )->add_string( 'idCollection'
                  )->add_member( 'type' )->add_enum( 'COLLECTION'
                  )->add_member( 'label' )->add_string( io_rap_bo_node->rap_node_objects-alias && ''
                  )->add_member( 'position' )->add_number( 10
                )->end_record(
                )->begin_record(
                  )->add_member( 'id' )->add_string( 'idIdentification'
                  )->add_member( 'parentId' )->add_string( 'idCollection'
                  )->add_member( 'type' )->add_enum( 'IDENTIFICATION_REFERENCE'
                  )->add_member( 'label' )->add_string( 'General Information'
                  )->add_member( 'position' )->add_number( 10
                )->end_record(
              )->end_array( ).
          ENDIF.
        ELSE.
          IF io_rap_bo_node->has_childs(  ).
            lo_field->add_annotation( 'UI.facet' )->value->build(
              )->begin_array(
                )->begin_record(
                  )->add_member( 'id' )->add_string( 'id' && io_rap_bo_node->rap_node_objects-alias
                  )->add_member( 'purpose' )->add_enum( 'STANDARD'
                  )->add_member( 'type' )->add_enum( 'IDENTIFICATION_REFERENCE'
                  )->add_member( 'label' )->add_string( CONV #( io_rap_bo_node->rap_node_objects-alias )
                  )->add_member( 'position' )->add_number( 10
                )->end_record(
                )->begin_record(
                    )->add_member( 'id' )->add_string( 'idLineitem'
                    )->add_member( 'type' )->add_enum( 'LINEITEM_REFERENCE'
                    )->add_member( 'label' )->add_string( io_rap_bo_node->childnodes[ 1 ]->rap_node_objects-alias && ''
                    )->add_member( 'position' )->add_number( 20
                    )->add_member( 'targetElement' )->add_string( '_' && io_rap_bo_node->childnodes[ 1 ]->rap_node_objects-alias
                  )->end_record(
              )->end_array( ).
          ELSE.
            lo_field->add_annotation( 'UI.facet' )->value->build(
              )->begin_array(
                )->begin_record(
                  )->add_member( 'id' )->add_string( 'id' && io_rap_bo_node->rap_node_objects-alias
                  )->add_member( 'purpose' )->add_enum( 'STANDARD'
                  )->add_member( 'type' )->add_enum( 'IDENTIFICATION_REFERENCE'
                  )->add_member( 'label' )->add_string( CONV #( io_rap_bo_node->rap_node_objects-alias )
                  )->add_member( 'position' )->add_number( 10
                )->end_record(
              )->end_array( ).
          ENDIF.
        ENDIF.
      ENDIF.

      CASE to_upper( ls_header_fields-name ).
        WHEN io_rap_bo_node->field_name-uuid.
          "hide technical key field (uuid)
          lo_field->add_annotation( 'UI.hidden' )->value->build(  )->add_boolean( iv_value =  abap_true ).

        WHEN io_rap_bo_node->field_name-last_changed_at OR io_rap_bo_node->field_name-last_changed_by OR
             io_rap_bo_node->field_name-created_at OR io_rap_bo_node->field_name-created_by OR
             io_rap_bo_node->field_name-local_instance_last_changed_at OR
             io_rap_bo_node->field_name-parent_uuid OR io_rap_bo_node->field_name-root_uuid.
          "hide administrative fields and guid-based fields
          lo_field->add_annotation( 'UI.hidden' )->value->build(  )->add_boolean( iv_value =  abap_true ).

        WHEN 'CURRENCY_CODE'.
          "do nothing.
          "The currency key will automatically be displayed with the associated amount fields
          "thanks to annotations maintained in the corresponding projection view

        WHEN OTHERS.
          "display field
          DATA lo_valuebuilder TYPE REF TO if_xco_gen_cds_s_fo_ann_v_bldr .

          IF ls_header_fields-name <> 'CURRENCY_CODE' AND ls_header_fields-name <> 'DESCRIPTION'
            AND ls_header_fields-name <> 'TOTAL_PRICE' AND ls_header_fields-name <> 'BOOKING_FEE'.
            "line item page
            lo_valuebuilder = lo_field->add_annotation( 'UI.lineItem' )->value->build( ).
            DATA(lo_record) = lo_valuebuilder->begin_array(
            )->begin_record(
                )->add_member( 'position' )->add_number( pos  ").
                )->add_member( 'importance' )->add_enum( 'HIGH').

            "label for fields based on a built-in type
            IF ls_header_fields-is_data_element = abap_false.
              lo_record->add_member( 'label' )->add_string( CONV #( ls_header_fields-cds_view_field ) ).
            ENDIF.
            lo_valuebuilder->end_record( )->end_array( ).
          ENDIF.

          "object page
          lo_valuebuilder = lo_field->add_annotation( 'UI.identification' )->value->build( ).
          lo_record = lo_valuebuilder->begin_array(
          )->begin_record(
              )->add_member( 'position' )->add_number( pos ).
          IF ls_header_fields-is_data_element = abap_false.
            lo_record->add_member( 'label' )->add_string( CONV #( ls_header_fields-cds_view_field ) ).
          ENDIF.
          lo_valuebuilder->end_record( )->end_array( ).

          "selection fields
          IF
             ls_header_fields-name = 'CUSTOMER_ID' OR
             ls_header_fields-name = 'AGENCY_ID' .

            lo_field->add_annotation( 'UI.selectionField' )->value->build(
            )->begin_array(
            )->begin_record(
                )->add_member( 'position' )->add_number( pos
              )->end_record(
            )->end_array( ).
          ENDIF.
          IF io_rap_bo_node->is_root(  ) = abap_true AND
             io_rap_bo_node->get_implementation_type( ) = io_rap_bo_node->implementation_type-managed_uuid  AND
             ls_header_fields-name = io_rap_bo_node->object_id.

            lo_field->add_annotation( 'UI.selectionField' )->value->build(
            )->begin_array(
            )->begin_record(
                )->add_member( 'position' )->add_number( pos
              )->end_record(
            )->end_array( ).
          ENDIF.
      ENDCASE.
    ENDLOOP.

    mo_put_operation->execute(  ).
  ENDMETHOD.


  METHOD generate_data_generator_class.

    DATA(lo_specification) = io_put_operation->for-clas->add_object(  data_generator_class_name
                                      )->set_package( package_name
                                      )->create_form_specification( ).
    lo_specification->set_short_description( |This class generates the test data| ).
    lo_specification->set_short_description( 'Data generator class' ).
    lo_specification->definition->add_interface( 'if_oo_adt_classrun' ).
    lo_specification->implementation->add_method( |if_oo_adt_classrun~main|
      )->set_source( VALUE #(
        "business logic to fill both tables with demo data
        ( |      DELETE FROM ('{ table_name_root }').| )
        ( |     " insert travel demo data | )
        ( |     INSERT ('{ table_name_root }')  FROM ( | )
        ( |         SELECT | )
        ( |           FROM /dmo/travel AS travel | )
        ( |           FIELDS | )
        ( |             travel~travel_id        AS travel_id, | )
        ( |             travel~agency_id        AS agency_id, | )
        ( |             travel~customer_id      AS customer_id, | )
        ( |             travel~begin_date       AS begin_date, | )
        ( |             travel~end_date         AS end_date, | )
        ( |             travel~booking_fee      AS booking_fee, | )
        ( |             travel~total_price      AS total_price, | )
        ( |             travel~currency_code    AS currency_code, | )
        ( |             travel~description      AS description, | )
        ( |             CASE travel~status    "Status [N(New) \| P(Planned) \| B(Booked) \| X(Cancelled)] | )
        ( |               WHEN 'N' THEN 'O' | )
        ( |               WHEN 'P' THEN 'O' | )
        ( |               WHEN 'B' THEN 'A' | )
        ( |               ELSE 'X' | )
        ( |             END                     AS overall_status,  "Travel Status [A(Accepted) \| O(Open) \| X(Cancelled)] | )
        ( |             travel~createdby        AS created_by, | )
        ( |             travel~createdat        AS created_at, | )
        ( |             travel~lastchangedby    AS last_changed_by, | )
        ( |             travel~lastchangedat    AS last_changed_at | )
        ( |             ORDER BY travel_id UP TO 50 ROWS | )
        ( |       ). | )
        ( |     COMMIT WORK. | )

        ( |     " define FROM clause dynamically | )
        ( |     DATA: dyn_table_name TYPE string. | )
        ( |     dyn_table_name = \| /dmo/booking    AS booking  \| | )
        ( |                  && \| JOIN \{ '{ table_name_root }' \} AS z \|  | )
        ( |                  && \| ON   booking~travel_id = z~travel_id \|. | )

        ( |     DELETE FROM ('{ table_name_child }'). | )
        ( |     " insert booking demo data | )
        ( |     INSERT ('{ table_name_child }') FROM ( | )
        ( |         SELECT | )
        ( |           FROM (dyn_table_name) | )
        ( |           FIELDS | )
        ( |             z~travel_id             AS travel_id           , | )
        ( |             booking~booking_id      AS booking_id            , | )
        ( |             booking~booking_date    AS booking_date          ,| )
        ( |             booking~customer_id     AS customer_id           ,| )
        ( |             booking~carrier_id      AS carrier_id            ,| )
        ( |             booking~connection_id   AS connection_id         ,| )
        ( |             booking~flight_date     AS flight_date           ,| )
        ( |             booking~flight_price    AS flight_price          ,| )
        ( |             booking~currency_code   AS currency_code         ,| )
        ( |             CASE z~overall_status    ""Travel Status [A(Accepted) \| O(Open) \| X(Cancelled)]| )
        ( |               WHEN 'O' THEN 'N'| )
        ( |               WHEN 'P' THEN 'N'| )
        ( |               WHEN 'A' THEN 'B'| )
        ( |               ELSE 'X'| )
        ( |             END                     AS booking_status,   "Booking Status [N(New) \| B(Booked) \| X(Cancelled)]| )
        ( |             z~last_changed_at       AS last_changed_at| )
        ( |       ).| )
        ( |     COMMIT WORK.| )
      ) ).
  ENDMETHOD.


  METHOD generate_table.
    DATA(lo_specification) = io_put_operation->for-tabl-for-database_table->add_object( table_name
              )->set_package( package_name
               )->create_form_specification( ).

    lo_specification->set_short_description( table_short_description ).
    lo_specification->set_data_maintenance( xco_cp_database_table=>data_maintenance->allowed_with_restrictions ).
    lo_specification->set_delivery_class( xco_cp_database_table=>delivery_class->c ).

    DATA database_table_field  TYPE REF TO if_xco_gen_tabl_dbt_s_fo_field  .

    LOOP AT table_fields INTO DATA(table_field_line).
      database_table_field = lo_specification->add_field( table_field_line-field  ).

      IF table_field_line-is_key = abap_true.
        database_table_field->set_key_indicator( ).
      ENDIF.
      IF table_field_line-not_null = abap_true.
        database_table_field->set_not_null( ).
      ENDIF.
      IF table_field_line-currencycode IS NOT INITIAL.
        database_table_field->currency_quantity->set_reference_table( CONV #( to_upper( table_name ) ) )->set_reference_field( to_upper( table_field_line-currencycode ) ).
      ENDIF.
      IF table_field_line-unitofmeasure IS NOT INITIAL.
        database_table_field->currency_quantity->set_reference_table( CONV #( to_upper( table_name ) ) )->set_reference_field( to_upper( table_field_line-unitofmeasure ) ).
      ENDIF.
      IF table_field_line-data_element IS NOT INITIAL.
        database_table_field->set_type( xco_cp_abap_dictionary=>data_element( table_field_line-data_element ) ).
      ELSE.
        CASE  to_lower( table_field_line-built_in_type ).
          WHEN 'accp'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->accp ).
          WHEN 'clnt'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->clnt ).
          WHEN 'cuky'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->cuky ).
          WHEN 'dats'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->dats ).
          WHEN 'df16_raw'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->df16_raw ).
          WHEN 'df34_raw'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->df34_raw ).
          WHEN 'fltp'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->fltp ).
          WHEN 'int1'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->int1 ).
          WHEN 'int2'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->int2 ).
          WHEN 'int4'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->int4 ).
          WHEN 'int8'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->int8 ).
          WHEN 'lang'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->lang ).
          WHEN 'tims'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->tims ).
          WHEN 'char'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->char( table_field_line-built_in_type_length  ) ).
          WHEN 'curr'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->curr(
                                              iv_length   = table_field_line-built_in_type_length
                                              iv_decimals = table_field_line-built_in_type_decimals
                                            ) ).
          WHEN 'dec'  .
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->dec(
                                              iv_length   = table_field_line-built_in_type_length
                                              iv_decimals = table_field_line-built_in_type_decimals
                                            ) ).
          WHEN 'df16_dec'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->df16_dec(
                                              iv_length   = table_field_line-built_in_type_length
                                              iv_decimals = table_field_line-built_in_type_decimals
                                            ) ).
          WHEN 'df34_dec'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->df34_dec(
                                              iv_length   = table_field_line-built_in_type_length
                                              iv_decimals = table_field_line-built_in_type_decimals
                                            ) ).
          WHEN 'lchr' .
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->lchr( table_field_line-built_in_type_length  ) ).
          WHEN 'lraw'  .
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->lraw( table_field_line-built_in_type_length  ) ).
          WHEN 'numc'   .
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->numc( table_field_line-built_in_type_length  ) ).
          WHEN 'quan' .
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->quan(
                                              iv_length   = table_field_line-built_in_type_length
                                              iv_decimals = table_field_line-built_in_type_decimals
                                              ) ).
          WHEN 'raw'  .
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->raw( table_field_line-built_in_type_length  ) ).
          WHEN 'rawstring'.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->rawstring( table_field_line-built_in_type_length  ) ).
          WHEN 'sstring' .
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->sstring( table_field_line-built_in_type_length  ) ).
          WHEN 'string' .
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->string( table_field_line-built_in_type_length  ) ).
          WHEN 'unit'  .
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->unit( table_field_line-built_in_type_length  ) ).
          WHEN OTHERS.
            database_table_field->set_type( xco_cp_abap_dictionary=>built_in_type->for(
                                              iv_type     = to_upper( table_field_line-built_in_type )
                                              iv_length   = table_field_line-built_in_type_length
                                              iv_decimals = table_field_line-built_in_type_decimals
                                            ) ).
        ENDCASE.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_child_table_fields.
    child_table_fields = VALUE tt_fields(
                   ( field         = 'client'
                     data_element  = 'mandt'
                     is_key        = 'X'
                     not_null      = 'X' )
                   ( field         = 'travel_id'
                     data_element  = '/dmo/travel_id'
                     is_key        = 'X'
                     not_null      = 'X' )
                   ( field         = 'booking_id'
                     data_element  = '/dmo/booking_id'
                     is_key        = 'X'
                     not_null      = 'X' )
                   ( field         = 'booking_date'
                     data_element  = '/dmo/booking_date' )
                   ( field         = 'customer_id'
                     data_element  = '/dmo/customer_id' )
                   ( field         = 'carrier_id'
                     data_element  = '/dmo/carrier_id' )
                   ( field         = 'connection_id'
                     data_element  = '/dmo/connection_id' )
                   ( field         = 'flight_date'
                     data_element  = '/dmo/flight_date' )
                   ( field         = 'flight_price'
                     data_element  = '/dmo/flight_price'
                     currencycode  = 'currency_code'  )
                   ( field         = 'currency_code'
                     data_element  = '/dmo/currency_code' )
                   ( field         = 'booking_status'
                     data_element  = '/dmo/booking_status' )
                   ( field         = 'last_changed_at '
                     data_element  = 'timestampl' )
                   ).
  ENDMETHOD.


  METHOD get_json_string.
    "build the json document for RAP400 workshop
    json_string ='{' && |\r\n|  &&
                 '  "implementationType": "managed_semantic",' && |\r\n|  &&
                 '  "transactionalbehavior" : true,' && |\r\n|  &&
                 '  "publishservice" : true ,' && |\r\n|  &&
                 '  "namespace": "ZRAP400_",' && |\r\n|  &&
                 |  "transportrequest": "{ transport_request }",| && |\r\n|  &&
                 |  "suffix": "_{ unique_group_id }",| && |\r\n|  &&
*                 '  "prefix": "",' && |\r\n|  &&
                 |  "package": "{ package_name }",| && |\r\n|  &&
                 '  "datasourcetype": "table",' && |\r\n|  &&
                 '  "bindingtype": "odata_v2_ui",' && |\r\n|  &&
                 '  "hierarchy": {' && |\r\n|  &&
                 '    "entityName": "Travel",' && |\r\n|  &&
                 |    "dataSource": "{ table_name_root }",| && |\r\n|  &&
                 '    "objectId": "travel_id",' && |\r\n|  &&
                 '    "etagMaster": "last_changed_at" ,   ' && |\r\n|  &&
*                 "field mapping
                 '"mapping": [' && |\r\n|  &&
                 '      {' && |\r\n|  &&
                 '        "dbtable_field": "travel_id",' && |\r\n|  &&
                 '        "cds_view_field": "TravelID"' && |\r\n|  &&
                 '      }' && |\r\n|  &&
                 '    ],' && |\r\n|  &&

*                 "value help definitions
                 '    "valueHelps": [' && |\r\n|  &&
                 '      {' && |\r\n|  &&
                 '        "alias": "Agency",' && |\r\n|  &&
                 '        "name": "/DMO/I_Agency",' && |\r\n|  &&
                 '        "localElement": "AgencyID",' && |\r\n|  &&
                 '        "element": "AgencyID"' && |\r\n|  &&
                 '      },' && |\r\n|  &&
                 '      {' && |\r\n|  &&
                 '        "alias": "Customer",' && |\r\n|  &&
                 '        "name": "/DMO/I_Customer",' && |\r\n|  &&
                 '        "localElement": "CustomerID",' && |\r\n|  &&
                 '        "element": "CustomerID"' && |\r\n|  &&
                 '      },' && |\r\n|  &&
                 '      {' && |\r\n|  &&
                 '        "alias": "Currency",' && |\r\n|  &&
                 '        "name": "I_Currency",' && |\r\n|  &&
                 '        "localElement": "CurrencyCode",' && |\r\n|  &&
                 '        "element": "Currency"' && |\r\n|  &&
                 '      }' && |\r\n|  &&
                 '    ],' && |\r\n|  &&
                 '    "associations": [' && |\r\n|  &&
                 '      {' && |\r\n|  &&
                 '        "name": "_Agency",' && |\r\n|  &&
                 '        "target": "/DMO/I_Agency",' && |\r\n|  &&
                 '        "cardinality": "zero_to_one",' && |\r\n|  &&
                 '        "conditions": [' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "projectionField": "AgencyID",' && |\r\n|  &&
                 '            "associationField": "AgencyID"' && |\r\n|  &&
                 '          }' && |\r\n|  &&
                 '        ]' && |\r\n|  &&
                 '      },' && |\r\n|  &&
                 '      {' && |\r\n|  &&
                 '        "name": "_Currency",' && |\r\n|  &&
                 '        "target": "I_Currency",' && |\r\n|  &&
                 '        "cardinality": "zero_to_one",' && |\r\n|  &&
                 '        "conditions": [' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "projectionField": "CurrencyCode",' && |\r\n|  &&
                 '            "associationField": "Currency"' && |\r\n|  &&
                 '          }' && |\r\n|  &&
                 '        ]' && |\r\n|  &&
                 '      },' && |\r\n|  &&
                 '      {' && |\r\n|  &&
                 '        "name": "_Customer",' && |\r\n|  &&
                 '        "target": "/DMO/I_Customer",' && |\r\n|  &&
                 '        "cardinality": "zero_to_one",' && |\r\n|  &&
                 '        "conditions": [' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "projectionField": "CustomerID",' && |\r\n|  &&
                 '            "associationField": "CustomerID"' && |\r\n|  &&
                 '          }' && |\r\n|  &&
                 '        ]' && |\r\n|  &&
                 '      }' && |\r\n|  &&
                 '    ],' && |\r\n|  &&

*                 "children
                 '    "children": [' && |\r\n|  &&
                 '      {' && |\r\n|  &&
                 '        "entityName": "Booking",' && |\r\n|  &&
                 |        "dataSource": "{ table_name_child }",| && |\r\n|  &&
                 '        "objectId": "booking_id",' && |\r\n|  &&
                 '    "etagMaster": "last_changed_at"   , ' && |\r\n|  &&
*                 "field mapping
                 '"mapping": [' && |\r\n|  &&
                 '      {' && |\r\n|  &&
                 '        "dbtable_field": "travel_id",' && |\r\n|  &&
                 '        "cds_view_field": "TravelID"' && |\r\n|  &&
                 '      },' && |\r\n|  &&
                 '      {' && |\r\n|  &&
                 '        "dbtable_field": "booking_id",' && |\r\n|  &&
                 '        "cds_view_field": "BookingID"' && |\r\n|  &&
                 '      }' && |\r\n|  &&
                 '    ],' && |\r\n|  &&

*                 "Value Help definitions
                 '        "valueHelps": [' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "alias": "Flight",' && |\r\n|  &&
                 '            "name": "/DMO/I_Flight",' && |\r\n|  &&
                 '            "localElement": "ConnectionID",' && |\r\n|  &&
                 '            "element": "ConnectionID",' && |\r\n|  &&
                 '            "additionalBinding": [' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "localElement": "FlightDate",' && |\r\n|  &&
                 '                "element": "FlightDate"' && |\r\n|  &&
                 '              },' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "localElement": "CarrierID",' && |\r\n|  &&
                 '                "element": "AirlineID"' && |\r\n|  &&
                 '              },' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "localElement": "FlightPrice",' && |\r\n|  &&
                 '                "element": "Price"' && |\r\n|  &&
                 '              },' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "localElement": "CurrencyCode",' && |\r\n|  &&
                 '                "element": "CurrencyCode"' && |\r\n|  &&
                 '              }' && |\r\n|  &&
                 '            ]' && |\r\n|  &&
                 '          },' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "alias": "Currency",' && |\r\n|  &&
                 '            "name": "I_Currency",' && |\r\n|  &&
                 '            "localElement": "CurrencyCode",' && |\r\n|  &&
                 '            "element": "Currency"' && |\r\n|  &&
                 '          },' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "alias": "Airline",' && |\r\n|  &&
                 '            "name": "/DMO/I_Carrier",' && |\r\n|  &&
                 '            "localElement": "CarrierID",' && |\r\n|  &&
                 '            "element": "AirlineID"' && |\r\n|  &&
                 '          },' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "alias": "Customer",' && |\r\n|  &&
                 '            "name": "/DMO/I_Customer",' && |\r\n|  &&
                 '            "localElement": "CustomerID",' && |\r\n|  &&
                 '            "element": "CustomerID"' && |\r\n|  &&
                 '          }' && |\r\n|  &&
                 '        ],' && |\r\n|  &&
                 '        "associations": [' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "name": "_Connection",' && |\r\n|  &&
                 '            "target": "/DMO/I_Connection",' && |\r\n|  &&
                 '            "cardinality": "one_to_one",' && |\r\n|  &&
                 '            "conditions": [' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "projectionField": "CarrierID",' && |\r\n|  &&
                 '                "associationField": "AirlineID"' && |\r\n|  &&
                 '              },' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "projectionField": "ConnectionID",' && |\r\n|  &&
                 '                "associationField": "ConnectionID"' && |\r\n|  &&
                 '              }' && |\r\n|  &&
                 '            ]' && |\r\n|  &&
                 '          },' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "name": "_Flight",' && |\r\n|  &&
                 '            "target": "/DMO/I_Flight",' && |\r\n|  &&
                 '            "cardinality": "one_to_one",' && |\r\n|  &&
                 '            "conditions": [' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "projectionField": "CarrierID",' && |\r\n|  &&
                 '                "associationField": "AirlineID"' && |\r\n|  &&
                 '              },' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "projectionField": "ConnectionID",' && |\r\n|  &&
                 '                "associationField": "ConnectionID"' && |\r\n|  &&
                 '              },' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "projectionField": "FlightDate",' && |\r\n|  &&
                 '                "associationField": "FlightDate"' && |\r\n|  &&
                 '              }' && |\r\n|  &&
                 '            ]' && |\r\n|  &&
                 '          },' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "name": "_Carrier",' && |\r\n|  &&
                 '            "target": "/DMO/I_Carrier",' && |\r\n|  &&
                 '            "cardinality": "one_to_one",' && |\r\n|  &&
                 '            "conditions": [' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "projectionField": "CarrierID",' && |\r\n|  &&
                 '                "associationField": "AirlineID"' && |\r\n|  &&
                 '              }' && |\r\n|  &&
                 '            ]' && |\r\n|  &&
                 '          },' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "name": "_Currency",' && |\r\n|  &&
                 '            "target": "I_Currency",' && |\r\n|  &&
                 '            "cardinality": "zero_to_one",' && |\r\n|  &&
                 '            "conditions": [' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "projectionField": "CurrencyCode",' && |\r\n|  &&
                 '                "associationField": "Currency"' && |\r\n|  &&
                 '              }' && |\r\n|  &&
                 '            ]' && |\r\n|  &&
                 '          },' && |\r\n|  &&
                 '          {' && |\r\n|  &&
                 '            "name": "_Customer",' && |\r\n|  &&
                 '            "target": "/DMO/I_Customer",' && |\r\n|  &&
                 '            "cardinality": "one_to_one",' && |\r\n|  &&
                 '            "conditions": [' && |\r\n|  &&
                 '              {' && |\r\n|  &&
                 '                "projectionField": "CustomerID",' && |\r\n|  &&
                 '                "associationField": "CustomerID"' && |\r\n|  &&
                 '              }' && |\r\n|  &&
                 '            ]' && |\r\n|  &&
                 '          }' && |\r\n|  &&
                 '        ]' && |\r\n|  &&
                 '      }' && |\r\n|  &&
                 '    ]' && |\r\n|  &&
                 '  }' && |\r\n|  &&
                 '}'.
  ENDMETHOD.


  METHOD get_root_table_fields.
    root_table_fields = VALUE tt_fields(
                  ( field         = 'client'
                    data_element  = 'mandt'
                    is_key        = 'X'
                    not_null      = 'X' )
                  ( field         = 'travel_id'
                    data_element  = '/dmo/travel_id'
                    is_key        = 'X'
                    not_null      = 'X' )
                  ( field         = 'agency_id'
                    data_element  = '/dmo/agency_id' )
                  ( field         = 'customer_id'
                    data_element  = '/dmo/customer_id' )
                  ( field         = 'begin_date'
                    data_element  = '/dmo/begin_date' )
                  ( field         = 'end_date'
                    data_element  = '/dmo/end_date' )
                  ( field         = 'booking_fee'
                    data_element  = '/dmo/booking_fee'
                    currencycode  = 'currency_code' )
                  ( field         = 'total_price'
                    data_element  = '/dmo/total_price'
                    currencycode  = 'currency_code' )
                  ( field         = 'currency_code'
                    data_element  = '/dmo/currency_code' )
                  ( field         = 'description'
                    data_element  = '/dmo/description' )
                  ( field         = 'overall_status'
                    data_element  = '/dmo/overall_status' )
                  ( field         = 'created_by'
                    data_element  = 'syuname' )
                  ( field         = 'created_at'
                    data_element  = 'timestampl' )
                  ( field         = 'last_changed_by'
                    data_element  = 'syuname' )
                  ( field         = 'last_changed_at'
                    data_element  = 'timestampl' )
                    ).
  ENDMETHOD.


  METHOD get_unique_suffix.
    DATA: li_counter(4)            TYPE n,
          ls_package_name          TYPE sxco_package,
          is_valid_package         TYPE abap_bool,
          is_valid_bo              TYPE abap_bool,
          lv_object_already_exists TYPE abap_bool,
          ls_bo_name               TYPE sxco_cds_object_name.

    DATA(xco_lib)    = NEW /dmo/cl_rap_xco_cloud_lib( ).
    is_valid_package = abap_false.
    is_valid_bo      = abap_false.
    li_counter       = 0.
    ls_package_name  = |{ s_prefix }TRAVEL_{ li_counter }|.

    WHILE is_valid_package = abap_false OR is_valid_bo = abap_false.
      "check package name
      DATA(lo_package)   = xco_cp_abap_repository=>object->devc->for( ls_package_name ).
      IF NOT lo_package->exists( ).
        is_valid_package = abap_true.
        s_unique_suffix  = li_counter.
      ELSE.
        li_counter       = li_counter + 1.
      ENDIF.

      ls_bo_name        = |{ s_prefix }I_TRAVEL_{ li_counter }|.
      IF NOT xco_lib->get_data_definition( ls_bo_name  )->exists( ).
        is_valid_bo     = abap_true.
        s_unique_suffix = li_counter.
      ELSE.
        li_counter      = li_counter + 1.
      ENDIF.

      ls_package_name = |{ s_prefix }TRAVEL_{ li_counter }|.
      ls_bo_name      = |{ s_prefix }I_TRAVEL_{ li_counter }|.
    ENDWHILE.
  ENDMETHOD.


  METHOD main.
    package_name    = to_upper( package_name ).
    unique_group_id = to_upper( unique_group_id ).

    out->write( | **************************************************************************************************** | ).
    out->write( | **                    Generation for the RAP400 Workshop ({ cl_abap_context_info=>get_system_date(  ) } { cl_abap_context_info=>get_system_time(  ) } UTC)                    ** | ).
    out->write( | **************************************************************************************************** | ).
*    out->write( | Generation started... ({ cl_abap_context_info=>get_system_date(  ) } { cl_abap_context_info=>get_system_time(  ) } UTC)... | ).
    out->write( | - Group ID (suffix): { unique_group_id } | ).
    out->write( | - Package: { package_name } (superpackage: ZLOCAL)| ).

    "create transport
    transport_request      = create_transport(  ).
    dev_system_environment = xco_cp_generation=>environment->dev_system( transport_request ).
    out->write( | - Transport Request: { transport_request } | ).

    "create package
    create_package( transport_request ).

    "get json document
    DATA(json_string)              = get_json_string(  ).

    DATA(root_table_fields)        = get_root_table_fields(  ).
    DATA(lo_objects_put_operation) = dev_system_environment->create_put_operation( ).
    DATA(lo_table_root) = xco_cp_abap_repository=>object->tabl->for( CONV #( table_name_root ) ).
    DATA(lo_table_child) = xco_cp_abap_repository=>object->tabl->for( CONV #( table_name_child ) ).

    IF lo_table_root->exists(  ) = abap_false.
      "generate of travel table
      generate_table(
        EXPORTING
          io_put_operation        = lo_objects_put_operation
          table_fields            = root_table_fields
          table_name              = table_name_root
          table_short_description = 'Travel Table'
      ).
    ELSE.
      out->write( | - Table { table_name_root } already exists.| ).
    ENDIF.

    IF lo_table_child->exists(  ) = abap_false.
      IF table_name_child IS NOT INITIAL.
        "generate of booking table
        generate_table(
          EXPORTING
            io_put_operation        = lo_objects_put_operation
            table_fields            = get_child_table_fields(  )
            table_name              = table_name_child
            table_short_description = 'Booking Table'
        ).
      ENDIF.
    ELSE.
      out->write( | - Table { table_name_child } already exists.| ).
    ENDIF.

    DATA(lo_result) = lo_objects_put_operation->execute( ).
    "handle findings
    DATA(lo_findings) = lo_result->findings.
    DATA(lt_findings) = lo_findings->get( ).
    IF lt_findings IS NOT INITIAL.
      out->write( lt_findings ).
    ENDIF.

    "create data generator class
    lo_objects_put_operation = dev_system_environment->create_put_operation( ).
    generate_data_generator_class(
      EXPORTING
        io_put_operation       = lo_objects_put_operation
        lo_transport            = transport_request
    ).
    lo_result = lo_objects_put_operation->execute( ).
    "handle findings
    lo_findings = lo_result->findings.
    lt_findings = lo_findings->get( ).
    IF lt_findings IS NOT INITIAL.
      out->write( lt_findings ).
    ENDIF.
    "release generated class
    release_data_generator_class(
        EXPORTING
            lo_transport            = transport_request
    ).
    "execute generated class to fill tables with demo data
    DATA lo_object TYPE REF TO if_oo_adt_classrun.
    CREATE OBJECT lo_object TYPE (data_generator_class_name).
    lo_object->main(
        EXPORTING out = out->plain
    ).
*   "out->write( | - Tables generated and filled with demo data: { table_name_root } and { table_name_child } . | ).

    "generate RAP BO artifacts according to the json document
    DATA(rap_generator) = /dmo/cl_rap_generator=>create_for_cloud_development( json_string ).
    rap_generator->root_node->set_behavior_impl_name( |{ co_prefix }bp_i_travel_{ unique_group_id }| ).
    DATA(child_node) = rap_generator->root_node->childnodes[ 1 ].
    child_node->set_behavior_impl_name( |{ co_prefix }bp_i_booking_{ unique_group_id }| ).

    DATA(todos) = rap_generator->generate_bo(  ).
    DATA(rap_bo_name) = rap_generator->root_node->rap_root_node_objects-service_binding.
**   "write ToDos to the console
*    out->write( |General information & Todo's:| ).
*    LOOP AT todos INTO DATA(todo).
*      out->write( todo ).
*    ENDLOOP.

    "delete and create adjusted metadata extensions (MDEs)
    DATA(cts_obj) =
        xco_cp_abap_repository=>object->for(
                                    EXPORTING
                                    iv_type = 'DDLX'
                                    iv_name = to_upper( rap_generator->root_node->rap_node_objects-meta_data_extension )
                                    )->if_xco_cts_changeable~get_object( ).
    DATA(lv_del_transport) = cts_obj->get_lock( )->get_transport( ).
    lv_del_transport = xco_cp_cts=>transport->for( lv_del_transport )->get_request( )->value.
    DATA(mo_environment) = xco_cp_generation=>environment->dev_system( lv_del_transport ).
    DATA(lo_delete_operation) = mo_environment->for-ddlx->create_delete_operation( ).
    lo_delete_operation->add_object( rap_generator->root_node->rap_node_objects-meta_data_extension ).
    "execute
    lo_delete_operation->execute( ).
    generate_cds_mde( rap_generator->root_node ).

    "successful UI service generation
*    out->write( |   | ).
    out->write( | Your OData V2 based UI service has been successfully created! | ).
    out->write( | The following package got created for you and includes everything you need: { package_name } | ).
    out->write( | Now perform the following steps: | ).
    out->write( | 1) In the "Project Explorer" right-click on "Favorite Packages" and click on "Add Package...".| ).
    out->write( |    Then enter "{ package_name }" and click OK.| ).
    out->write( | 2) Publish the local service endpoint of the generated service binding "ZRAP400_UI_TRAVEL_{ unique_group_id }_O2".| ).
*    out->write( |   | ).
    out->write( | You can now go ahead with the RAP400 exercises! | ).
    out->write( | **************************************************************************************************** | ).
  ENDMETHOD.


  METHOD release_data_generator_class.
    DATA(lo_change_scenario) = xco_cp_cts=>transport->for( lo_transport ).
    DATA(lo_api_state) = xco_cp_ars=>api_state->released( VALUE #( ( xco_cp_ars=>visibility->sap_cloud_platform ) ) ).

    DATA(lo_data_element) = xco_cp_abap_repository=>object->clas->for( data_generator_class_name ).
    lo_data_element->set_api_state(
      io_change_scenario = lo_change_scenario
      io_api_state       = lo_api_state
    ).
  ENDMETHOD.
ENDCLASS.
