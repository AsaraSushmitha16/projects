--------------------------------------------------------
--  File created - Wednesday-February-28-2024   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package PKG_DATA_CONNECTOR_REVERSE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "VMESDEV"."PKG_DATA_CONNECTOR_REVERSE" AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */

    PROCEDURE PRC_GET_CLOSURE_DETAIL_ID (
        p_fid       IN NUMBER,
        p_fno       IN NUMBER,
        p_detail_id OUT NUMBER,
        p_CLOSURE_FID OUT NUMBER
    );
    FUNCTION FUN_GET_CENTROID_DETAIL
    (P_GEOMETRY IN SDO_GEOMETRY,
    P_FNO  in number,
     P_TB_NAME  in varchar2) 
     RETURN SDO_GEOMETRY ;
    FUNCTION fun_get_gcoms_fid (
        p_iqgeo_fid IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION fun_get_fno (
        p_iqgeo_fid IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION fun_get_detail_usr (
        p_fno IN NUMBER,
        p_fid IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION fun_get_polygon (
        p_geometry IN sdo_geometry,
        p_fno      IN NUMBER
    ) RETURN sdo_geometry;

    FUNCTION fun_get_point_ofset (
        p_geometry IN sdo_geometry,
        p_fno      IN NUMBER
    ) RETURN sdo_geometry;

    FUNCTION fun_get_wkb_reverse (
        p_wkb IN VARCHAR2
    ) RETURN sdo_geometry;

    FUNCTION fun_get_wkb_reverse_polygonto3d (
        p_wkb IN VARCHAR2,
        p_fno IN NUMBER
    ) RETURN sdo_geometry;

    FUNCTION fun_get_wkb_reverse_pointto3d (
        p_wkb IN VARCHAR2,
        p_fno IN NUMBER
    ) RETURN sdo_geometry;

    FUNCTION fun_get_offset_coordinates (
        p_wkb    IN VARCHAR2,
        p_offset IN VARCHAR2,
        p_fno    IN NUMBER
    ) RETURN NUMBER;

    FUNCTION fun_get_wkb_reverse (
        p_orientation IN VARCHAR2,
        p_wkb         IN VARCHAR2,
        P_REGION      IN VARCHAR2
    ) RETURN sdo_geometry;

    FUNCTION fun_get_wkb_reverse_11800 (
        p_wkb IN VARCHAR2
    ) RETURN sdo_geometry;

    PROCEDURE prc_post_job (
        p_fno      IN NUMBER,
        p_ltt_id   OUT NUMBER,
        p_ltt_name OUT NUMBER -- JOB_ID
    );

    PROCEDURE prc_reverse_data_connecter (
        p_fno    IN NUMBER,
        p_dml    IN VARCHAR2,
        p_status OUT VARCHAR2
    );

    PROCEDURE prc_reverse_main (
        p_dml    IN VARCHAR2,
        p_status OUT VARCHAR2
    );

END pkg_data_connector_reverse;

/
