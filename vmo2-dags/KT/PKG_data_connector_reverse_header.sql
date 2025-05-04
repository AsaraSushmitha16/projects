--------------------------------------------------------
--  File created - Monday-February-12-2024   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package PKG_DATA_CONNECTOR_REVERSE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "VMESDEV"."PKG_DATA_CONNECTOR_REVERSE" AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 

    FUNCTION FUN_GET_GCOMS_FID 
(
  P_IQGEO_FID IN VARCHAR2 
) RETURN NUMBER;
    FUNCTION FUN_GET_DETAIL_USR
        (P_FNO IN NUMBER,
         P_FID IN NUMBER )
    RETURN VARCHAR2;
FUNCTION FUN_GET_POLYGON
    (P_GEOMETRY IN SDO_GEOMETRY, P_FNO IN NUMBER) 
        RETURN SDO_GEOMETRY;
    FUNCTION FUN_GET_POINT_OFSET
    (P_GEOMETRY IN SDO_GEOMETRY, P_FNO IN NUMBER) 
        RETURN SDO_GEOMETRY;
     FUNCTION fun_get_wkb_reverse
    ( p_wkb IN VARCHAR2 )
    RETURN SDO_GEOMETRY;
    FUNCTION fun_get_wkb_reverse_polygonTo3D
    ( p_wkb IN VARCHAR2,
    p_fno in number)
     RETURN SDO_GEOMETRY;
     FUNCTION fun_get_wkb_reverse_PointTo3D
     (p_wkb IN VARCHAR2, P_FNO IN NUMBER)
     RETURN SDO_GEOMETRY;
     FUNCTION fun_get_offset_coordinates
     (p_wkb IN VARCHAR2,
        p_offset IN VARCHAR2,
        p_fno IN NUMBER)
    RETURN NUMBER;
    
    FUNCTION fun_get_wkb_reverse
     (P_ORIENTATION IN VARCHAR2,P_WKB in varchar2)
    RETURN sdo_geometry;
    FUNCTION fun_get_wkb_reverse_11800
    ( p_wkb IN VARCHAR2 )
    RETURN SDO_GEOMETRY;


    PROCEDURE PRC_POST_JOB
        (   P_FNO  IN NUMBER,       
            P_LTT_ID   OUT NUMBER,
            P_LTT_NAME OUT NUMBER -- JOB_ID
         );
    PROCEDURE PRC_REVERSE_DATA_CONNECTER
    ( p_fno          IN NUMBER,   
      p_dml          IN VARCHAR2,
      P_STATUS          OUT VARCHAR2
    );
    PROCEDURE PRC_REVERSE_MAIN (P_DML  IN VARCHAR2,
                                    P_STATUS OUT VARCHAR2);
END PKG_DATA_CONNECTOR_REVERSE;

/
