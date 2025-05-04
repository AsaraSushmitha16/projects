--------------------------------------------------------
--  File created - Wednesday-February-28-2024   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body PKG_DATA_CONNECTOR_REVERSE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "VMESDEV"."PKG_DATA_CONNECTOR_REVERSE" 
/***************************************************************************************************************************************************
** Name        : PKG_DATA_CONNECTOR_REVERSE
** Description : Generate scripts based on the DATA_MAPPING table for provided feature number
** Created by  : Thushar C Chandran
** Created Date: 01-Dec-2024
****************************************************************************************************************************************************
** Change History
****************************************************************************************************************************************************
** Version                                           Date      Developer             Ticket#: Comment  
----------------------------------------------------------------------------------------------------------------------------------------------------------


****************************************************************************************************************************************************/
AS
    PROCEDURE PRC_GET_CLOSURE_DETAIL_ID 
    (
      P_FID IN NUMBER 
    , P_FNO IN NUMBER ,
    P_detail_id out number,
    p_CLOSURE_FID OUT NUMBER
    ) AS 
    V_FID NUMBER := 0;
    V_14900_FID NUMBER := 0;
    v_err   varchar2(1000);
     v_detailid number;
    E_NOT_EXIST  EXCEPTION;
    
    BEGIN
      IF P_FNO = 7200 then
        BEGIN
            SELECT IN_FID
            INTO V_FID
            from b$gc_nr_connect nc
            WHERE nc.g3e_fno = P_FNO 
            and nc.g3e_fid = P_FID
            AND IN_FNO in( 15700,11800)
            and rownum = 1  ;
        EXCEPTION
            WHEN OTHERS THEN
            V_FID := 0;
        END;
        IF V_FID = 0 THEN
            BEGIN
            SELECT OUT_FID
            INTO V_FID
            from b$gc_nr_connect nc
            WHERE nc.g3e_fno = P_FNO 
            and nc.g3e_fid = P_FID
            AND OUT_FNO  in( 15700,11800)
            and rownum =1;
        EXCEPTION
            WHEN OTHERS THEN
            v_err := 'Associated fiber shelf for cabel not found';
            raise E_NOT_EXIST;
        END;
        
        END IF;
        begin
            select a.g3e_fid 
            into V_14900_FID
            from b$gc_ownership a
            join b$gc_ownership b on ( a.g3e_id = b.owner1_id)
            where b.g3e_fid = v_fid
            and a.g3e_fno = 14900;
            
            select G3E_DETAILID
            into v_detailid
            from b$gc_detail
            where g3e_fid = V_14900_FID;
        
        EXCEPTION
            WHEN OTHERS THEN
            v_err := 'Associated closure not found';
            raise E_NOT_EXIST;
        END;
        --DBMS_OUTPUT.PUT_LINE(v_detailid);
      end if;
      if p_fno in( 11800,15700) then
        begin
            select a.g3e_fid 
            into V_14900_FID
            from b$gc_ownership a
            join b$gc_ownership b on ( a.g3e_id = b.owner1_id)
            where b.g3e_fid = P_FID
            and a.g3e_fno = 14900;
            
            select G3E_DETAILID
            into v_detailid
            from b$gc_detail
            where g3e_fid = V_14900_FID;
          
        EXCEPTION
            WHEN OTHERS THEN
            v_err := 'Associated closure not found';
            raise E_NOT_EXIST;
        END;
      end if;
      P_detail_id := v_detailid;
      p_CLOSURE_FID := V_14900_FID;
    EXCEPTION
        WHEN E_NOT_EXIST THEN
        P_detail_id := 0;
    END PRC_GET_CLOSURE_DETAIL_ID;
    FUNCTION FUN_GET_GCOMS_FID 
    (
        P_IQGEO_FID IN VARCHAR2 
    ) RETURN NUMBER AS
        V_GECOMS_FID NUMBER;
        V_ID NUMBER;
    BEGIN
        V_ID := SUBSTR (P_IQGEO_FID,INSTR(P_IQGEO_FID,'/')+1);
        if SIGN (V_ID) = -1 THEN
            SELECT gcomms_fid 
            INTO V_GECOMS_FID
            FROM tb_fid_gcomms_iqgeo 
            WHERE iqgeo_fid = P_IQGEO_FID;
        ELSE
            V_GECOMS_FID := V_ID;
        END IF;
            RETURN V_GECOMS_FID;
    EXCEPTION
        WHEN OTHERS THEN
            V_GECOMS_FID:= -1;
            RETURN V_GECOMS_FID;
    END FUN_GET_GCOMS_FID;
    FUNCTION FUN_GET_FNO 
    (
        P_IQGEO_FID IN VARCHAR2 
    ) RETURN NUMBER AS
        V_F_NAME VARCHAR2(100);
        V_FNO NUMBER;
    BEGIN
        V_F_NAME := SUBSTR (P_IQGEO_FID,1,INSTR(P_IQGEO_FID,'/')-1);
       
            SELECT gcomms_fNO 
            INTO V_FNO
            FROM TB_FEATURE 
            WHERE UPPER(FEATURE_NAME) = UPPER(V_F_NAME);
       
            RETURN V_FNO;
    EXCEPTION
        WHEN OTHERS THEN
            V_FNO:= 0;
            RETURN V_FNO;
    END FUN_GET_FNO;

    FUNCTION FUN_GET_DETAIL_USR
        (P_FNO IN NUMBER,
         P_FID IN NUMBER )
    RETURN VARCHAR2
        AS
            V_USR VARCHAR2(200);
    BEGIN

        SELECT ID 
        INTO V_USR
        FROM B$GC_NETELEM 
        WHERE G3E_FNO = P_FNO 
        AND g3e_fid = P_FID 
        AND ROWNUM = 1;
        RETURN V_USR;
    EXCEPTION
    WHEN OTHERS THEN
        V_USR := NULL;
        RETURN V_USR;

    END FUN_GET_DETAIL_USR;

    FUNCTION FUN_GET_POINT_OFSET
    (P_GEOMETRY IN SDO_GEOMETRY , P_FNO IN NUMBER ) 
        RETURN SDO_GEOMETRY 
        AS
    V_GEOMETRY SDO_GEOMETRY;
    BEGIN
        FOR REC2 IN ( SELECT X.X ,X.Y,X.ID  FROM TABLE(SDO_UTIL.GETVERTICES (P_GEOMETRY)) X)
            LOOP
            if P_FNO =14900 THEN
                select SDO_GEOMETRY (3001, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1, 1, 1, 4, 1, 0), MDSYS.SDO_ORDINATE_ARRAY(rec2.x, rec2.Y+1.5, 0, 1, 0, 0))
                into v_geometry
                FROM DUAL;        
            ELSE
                select SDO_GEOMETRY (3001, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1, 1, 1, 4, 1, 0), MDSYS.SDO_ORDINATE_ARRAY(rec2.x+1.5, rec2.Y, 0, 1, 0, 0))
                into v_geometry
                FROM DUAL;
        
            END IF;
         END LOOP;
        RETURN V_GEOMETRY;
    END FUN_GET_POINT_OFSET;
     FUNCTION FUN_GET_CENTROID_DETAIL
    (P_GEOMETRY IN SDO_GEOMETRY,
    P_FNO  in number,
     P_TB_NAME  in varchar2) 
        RETURN SDO_GEOMETRY 
        AS
    V_GEOMETRY SDO_GEOMETRY;
    BEGIN
        FOR REC2 IN ( SELECT X.X ,X.Y,X.ID  FROM TABLE(SDO_UTIL.GETVERTICES (sdo_geom.sdo_centroid(P_GEOMETRY))) X)
            LOOP
              if  p_fno in (15700,11800) and P_TB_NAME in ('B$DGC_FSPLICE_S','B$DGC_FRACK_S') then
                v_geometry := SDO_GEOMETRY (3001, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1, 1, 1, 4, 1, 0), MDSYS.SDO_ORDINATE_ARRAY(rec2.x, rec2.Y, 0, 1, 0, 0));
                  
            elsif  p_fno in (15700,11800) and P_TB_NAME in ('B$DGC_FSPLICE_T','B$DGC_FRACK_T') then
                v_geometry := SDO_GEOMETRY (3001, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1, 1, 1, 4, 1, 0), MDSYS.SDO_ORDINATE_ARRAY(rec2.x-0.1, rec2.Y-0.4, 0, 1, 0, 0));
                 
            elsif  p_fno = 7200 and P_TB_NAME = 'B$DGC_FCBL_L' then
                v_geometry := SDO_GEOMETRY (3002, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1, 2, 1), MDSYS.SDO_ORDINATE_ARRAY(rec2.x, rec2.Y-2, 0, rec2.x, rec2.Y, 0));
            elsif  p_fno = 7201 and P_TB_NAME = 'B$DGC_FCBL_T' then
                v_geometry := SDO_GEOMETRY (3001, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1, 1, 1, 4, 1, 0), MDSYS.SDO_ORDINATE_ARRAY(rec2.x, rec2.Y-2.5, 0, 1, 0, 0));
            
            end if;
         END LOOP;
        RETURN V_GEOMETRY;
    END FUN_GET_CENTROID_DETAIL;
    FUNCTION FUN_GET_POLYGON
    (P_GEOMETRY IN SDO_GEOMETRY, P_FNO IN NUMBER) 
        RETURN SDO_GEOMETRY 
        AS
    V_GEOMETRY SDO_GEOMETRY;
    BEGIN
        FOR REC2 IN ( SELECT X.X ,X.Y,X.ID  FROM TABLE(SDO_UTIL.GETVERTICES (P_GEOMETRY)) X)
            LOOP
            
            IF P_FNO = 14900 THEN
            
            SELECT SDO_GEOMETRY(3003, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1, 1003,1), MDSYS.SDO_ORDINATE_ARRAY(REC2.X - 2,REC2.Y - 1,0,REC2.X + 2,REC2.Y - 1,0,REC2.X + 2,REC2.Y + 1,0,REC2.X - 2,REC2.Y + 1.,0,REC2.X - 2,REC2.Y - 1,0))
            INTO V_GEOMETRY
            FROM DUAL;
            ELSE
           SELECT SDO_GEOMETRY(3003, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1, 1005, 2, 1, 2, 2, 7, 2, 2), MDSYS.SDO_ORDINATE_ARRAY(REC2.X + 1, REC2.Y, 0,REC2.X, REC2.Y + 1, 0,REC2.X - 1, REC2.Y, 0,REC2.X, REC2.Y - 1, 0,REC2.X + 1, REC2.Y, 0)) 
            INTO V_GEOMETRY
            FROM DUAL;
            END IF;
            
        END LOOP;
        RETURN V_GEOMETRY;
    END FUN_GET_POLYGON;
    
    
    FUNCTION fun_get_wkb_reverse
    ( p_wkb IN VARCHAR2 )
    RETURN SDO_GEOMETRY AS 
        v_sring CLOB;
        v_loop  NUMBER:=0;
        v_geometry SDO_GEOMETRY;
        v_out_geometry SDO_GEOMETRY;
    BEGIN
        if p_wkb is not null then
        v_geometry := SDO_GEOMETRY(to_blob(p_wkb));
        SELECT sdo_cs.transform(SDO_GEOMETRY(2001, 8307, sdo_point_type(R.X,R.y, NULL), NULL, NULL), 27700)
        INTO v_geometry
        FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;

        SELECT SDO_GEOMETRY(3001, NULL, NULL, mdsys.sdo_elem_info_array(1, 1, 1, 4, 1, 0), mdsys.sdo_ordinate_array(R.X,R.y, 0, 1, 0, 0))
        INTO v_geometry
        FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;
        else
            v_geometry := null;
        end if;
        RETURN v_geometry;
    
    END;
    FUNCTION fun_get_wkb_reverse_11800
    ( p_wkb IN VARCHAR2 )
    RETURN SDO_GEOMETRY AS 
        v_sring CLOB;
        v_loop  NUMBER:=0;
        v_geometry SDO_GEOMETRY;
        v_out_geometry SDO_GEOMETRY;
    BEGIN
        if p_wkb is not null then
        v_geometry := SDO_GEOMETRY(to_blob(p_wkb));
        SELECT sdo_cs.transform(SDO_GEOMETRY(2001, 8307, sdo_point_type(R.X,R.y, NULL), NULL, NULL), 27700)
        INTO v_geometry
        FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;

        SELECT SDO_GEOMETRY(3001,27700, NULL, mdsys.sdo_elem_info_array(1, 1, 1, 4, 1, 0), mdsys.sdo_ordinate_array(R.X,R.y, 0, 1, 0, 0))
        INTO v_geometry
        FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;
        else
            v_geometry := null;
        end if;
        RETURN v_geometry;
    
    END;
    FUNCTION fun_get_wkb_reverse_polygonTo3D
    ( p_wkb IN VARCHAR2,
    p_fno in number)
    RETURN SDO_GEOMETRY AS 
        v_sring CLOB;
        v_loop  NUMBER:=0;
        v_geometry SDO_GEOMETRY;
        v_out_geometry SDO_GEOMETRY;
        v_coords varchar2(30000);
        t sdo_ordinate_array := sdo_ordinate_array();
        s clob ;
        i number;
        j number;
    BEGIN
        v_geometry := SDO_GEOMETRY(to_blob(p_wkb));
        
       FOR REC1 in (SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)
LOOP       
        SELECT sdo_cs.transform(SDO_GEOMETRY(2001, 8307, sdo_point_type(REC1.X,REC1.y, NULL), NULL, NULL), 27700)
        INTO v_geometry
        FROM DUAL;       

FOR REC2 IN ( SELECT X.X ,X.Y,X.ID  FROM TABLE(SDO_UTIL.GETVERTICES (v_geometry)) X)        
            LOOP           
            
            v_coords := v_coords || REC2.X || ', ' || REC2.Y || ', 0,';         
        END LOOP;        
        END LOOP;
        s := v_coords;
       i := 1;
  loop
    j := instr(s, ',', i);
    --DBMS_OUTPUT.PUT_LINE('j:'||j);
    exit when j = 0;

    t.extend();
    t(t.count) := to_number(substr(s,i,j-i));
     --DBMS_OUTPUT.PUT_LINE('t:'||t(t.count));
    i := j+1;
  end loop;
       
       if p_fno in (5200,9100,2200,7200) then
        V_GEOMETRY := SDO_GEOMETRY(3002, NULL, NULL, SDO_ELEM_INFO_ARRAY(1, 2, 1),t);
       else
        V_GEOMETRY := SDO_CS.TRANSFORM(SDO_GEOMETRY(3003, 27700, NULL, SDO_ELEM_INFO_ARRAY(1, 1003, 1),t),27700);
       end if;
     
       /* SELECT sdo_cs.transform(SDO_GEOMETRY(3003, 27700, sdo_point_type(R.X,R.y, NULL), NULL, NULL), 8307)
        INTO v_geometry
        FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;

        SELECT SDO_GEOMETRY(3003, 27700, NULL, mdsys.sdo_elem_info_array(1, 1003, 1), mdsys.sdo_ordinate_array(R.X,R.y, 0, 1, 0, 0))
        INTO v_geometry
        FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;*/

        RETURN v_geometry;
    END;
    FUNCTION fun_get_wkb_reverse_PointTo3D
    ( p_wkb IN VARCHAR2 , P_FNO IN NUMBER)
    RETURN SDO_GEOMETRY AS 
        v_sring CLOB;
        v_loop  NUMBER:=0;
        v_geometry SDO_GEOMETRY;        
        v_coords varchar2(30000);
        t sdo_ordinate_array := sdo_ordinate_array();
        s clob ;
        i number;
        j number;
    BEGIN
        v_geometry := SDO_GEOMETRY(to_blob(p_wkb));
        
       FOR REC1 in (SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)
LOOP       
        SELECT sdo_cs.transform(SDO_GEOMETRY(2001, 8307, sdo_point_type(REC1.X,REC1.y, NULL), NULL, NULL), 27700)
        INTO v_geometry
        FROM DUAL;       

FOR REC2 IN ( SELECT X.X ,X.Y,X.ID  FROM TABLE(SDO_UTIL.GETVERTICES (v_geometry)) X)        
            LOOP           
            
            v_coords := v_coords || REC2.X || ', ' || REC2.Y || ', 0, 0, 0, 0, 0';         
        END LOOP;        
        END LOOP;
        s := v_coords;
       i := 1;
  loop
    j := instr(s, ',', i);
    --DBMS_OUTPUT.PUT_LINE('j:'||j);
    exit when j = 0;

    t.extend();
    t(t.count) := to_number(substr(s,i,j-i));
     --DBMS_OUTPUT.PUT_LINE('t:'||t(t.count));
    i := j+1;
  end loop;
  
  IF P_FNO = 14900 THEN
  
  V_GEOMETRY := SDO_CS.TRANSFORM(SDO_GEOMETRY(3001, 27700, NULL, SDO_ELEM_INFO_ARRAY(1,1003,1),t),27700);      
   
   ELSE
       
       V_GEOMETRY := SDO_CS.TRANSFORM(SDO_GEOMETRY(3001, 27700, NULL, SDO_ELEM_INFO_ARRAY(1, 1, 1,4,1,0),t),27700);      
  END IF;
        RETURN v_geometry;
    END;
   FUNCTION fun_get_offset_coordinates
   (p_wkb IN VARCHAR2,
        p_offset IN VARCHAR2,
        p_fno IN NUMBER)
    RETURN NUMBER AS
        V_Geometry sdo_geometry;
        V_OFFSET varchar2(7);
        V_DISTANCE number;
    BEGIN
        IF p_fno= 14100 THEN
            V_Geometry := PKG_DATA_CONNECTOR_REVERSE.fun_get_wkb_reverse_polygonTo3D(p_wkb,p_fno);
            ELSE
            V_Geometry := PKG_DATA_CONNECTOR_REVERSE.fun_get_wkb_reverse(p_wkb);
        END IF;
        IF V_Geometry IS NOT NULL AND p_offset IS NOT NULL THEN
            IF p_fno = 14100 THEN
                IF UPPER(p_offset)='X_LOW' THEN
                    V_DISTANCE := sdo_geom.sdo_min_mbr_ordinate(V_Geometry,1);
                ELSIF  UPPER(p_offset)='Y_LOW' THEN
                    V_DISTANCE := sdo_geom.sdo_min_mbr_ordinate(V_Geometry,2);
                ELSIF  UPPER(p_offset)='X_HIGH' THEN
                    V_DISTANCE := sdo_geom.sdo_max_mbr_ordinate(V_Geometry,1);
                ELSIF  UPPER(p_offset)='Y_HIGH' THEN
                    V_DISTANCE := sdo_geom.sdo_max_mbr_ordinate(V_Geometry,2);
                ELSE
                 V_DISTANCE := null;
                END IF;
                
                
       ELSE
            IF UPPER(p_offset)='X_LOW' THEN
                SELECT X_LOW INTO V_OFFSET FROM TB_APPLICATION_SETTINGS WHERE G3E_FNO=P_FNO;
                V_DISTANCE := sdo_util.getvertices (V_Geometry)(1).X - V_OFFSET;

            ELSIF UPPER(p_offset)='Y_LOW' THEN
                SELECT Y_LOW INTO V_OFFSET FROM TB_APPLICATION_SETTINGS WHERE G3E_FNO=P_FNO;
                V_DISTANCE := sdo_util.getvertices (V_Geometry)(1).Y - V_OFFSET;

            ELSIF UPPER(p_offset)='X_HIGH' THEN
                SELECT X_HIGH INTO V_OFFSET FROM TB_APPLICATION_SETTINGS WHERE G3E_FNO=P_FNO;
                V_DISTANCE := sdo_util.getvertices (V_Geometry)(1).X + V_OFFSET;

            ELSIF UPPER(p_offset)='Y_HIGH' THEN
                SELECT Y_HIGH INTO V_OFFSET FROM TB_APPLICATION_SETTINGS WHERE G3E_FNO=P_FNO;
                V_DISTANCE := sdo_util.getvertices (V_Geometry)(1).Y + V_OFFSET;            
            END IF;
        
        END IF;
         
        RETURN V_DISTANCE;
        END IF;
    /*EXCEPTION WHEN OTHERS THEN
        V_DISTANCE :=null;
        RETURN V_DISTANCE;*/
    END;
     /*************************************************************************************************
    ** fun_get_wkb_reverse : to create the point geometry with orientation
    13-02-204 - if orientation is coming to below -90 or it is coming as 90 or 270 we are handling that with another if condition
    ********************************************************************************************************/
    FUNCTION fun_get_wkb_reverse(P_ORIENTATION IN VARCHAR2,P_WKB in varchar2,P_REGION  IN VARCHAR2)
    RETURN sdo_geometry AS     
    v_radian number;    
    i number:=0;
    j number:=0;
    pi number := 3.14159265;
    flagCheck boolean;
    counter number;
    v_geometry sdo_geometry;
    v_orientation varchar2(100);
    BEGIN
    
    v_orientation := P_ORIENTATION+360;   
    select mod(v_orientation,360) into v_orientation from dual;
    
        if v_orientation = 90 or v_orientation=-90 or v_orientation = 270 or v_orientation = -270 then
            v_orientation := v_orientation -0.1;
        end if;
        select tan((v_orientation * pi)/180) into v_radian from dual;
        if v_orientation < -90 or (v_orientation >90 and v_orientation < 270) then
            j:=-1;
        else
            j:=1;
        end if;
        counter :=0;
        flagCheck := true;
        if v_orientation != 0 then
            while flagCheck loop
            if v_orientation < -90 or (v_orientation >90 and v_orientation < 270) then
                j := j+0.001;
            else
                j := j-0.001;
            end if;                
                i := j * v_radian;    
                if (i < 1 and i > -1) or counter > 1000 then    
                    flagcheck :=false;        
                end if;    
                counter := counter +1;
            end loop;
        else
            i:=0;
            j:=0;
        end if;       
    
	i:= substr(i,1,16);

 	if p_wkb is not null then
        v_geometry := SDO_GEOMETRY(to_blob(p_wkb));
        
            IF P_REGION = 'NI' THEN
            
                SELECT sdo_cs.transform(SDO_GEOMETRY(2001, 8307, sdo_point_type(R.X,R.y, NULL), NULL, NULL), 29902)
                INTO v_geometry
                FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;
                
                
        
                SELECT SDO_GEOMETRY(3001, 29902, NULL, mdsys.sdo_elem_info_array(1, 1, 1, 4, 1, 0), mdsys.sdo_ordinate_array(R.X,R.y, 0, j, i, 0))
                INTO v_geometry
                FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;
                
                SELECT SDO_CS.TRANSFORM(v_geometry,27700) into v_geometry from dual; 
        
            ELSE
            
                SELECT sdo_cs.transform(SDO_GEOMETRY(2001, 8307, sdo_point_type(R.X,R.y, NULL), NULL, NULL), 27700)
                INTO v_geometry
                FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;
        
                SELECT SDO_GEOMETRY(3001, NULL, NULL, mdsys.sdo_elem_info_array(1, 1, 1, 4, 1, 0), mdsys.sdo_ordinate_array(R.X,R.y, 0, j, i, 0))
                INTO v_geometry
                FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;
            END IF;
        
        
       
        else
           
            v_geometry := null;
        end if;

        RETURN  v_geometry;
        EXCEPTION 
            WHEN OTHERS THEN                    
        RETURN  null;
    END fun_get_wkb_reverse;
    
    /*************************************************************************************************
    ** PRC_POST_JOB : to create and post job before inserting the object details
    ********************************************************************************************************/
    PROCEDURE PRC_POST_JOB
        ( P_FNO  IN NUMBER,         
         P_LTT_ID   OUT NUMBER,
         P_LTT_NAME OUT NUMBER -- JOB_ID
         )
    AS
        V_JOB_ID    NUMBER;
    BEGIN
        V_JOB_ID :=  G3E_JOB_IDENTIFIER.NEXTVAL ;
        INSERT INTO G3E_JOB
        ( G3E_IDENTIFIER, 
        G3E_DESCRIPTION, 
        G3E_OWNER, 
        G3E_STATUS, 
        G3E_CREATION,
        G3E_POSTED, 
        G3E_CLOSED,
        G3E_ADDJOBATTR,
        G3E_FIELDUSER, 
        JOB_TYPE, 
        JOB_STATE, 
        WORK_ORDER_ID, 
        G3E_JOBCLASS, 
        G3E_ID, 
        G3E_PROCESSINGSTATUS, 
        G3E_POSTFLAG, 
        G3E_PLACED, 
        COMPANY_OWNERSHIP, 
        WORKFLOW_ID, 
        PROTECTED) 
        VALUES
        ( V_JOB_ID ,--G3E_IDENTIFIER, 
        'IQGEO_'||P_FNO,--G3E_DESCRIPTION 
        USER,--G3E_OWNER
        'Open', --G3E_STATUS
        SYSDATE,--G3E_CREATION
        '',--G3E_POSTED
        '',--G3E_CLOSED
        '',--G3E_ADDJOBATTR
        '',--G3E_FIELDUSER
        'BO',--JOB_TYPE
        'UNC',--JOB_STATE
        'IQGEO_'||V_JOB_ID,--WORK_ORDER_ID
        '', --G3E_JOBCLASS
        G3E_JOB_SEQ.NEXTVAL,--G3E_ID
        '0',--G3E_PROCESSINGSTATUS
        '1', --G3E_POSTFLAG
        '',--G3E_PLACED
        'VM',--COMPANY_OWNERSHIP
        '',--WORKFLOW_ID
        'N' --PROTECTED
        ); 
         LTT_ADMIN.createjob(V_JOB_ID);
         LTT_USER.done;

          select LTT_ID
          INTO P_LTT_ID
          from LTT_IDENTIFIERS 
          where LTT_NAME = TO_CHAR(V_JOB_ID);
         LTT_USER.editjob(V_JOB_ID);

    END PRC_POST_JOB;
PROCEDURE PRC_REVERSE_DATA_CONNECTER
( p_fno             IN NUMBER, 
    p_dml          IN VARCHAR2,
  P_STATUS          OUT VARCHAR2
)
AS

	v_string        varchar2(32000);
    v_string_mand   varchar2(4000);
	V_STRING1       VARCHAR2(20000);
	V_STRING2       VARCHAR2(4000);
	V_QUERY         VARCHAR2(32000);
    V_FINAL_QUERY   VARCHAR2 (32000);
    V_TMP_TABLE_NAME    VARCHAR2(200);
    V_TABLE_NAME    VARCHAR2(200);
    V_G3E_ID NUMBER;
	V_COLUMN_CNT    NUMBER;
    V_14900_FID    NUMBER;
    V_LTT_ID        NUMBER;
    V_JOB_ID        NUMBER;
    V_DETAILID    NUMBER;
    V_node_id       number;
    V_node_id_count number;
    V_node1_id number;
    V_node2_id number;
    V_FNO           NUMBER;
    V_VMX_FNO       NUMBER;
    V_TABLE_CNT     NUMBER;
	V_COLUMN_NAME   VARCHAR2(100);
    V_COLUMN_IQGO   VARCHAR2(100);
    V_COLUMN_value   VARCHAR2(500);    
	V_MAIN_TABLE    VARCHAR2(50);
	V_VMX_ID        NUMBER;
    V_REGION        VARCHAR2(4);
    v_new_g3e_fid   number;
    V_IQGO_VMX_ID   VARCHAR2(500);
    V_vmx_cable     VARCHAR2(500);
    v_CHANGE_TYPE   varchar2(10);
	V_FID_CNT       NUMBER;
	v_count         number;
    v_null_count    number;
    v_null_chk_string varchar2(4000);
    V_ERR_MSG       VARCHAR2(2000);
	E_NOT_EXISTS    EXCEPTION;
    E_TB_NOT_EXISTS    EXCEPTION;
    E_FEATURE_CHK   EXCEPTION;
    E_FID_EXISTS    EXCEPTION;
	CUR_VMX_ID      SYS_REFCURSOR;
    CUR_TMP_DATA      SYS_REFCURSOR;
    V_TEMP_QUERY         VARCHAR2(4000);
    V_FORM_NEW_FID NUMBER;
    V_COLUMN_IQGO2   VARCHAR2(100);
    V_COLUMN_IQGO3 VARCHAR2(100);
    V_COLUMN_value1   VARCHAR2(500);
    v_ownerfno number;
    V_Ownerfid number;    
    V_DUCT_TEMP_QUERY         VARCHAR2(4000);    
    V_FORM_DUCT_NEW_FID NUMBER;
    POS_HORZ_TO NUMBER;
    V_FORM_DUCT_COUNT number;
	V_G3E_CID NUMBER;
    

begin
        V_TMP_TABLE_NAME := pkg_data_connector.fun_table_name (p_FNO);
        IF p_fno = 12301 then
            V_FNO := 12300;
        ELSIF p_fno IN (7201,7202,7203) THEN
            V_FNO := 7200;            
        else
            V_FNO := p_fno;  
        end if;
       
       IF V_TMP_TABLE_NAME IS NULL THEN
         RAISE  E_FEATURE_CHK;
       END IF;
       SELECT COUNT(1)
       INTO V_TABLE_CNT 
       FROM SYS.USER_TABLES
       WHERE TABLE_NAME = V_TMP_TABLE_NAME;
       IF V_TABLE_CNT = 0 THEN
          RAISE E_TB_NOT_EXISTS;
       END IF;
       SELECT  TC.G3E_TABLE 
        INTO V_MAIN_TABLE
        FROM tb_components TC 
        where TC.G3E_FNO = P_FNO
        AND upper (TC.IS_MAIN_table) = 'Y';
        V_COLUMN_IQGO := null;
        V_COLUMN_IQGO2 :=null;
        FOR REC2 IN ( SELECT column_name,TABLE_NAME FROM SYS.all_tab_columns WHERE TABLE_NAME = V_TMP_TABLE_NAME)
        LOOP
            
            IF REC2.column_name in ('VMX_HOUSING','VMX_MANHOLE','VMX_IN_STRUCTURE','VMX_IN_EQUIP') THEN
               V_COLUMN_IQGO :=  REC2.column_name ;            
            ELSIF REC2.column_name in ('VMX_OUT_STRUCTURE','VMX_HOUSINGS','VMX_OUT_EQUIP') THEN            
                V_COLUMN_IQGO2 := REC2.column_name ;
            ELSIF REC2.column_name in ('VMX_N_DUCTS','VMX_CONDUITS') THEN
                V_COLUMN_IQGO3 := REC2.column_name ;
            END IF;
        --  DBMS_OUTPUT.PUT_LINE (REC2.column_name);
          	SELECT COUNT(1)
          	INTO V_COLUMN_CNT
          	FROM data_mapping where g3e_fno =  P_FNO
          	AND UPPER (DATA_EXCHANGE_FIELD) = REC2.column_name;
          	IF V_COLUMN_CNT = 0 THEN             		
                   V_ERR_MSG := 'IQGEO COLUMN NOT EXISTS IN MAPPING TABLE PLEASE ADD :'||REC2.column_name;
             		RAISE E_NOT_EXISTS;
          	END IF;

        END LOOP;

 --DBMS_OUTPUT.PUT_LINE (V_TMP_TABLE_NAME);
	OPEN CUR_VMX_ID FOR q'[SELECT DISTINCT TO_NUMBER (SUBSTR (VMX_ID,INSTR (VMX_ID,'/')+1)) AS T, VMX_ID,VMX_CHANGE_TYPE,trim(VMX_REGION) FROM ]'||V_TMP_TABLE_NAME||Q'[ WHERE VMX_CHANGE_TYPE = ]'||''''||p_dml||'''';
	LOOP
        V_FID_CNT := 0;
        V_VMX_ID := null;        
		FETCH CUR_VMX_ID INTO V_VMX_ID,V_IQGO_VMX_ID,V_CHANGE_TYPE,V_REGION;
        EXIT WHEN CUR_VMX_ID%NOTFOUND;
      --  DBMS_OUTPUT.PUT_LINE ('SELECT COUNT(1) FROM '||V_MAIN_TABLE||' WHERE G3E_FID = '||V_VMX_ID);
      IF  p_FNO IN (7201,7202,7203) THEN
         EXECUTE IMMEDIATE 'SELECT VMX_CABLE FROM '||V_TMP_TABLE_NAME||' WHERE VMX_ID = '||''''||V_IQGO_VMX_ID||'''' INTO v_vmx_cable;   
      END IF;  
	    IF V_CHANGE_TYPE =  'insert'  THEN
            PRC_POST_JOB  ( V_FNO, V_LTT_ID,V_JOB_ID ) ;
       			SELECT count(1)
                INTO V_FID_CNT
                FROM TB_FID_GCOMMS_IQGEO GI
                WHERE GI.IQGEO_FID = V_IQGO_VMX_ID
                and g3e_fno = p_FNO;
                if V_FID_CNT = 0 then
                 
                    if p_fno IN (7201,7202,7203) then
						begin
							SELECT GCOMMS_FID
							INTO v_new_g3e_fid
							FROM TB_FID_GCOMMS_IQGEO GI
							WHERE GI.IQGEO_FID = v_vmx_cable
							and g3e_fno = 7200;
						exception  
						when no_data_found then
						v_new_g3e_fid := pkg_data_connector_reverse.FUN_GET_GCOMS_FID(v_vmx_cable);
						end;
                    else
                        v_new_g3e_fid := G3E_FID_SEQ.nextval;
                    end if;
                  INSERT INTO TB_FID_GCOMMS_IQGEO(IQGEO_FID,GCOMMS_FID , G3E_FNO)
                  values (V_IQGO_VMX_ID,v_new_g3e_fid,p_fno);
                    
                    
                else                  
                      v_err_msg := 'INSERT FAILED : IQGEO FID '||V_IQGO_VMX_ID ||' ALREADY EXISTS IN '||V_MAIN_TABLE||' OR IN TB_FID_GCOMMS_IQGEO TABLE';
					  --EXECUTE IMMEDIATE  Q'[delete FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' ;
					  --commit;
                      RAISE E_NOT_EXISTS;
					  
                    
                end if;

               
               --V_LTT_ID := 0;
                    for rec0 in (SELECT  TC.G3E_TABLE ,TC.IS_MAIN_table,TC.TABLE_ALIAS,G3E_CNO
                                FROM tb_components TC 
                                where TC.G3E_FNO = P_FNO
                                AND upper (tc.required_for_reverse) = 'Y'
                                order by table_order )loop
                    V_STRING := NULL;
                    V_STRING1 := NULL;
                    v_null_chk_string := null;
                    
                        for rec1 in (select * from data_mapping 
                                        where g3e_fno = P_FNO--20600 
                                        and TABLE_NAME = REC0.G3E_TABLE 
                                        AND DATA_EXCHANGE_FIELD is not null 
                                        and column_name not in ('G3E_ID','G3E_FID','G3E_FNO','G3E_CNO')
                                        AND upper (DATA_EXCHANGE_FIELD) not in ('VMX_REGION','VMX_ORIENTATION','VMX_LABEL_ORIENTATION','DATE_INSTALLED')
                                    )
                        loop

                                v_string := v_string||REC1.COLUMN_NAME||',';
                                v_null_chk_string := v_null_chk_string||'||'||REC1.DATA_EXCHANGE_FIELD;
                                IF REC1.TABLE_LEVEL_DEFAULT IS NOT  NULL THEN
                                    IF UPPER ( REC1.DATA_TYPE)= 'NUMBER' THEN
                                        v_string1 := v_string1||REC1.TABLE_LEVEL_DEFAULT||',';
                                    ELSE
                                      v_string1 := v_string1||''''||REC1.TABLE_LEVEL_DEFAULT||''''||',';
                                    END IF;
                              ELSIF REC1.TABLE_LEVEL_DEFAULT IS NULL THEN 
                                IF UPPER( REC1.DATA_EXCHANGE_FIELD) = ( 'VMX_LOCATION') AND P_FNO = 11800 THEN
                                    v_string1 := v_string1||' pkg_data_connector_reverse.fun_get_wkb_reverse_11800 ('||REC1.DATA_EXCHANGE_FIELD||'),';
                                 ELSIF UPPER( REC1.DATA_EXCHANGE_FIELD) IN ('VMX_LOCATION','VMX_TRIANGLE') AND P_FNO in (14900,2700,9100) THEN
									V_STRING1 := V_STRING1||' pkg_data_connector_reverse.fun_get_wkb_reverse (VMX_ORIENTATION,'||REC1.DATA_EXCHANGE_FIELD||','''||UPPER(V_REGION)||'''),';
                                 ELSIF  UPPER( REC1.DATA_EXCHANGE_FIELD) IN ( 'VMX_LOCATION','VMX_LABEL_LOCATION') THEN
                                    v_string1 := v_string1||' pkg_data_connector_reverse.fun_get_wkb_reverse ('||REC1.DATA_EXCHANGE_FIELD||'),';
                                ELSIF UPPER( REC1.DATA_EXCHANGE_FIELD) in ( 'VMX_LABEL_LOCATION') AND P_FNO = 5200 THEN
                                    v_string1 := v_string1||' pkg_data_connector_reverse.fun_get_wkb_reverse (VMX_LABEL_ORIENTATION,'||REC1.DATA_EXCHANGE_FIELD||','''||UPPER(V_REGION)||'''),';
                                ELSIF UPPER(REC1.DATA_EXCHANGE_FIELD) IN ('VMX_BOUNDARY') THEN
                                    v_string1 := v_string1||' pkg_data_connector_reverse.fun_get_wkb_reverse_polygonTo3D ('||REC1.DATA_EXCHANGE_FIELD||','||P_FNO||'),';
                                ELSIF UPPER(REC1.DATA_EXCHANGE_FIELD) IN ('VMX_PATH','VMX_LEAD_IN') THEN
                                    v_string1 := v_string1||' pkg_data_connector_reverse.fun_get_wkb_reverse_polygonTo3D ('||REC1.DATA_EXCHANGE_FIELD||','||P_FNO||'),';
                                ELSE
                                   v_string1 := v_string1||REC1.DATA_EXCHANGE_FIELD||',';
                                END IF;
                            END IF;

                    end loop;
					--TO CALCUALTE THE G3E_CID FOR CABLE OBJECT IN SQEUNCES 
					IF P_FNO IN (7201,7202,7203) THEN 
						EXECUTE IMMEDIATE 'SELECT  NVL(MAX(G3E_CID),0)+1 FROM '||REC0.G3E_TABLE||' WHERE G3E_FNO='||V_FNO||' AND G3E_FID='||v_new_g3e_fid INTO V_G3E_CID;
					ELSE 
						V_G3E_CID :=1;
					END IF;

    -- ADD MANDATORY COLUMNS
    v_string := 'G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID,'||v_string;
    -------------------------------------------
    v_string := RTRIM (v_string,',')||')';
    v_string := 'INSERT INTO '||REC0.G3E_TABLE||'( '||v_string;    

     -- ADD MANDATORY COLUMN VALUES
     v_string_mand := LTRIM(REC0.G3E_TABLE,'B$')||'_SEQ.NEXTVAL,'|| V_FNO||','||v_new_g3e_fid||','||REC0.G3E_CNO||','||V_G3E_CID||','||V_LTT_ID||',';
     ---------------------------------------------------------
     v_string1 := RTRIM (v_string1,',');
    -- V_QUERY := v_string1;
     v_string1 := 'SELECT '||nvl(v_string1,'null')||' FROM '||V_TMP_TABLE_NAME ||' A  WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
      v_null_chk_string := 'SELECT '||ltrim(nvl(v_null_chk_string,'null'),'||')||' FROM '||V_TMP_TABLE_NAME ||' A WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
      v_null_chk_string :=  'select count(1) from ('||replace( v_null_chk_string,' FROM ',' as t FROM ')||') where t is not null';

    execute immediate v_null_chk_string into v_null_count;
   --  DBMS_OUTPUT.PUT_LINE(v_null_chk_string);
      if v_null_count > 0 then

        v_string1 := replace(v_string1,'SELECT ','SELECT '||v_string_mand);

       V_QUERY := v_string||' '||v_string1;
     --DBMS_OUTPUT.PUT_LINE(V_QUERY);
    elsif v_null_count = 0 and REC0.G3E_TABLE =  'B$GC_DETAIL' then
   --V_DETAILID := G3E_DETAILID_SEQ.NEXTVAL;   
   select max(G3E_DETAILID)+1 into V_DETAILID from B$GC_DETAIL;

        V_QUERY := 'INSERT INTO '||REC0.G3E_TABLE||'( G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID,DETAIL_MBRXLO,DETAIL_MBRYLO,DETAIL_MBRXHI,DETAIL_MBRYHI,G3E_DETAILID,DETAIL_LEGENDNUMBER,G3E_DETAILTYPE,DETAIL_USERNAME )';
                    IF v_fno = 14100 THEN  
                        V_QUERY := V_QUERY || ' SELECT '||RTRIM(v_string_mand,',')||',PKG_DATA_CONNECTOR_REVERSE.fun_get_offset_coordinates(VMX_BOUNDARY,'||''''||'X_LOW'||''''||','||V_FNO||'),PKG_DATA_CONNECTOR_REVERSE.fun_get_offset_coordinates(VMX_BOUNDARY,'||''''||'Y_LOW'||''''||','||V_FNO
                        ||'),PKG_DATA_CONNECTOR_REVERSE.fun_get_offset_coordinates(VMX_BOUNDARY,'||''''||'X_HIGH'||''''||','||V_FNO||'),PKG_DATA_CONNECTOR_REVERSE.fun_get_offset_coordinates(VMX_BOUNDARY,'||''''||'Y_HIGH'||''''||','||V_FNO||'),'||V_DETAILID
                        ||',2,8,PKG_DATA_CONNECTOR_REVERSE.FUN_GET_DETAIL_USR('||v_fno||','||v_new_g3e_fid
                        ||') FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
                    ELSE 
                        V_QUERY := V_QUERY ||' SELECT '||RTRIM(v_string_mand,',')||',PKG_DATA_CONNECTOR_REVERSE.fun_get_offset_coordinates(VMX_LOCATION,'||''''||'X_LOW'||''''||','||V_FNO||'),PKG_DATA_CONNECTOR_REVERSE.fun_get_offset_coordinates(VMX_LOCATION,'||''''||'Y_LOW'||''''||','||V_FNO
                        ||'),PKG_DATA_CONNECTOR_REVERSE.fun_get_offset_coordinates(VMX_LOCATION,'||''''||'X_HIGH'||''''||','||V_FNO||'),PKG_DATA_CONNECTOR_REVERSE.fun_get_offset_coordinates(VMX_LOCATION,'||''''||'Y_HIGH'||''''||','||V_FNO||'),'||V_DETAILID
                        ||',2,8,PKG_DATA_CONNECTOR_REVERSE.FUN_GET_DETAIL_USR('||v_fno||','||v_new_g3e_fid
                        ||') FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
                    END IF;
     -- DBMS_OUTPUT.PUT_LINE(V_QUERY); 
     elsif v_null_count = 0 and REC0.G3E_TABLE =  'B$GC_DETAILIND_S' then
        V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE||' (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, G3E_GEOMETRY)' ;
        IF v_fno = 14100 THEN        
        V_QUERY := V_QUERY || 'SELECT '||RTRIM(v_string_mand,',')||',sdo_geom.sdo_centroid(PKG_DATA_CONNECTOR_REVERSE.fun_get_wkb_reverse_polygonTo3D(VMX_BOUNDARY,'||P_FNO||')) FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
        ELSE        
        V_QUERY := V_QUERY || 'SELECT '||RTRIM(v_string_mand,',')||',PKG_DATA_CONNECTOR_REVERSE.fun_get_wkb_reverse((VMX_LOCATION)) FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
        END IF;
        --DBMS_OUTPUT.PUT_LINE(V_QUERY);
    elsif v_null_count = 0 and  REC0.G3E_TABLE 
            in ( 'B$DGC_POLE_P','B$DGC_BLDG_P','B$DGC_CLOSURE_P','B$DGC_FCBL_T','B$DGC_FCBL_L','B$DGC_FSPLICE_T','B$DGC_FSPLICE_S','B$DGC_FRACK_S','B$DGC_FRACK_T') then
        
        IF v_fno = 14100 THEN
            V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE||' (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, G3E_DETAILID,G3E_GEOMETRY)' ;
            V_QUERY := V_QUERY || 'SELECT '||RTRIM(v_string_mand,',')||','||V_DETAILID||',PKG_DATA_CONNECTOR_REVERSE.fun_get_wkb_reverse_polygonTo3D(VMX_BOUNDARY,'||P_FNO||') FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
        ELSIF v_fno IN( 15700,11800) THEN
        
           EXECUTE IMMEDIATE 'SELECT  PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID(VMX_HOUSING),PKG_DATA_CONNECTOR_REVERSE.FUN_GET_FNO(VMX_HOUSING) FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' INTO V_COLUMN_VALUE,V_COLUMN_VALUE1;
            IF V_COLUMN_VALUE1 = 14900 THEN
                BEGIN
                select G3E_DETAILID
                into v_detailid
                from b$gc_detail
                where g3e_fid = V_COLUMN_VALUE; 
                EXCEPTION
                   WHEN OTHERS THEN 
                   v_detailid := NULL;
                END;
            END IF;
            IF v_detailid  IS NOT NULL THEN
                V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE||' (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, G3E_DETAILID,G3E_GEOMETRY)' ;
                V_QUERY := V_QUERY || 'SELECT '||RTRIM(v_string_mand,',')||','||V_DETAILID||','||' PKG_DATA_CONNECTOR_REVERSE.FUN_GET_CENTROID_DETAIL(G3E_GEOMETRY,'||P_FNO||','||''''|| REC0.G3E_TABLE||''''||'  )from b$dgc_closure_p where g3e_fid ='|| V_COLUMN_VALUE;
            END IF;
        ELSIF v_fno IN( 7200) THEN
        
            IF REC0.G3E_TABLE = 'B$DGC_FCBL_L' THEN
        
            EXECUTE IMMEDIATE 'SELECT  PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID(VMX_IN_EQUIP),PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID(VMX_OUT_EQUIP) FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' INTO V_COLUMN_VALUE,V_COLUMN_VALUE1;
               begin
                    select a.g3e_fid 
                    into V_14900_FID
                    from b$gc_ownership a
                    join b$gc_ownership b on ( a.g3e_id = b.owner1_id)
                    where b.g3e_fid = V_COLUMN_VALUE
                    and a.g3e_fno = 14900;
                exception
                    when others then
                    V_14900_FID:= 0;
                end;
                IF V_14900_FID = 0 THEN
                BEGIN
                    select a.g3e_fid 
                    into V_14900_FID
                    from b$gc_ownership a
                    join b$gc_ownership b on ( a.g3e_id = b.owner1_id)
                    where b.g3e_fid = V_COLUMN_VALUE1
                    and a.g3e_fno = 14900;
                  exception
                   when others then
                    V_14900_FID:= 0;
                    end;
                END IF;
             --   dbms_output.put_line(V_14900_FID);
               -- dbms_output.put_line(V_COLUMN_VALUE1);
                IF V_14900_FID <> 0 THEN
                    BEGIN
                    select G3E_DETAILID
                    into v_detailid
                    from b$gc_detail
                    where g3e_fid = V_14900_FID; 
                   EXCEPTION
                      WHEN OTHERS THEN 
                      v_detailid := 0;
                   -- dbms_output.put_line(v_detailid);
                    END;
                END IF;
              ELSIF REC0.G3E_TABLE = 'B$DGC_FCBL_T' THEN
                  
                BEGIN
                    select G3E_DETAILID
                   into v_detailid
                    from b$Dgc_FCBL_L
                    where g3e_fid = v_new_g3e_fid; 
                    SELECT G3E_FID 
                    into V_14900_FID
                    FROM B$GC_DETAIL WHERE G3E_FNO=14900 AND G3E_DETAILID = v_detailid;
                    
                   EXCEPTION
                      WHEN OTHERS THEN 
                      v_detailid := 0;
                   -- dbms_output.put_line(v_detailid);
                    END;
                    END IF;
              
            IF v_detailid <> 0 THEN
                V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE||' (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, G3E_DETAILID,G3E_GEOMETRY)' ;
                V_QUERY := V_QUERY || 'SELECT '||RTRIM(v_string_mand,',')||','||V_DETAILID||','||' PKG_DATA_CONNECTOR_REVERSE.FUN_GET_CENTROID_DETAIL(G3E_GEOMETRY,'||P_FNO||','|| ''''||REC0.G3E_TABLE||'''' ||' )from b$dgc_closure_p where g3e_fid ='|| V_14900_FID;
            END IF;
              
        ELSE
            V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE||' (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, G3E_DETAILID,G3E_GEOMETRY)' ;
            V_QUERY := V_QUERY || 'SELECT '||RTRIM(v_string_mand,',')||','||V_DETAILID||',PKG_DATA_CONNECTOR_REVERSE.FUN_GET_POLYGON(PKG_DATA_CONNECTOR_REVERSE.fun_get_wkb_reverse(VMX_LOCATION),'||V_FNO||') FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';

        END IF;
        
    ELSIF V_COLUMN_IQGO = 'VMX_IN_EQUIP' AND V_COLUMN_IQGO2 = 'VMX_OUT_EQUIP' AND REC0.G3E_TABLE = 'B$GC_NR_CONNECT' THEN
            EXECUTE IMMEDIATE  Q'[SELECT  VMX_IN_EQUIP,VMX_OUT_EQUIP FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' into V_COLUMN_value,V_COLUMN_value1;     
            
            V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE||' (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID,IN_FNO,IN_FID,OUT_FNO,OUT_FID)' || 
                'VALUES  ('||RTRIM(v_string_mand,',')||','||PKG_DATA_CONNECTOR_REVERSE.FUN_GET_FNO(V_COLUMN_value)||','||PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID ( V_COLUMN_value)||','||PKG_DATA_CONNECTOR_REVERSE.FUN_GET_FNO(V_COLUMN_value1)||','||PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID ( V_COLUMN_value1)||' )';
         
     elsif v_null_count = 0 and REC0.G3E_TABLE IN ( 'B$DGC_POLE_T','B$DGC_BLDG_T') then
        
        V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE||' (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, G3E_DETAILID,G3E_GEOMETRY)' || 
        'SELECT '||RTRIM(v_string_mand,',')||','||V_DETAILID||',PKG_DATA_CONNECTOR_REVERSE.FUN_GET_POINT_OFSET(PKG_DATA_CONNECTOR_REVERSE.fun_get_wkb_reverse(VMX_LABEL_LOCATION),'|| V_FNO ||') FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
     elsif v_null_count = 0 and REC0.G3E_TABLE = 'B$GC_FSPLICE_T' then
        V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE||' (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, G3E_GEOMETRY)' || 
        'SELECT '||RTRIM(v_string_mand,',')||',PKG_DATA_CONNECTOR_REVERSE.FUN_GET_POINT_OFSET(PKG_DATA_CONNECTOR_REVERSE.fun_get_wkb_reverse(VMX_LOCATION),'|| V_FNO ||') FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
    elsif v_null_count = 0 and REC0.G3E_TABLE IN ('B$DGC_CLOSURE_T') then
        
        V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE||' (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, G3E_DETAILID,G3E_GEOMETRY)' || 
        'SELECT '||RTRIM(v_string_mand,',')||','||V_DETAILID||',PKG_DATA_CONNECTOR_REVERSE.FUN_GET_POINT_OFSET(PKG_DATA_CONNECTOR_REVERSE.fun_get_wkb_reverse(VMX_LOCATION),'|| v_FNO ||') FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
    elsif v_null_count = 0 and REC0.G3E_TABLE IN ('B$GC_NE_CONNECT') AND P_FNO = 2700 then
        V_node_id := G3E_NODE_SEQ.nextval;
        V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE||' (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, node1_id,node2_id)' || 
        ' VALUES  ('||RTRIM(v_string_mand,',')||','||V_node_id||','||V_node_id||' )';
    elsif v_null_count = 0 and V_COLUMN_IQGO = 'VMX_MANHOLE' AND REC0.G3E_TABLE IN ('B$GC_NE_CONNECT') then
        EXECUTE IMMEDIATE  Q'[SELECT PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID (VMX_MANHOLE) FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' into V_COLUMN_value;     
        IF V_COLUMN_value IS NOT NULL THEN
            BEGIN
                select node1_id  INTO V_node_id 
                FROM B$GC_NE_CONNECT  
                WHERE G3E_FID = V_COLUMN_value;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                V_ERR_MSG := 'parent id '||V_COLUMN_value||' NOT FOUND IN B$GC_NE_CONNECT TABLE';
            RAISE E_NOT_EXISTS;
            END;
          
            V_QUERY := 'INSERT INTO B$GC_NE_CONNECT (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, node1_id,node2_id)' || 
            'VALUES  ('||RTRIM(v_string_mand,',')||','||V_node_id||','||V_node_id||' )';    
       END IF;
    elsif v_null_count = 0 and V_COLUMN_IQGO in ('VMX_IN_STRUCTURE') AND V_COLUMN_IQGO2 IN ('VMX_OUT_STRUCTURE') AND REC0.G3E_TABLE IN ('B$GC_NE_CONNECT') AND P_FNO=2200 then
        
           
        IF V_COLUMN_IQGO = 'VMX_IN_STRUCTURE' THEN
	EXECUTE IMMEDIATE  Q'[SELECT PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID ( VMX_IN_STRUCTURE) FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' into V_COLUMN_value;     
        
        select count(*)  INTO V_node_id_count FROM B$GC_NE_CONNECT  WHERE G3E_FID = V_COLUMN_value;
            if V_node_id_count = 0 then
                V_node1_id := G3E_NODE_SEQ.nextval;
            else
                select node1_id  INTO V_node1_id FROM B$GC_NE_CONNECT  WHERE G3E_FID = V_COLUMN_value;
                -- If row is present and  node1 or node 2 is null we need to generate the sequence
                /*if V_node1_id is null then
                    V_node1_id := G3E_NODE_SEQ.nextval;
                end if;*/
            end if;
        END IF;
        
        IF V_COLUMN_IQGO2 = 'VMX_OUT_STRUCTURE' THEN
        
        EXECUTE IMMEDIATE  Q'[SELECT PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID ( VMX_OUT_STRUCTURE) FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' into V_COLUMN_value;     
        
        select count(*)  INTO V_node_id_count FROM B$GC_NE_CONNECT  WHERE G3E_FID = V_COLUMN_value;
        
            if V_node_id_count = 0 then
                V_node2_id := G3E_NODE_SEQ.nextval;
            else
                select node2_id  INTO V_node2_id FROM B$GC_NE_CONNECT  WHERE G3E_FID = V_COLUMN_value;
                -- If row is present and  node1 or node 2 is null we need to generate the sequence
                /*if V_node2_id is null then
                    V_node2_id := G3E_NODE_SEQ.nextval;
                end if;*/
            end if;
        END IF;
        
        
        if V_node1_id <> 0 and V_node2_id <> 0 then
            V_QUERY := 'INSERT INTO B$GC_NE_CONNECT (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, node1_id,node2_id)' || 
            'VALUES  ('||RTRIM(v_string_mand,',')||','||V_node1_id||','||V_node2_id||' )';
        end if;
        
    elsif v_null_count = 0 and  REC0.G3E_TABLE IN ('B$GC_CONTAIN') AND P_FNO in (4100,4000,2200,7200) then
    
    IF V_COLUMN_IQGO2 = 'VMX_HOUSINGS' OR V_COLUMN_IQGO3 = 'VMX_CONDUITS'  THEN
        
		IF V_COLUMN_IQGO2 ='VMX_HOUSINGS' THEN
			V_COLUMN_value1 :=V_COLUMN_IQGO2;
		ELSIF V_COLUMN_IQGO3 = 'VMX_CONDUITS' THEN
			V_COLUMN_value1 :=V_COLUMN_IQGO3;
		END IF;
		
        EXECUTE IMMEDIATE  'SELECT '||V_COLUMN_value1||' FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' into V_COLUMN_value;
            V_TEMP_QUERY := null;
            V_G3E_CID :=0;
            for rec2 in (SELECT PKG_DATA_CONNECTOR_REVERSE.FUN_GET_FNO (strings) AS FNO,PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID (strings) AS FID, CID
						FROM (
								select LEVEL AS CID,regexp_substr(V_COLUMN_value, '[^;]+',1,level) as strings from dual 
										connect by regexp_substr(V_COLUMN_value, '[^;]+',1,level) is not null
							  )
						)
            loop              
                
                select count(*)  INTO V_node_id_count FROM B$GC_CONTAIN  WHERE G3E_FID = v_new_g3e_fid and G3E_OWNERFID=REC2.FID;               
                
				
                IF V_node_id_count = 0 THEN 
					v_string_mand := REPLACE (v_string_mand,'1,',NULL);
					
                    V_TEMP_QUERY := V_TEMP_QUERY || 'INSERT INTO B$GC_CONTAIN (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,LTT_ID,G3E_CID,G3E_OWNERFNO,G3E_OWNERFID )' || 
                            'VALUES  ('||RTRIM(v_string_mand,',')||','||REC2.CID||','||REC2.FNO||','|| REC2.FID ||');';
						
						V_QUERY :=  V_TEMP_QUERY ;
						V_QUERY := RTRIM(V_QUERY,';');
                END IF;
                
            end loop;
			
			
    
    ELSIF V_COLUMN_IQGO3 IN ('VMX_N_DUCTS') THEN
    
            V_QUERY:= 'INSERT INTO B$GC_CONTAIN (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID,G3E_OWNERFNO,G3E_OWNERFID )' || 
                            'VALUES  ('||RTRIM(v_string_mand,',')||','||0||','|| 0 ||' )';              
            EXECUTE IMMEDIATE  Q'[SELECT VMX_N_DUCTS FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' into V_FORM_DUCT_COUNT;            
            
            IF V_FORM_DUCT_COUNT > 0 THEN
                V_FORM_NEW_FID := G3E_FID_SEQ.nextval;
                            
                 V_TEMP_QUERY:= V_TEMP_QUERY ||'INSERT INTO B$GC_NETELEM (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID,SECURE)' || 
                            'VALUES  ('||GC_NETELEM_SEQ.NEXTVAL||','||2400||','||V_FORM_NEW_FID||','||51||','||1||','|| V_LTT_ID ||',''N'' )' ||';';
                            
                V_TEMP_QUERY:= V_TEMP_QUERY || 'INSERT INTO B$GC_CONTAIN (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID,G3E_OWNERFNO,G3E_OWNERFID )' || 
                            'VALUES  ('||GC_CONTAIN_SEQ.NEXTVAL||','||2400||','|| V_FORM_NEW_FID ||',65,1,'||V_LTT_ID||','||V_FNO||','||v_new_g3e_fid||' )' ||';';
                            
                V_TEMP_QUERY:= V_TEMP_QUERY || 'INSERT INTO B$GC_FORM (G3E_ID, G3E_FNO, G3E_FID, G3E_CNO, G3E_CID,FEATURE_TYPE,MATERIAL,NUM_DUCTS,
                STALE_FLAG_FROM,STALE_FLAG_TO,LTT_ID )' || 
                'VALUES  ('||GC_FORM_SEQ.NEXTVAL||',2400,'|| V_FORM_NEW_FID ||',2401,1,''STRAIGHT'',''PVC'','||V_FORM_DUCT_COUNT||',1,1,'||V_LTT_ID||' )' ||';';
            
                V_QUERY :=V_QUERY ||';'|| V_TEMP_QUERY;
                POS_HORZ_TO :=V_FORM_DUCT_COUNT;  
                FOR POS_HORZ_FROM in 1..V_FORM_DUCT_COUNT LOOP
                       V_FORM_DUCT_NEW_FID := G3E_FID_SEQ.nextval;                       
                       V_DUCT_TEMP_QUERY :=null;
                       
                       V_DUCT_TEMP_QUERY:= V_DUCT_TEMP_QUERY ||'INSERT INTO B$GC_NETELEM (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID,SECURE)' || 
                            'VALUES  ('||GC_NETELEM_SEQ.NEXTVAL||','||2300||','||V_FORM_DUCT_NEW_FID||','||51||','||1||','|| V_LTT_ID ||',''N'' )' ||';';
                            
                        V_DUCT_TEMP_QUERY:= V_DUCT_TEMP_QUERY || 'INSERT INTO B$GC_CONTAIN (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID,G3E_OWNERFNO,G3E_OWNERFID )' || 
                            'VALUES  ('||GC_CONTAIN_SEQ.NEXTVAL||','||2300||','|| V_FORM_DUCT_NEW_FID ||',65,1,'||V_LTT_ID||',2400,'||V_FORM_NEW_FID||' )' ||';';
                            
                       V_DUCT_TEMP_QUERY:= V_DUCT_TEMP_QUERY || 'INSERT INTO B$GC_DUCT (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,FEATURE_TYPE,ASSIGNMENT,STALE_FLAG_FROM,POS_HORZ_FROM,POS_VERT_FROM,STALE_FLAG_TO,POS_HORZ_TO,POS_VERT_TO,AGREEMENT,LTT_ID )' || 
                            'VALUES  ('||GC_DUCT_SEQ.NEXTVAL||','||2300||','|| V_FORM_DUCT_NEW_FID ||',2301,1,''THROUGH'','||POS_HORZ_FROM||',1,'||POS_HORZ_FROM||',1,1,'||POS_HORZ_TO||',1,''N'','||V_LTT_ID||' )' ||';';     
  
                        POS_HORZ_TO :=POS_HORZ_TO-1;
                        V_QUERY :=V_QUERY || V_DUCT_TEMP_QUERY; 
                END LOOP;
                           
               V_QUERY := RTRIM(V_QUERY,';');
            END IF;
    END IF;
    else
        --DBMS_OUTPUT.PUT_LINE ('Not inserting into table '||REC0.G3E_TABLE||' : all rows to insert are null');
        V_QUERY := 'INSERT INTO '||REC0.G3E_TABLE||'( G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID )'||' VALUES ('||RTRIM(v_string_mand,',')||')';
       -- DBMS_OUTPUT.PUT_LINE(V_QUERY);
      end if;
       --DBMS_OUTPUT.PUT_LINE(V_COLUMN_IQGO);
      IF V_COLUMN_IQGO = 'VMX_HOUSING' and UPPER( REC0.G3E_TABLE) in ('B$GC_OWNERSHIP','B$GC_ISP_OWNERSHIP') THEN
      
    EXECUTE IMMEDIATE  Q'[SELECT  PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID (VMX_HOUSING) FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' into V_COLUMN_value;     
     
      IF V_COLUMN_value IS NOT NULL and REC0.G3E_TABLE <> 'B$GC_ISP_OWNERSHIP' THEN
        BEGIN 
          
           EXECUTE IMMEDIATE 'select G3E_ID  
           from '||REC0.G3E_TABLE ||
           ' where g3e_fid = '|| V_COLUMN_value INTO V_G3E_ID;
           
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            V_ERR_MSG := 'parent id '||V_COLUMN_value||' NOT FOUND IN ' || LTRIM(REC0.G3E_TABLE,'B$') ||' TABLE';
            RAISE E_NOT_EXISTS;
        END;
    ELSE
        V_G3E_ID := NULL;
    END IF;
    
    IF V_COLUMN_value IS NOT NULL AND P_FNO = 14200 AND REC0.G3E_TABLE = 'B$GC_ISP_OWNERSHIP' THEN
   
   BEGIN  
      
       EXECUTE IMMEDIATE 'select G3E_ID  
                          from '||REC0.G3E_TABLE ||
                         ' where g3e_fid = '|| V_COLUMN_value INTO V_G3E_ID;
   EXCEPTION
       WHEN NO_DATA_FOUND THEN
           V_ERR_MSG := 'parent id '||V_COLUMN_value||' NOT FOUND IN ' || LTRIM(REC0.G3E_TABLE,'B$') ||' TABLE';
           RAISE E_NOT_EXISTS;
   END;
   END IF;
    IF V_G3E_ID IS NOT  NULL THEN
        IF REC0.G3E_TABLE = 'B$GC_OWNERSHIP' AND P_FNO = 14200 THEN
         V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE ||'( G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID ) VALUES ('
        || LTRIM(REC0.G3E_TABLE,'B$') ||'_SEQ.NEXTVAL,'|| V_FNO||','||v_new_g3e_fid||',64,1,'||V_LTT_ID||' )';
        -- V_FINAL_QUERY := V_FINAL_QUERY|| V_QUERY||';' ;
       elsif  UPPER( REC0.G3E_TABLE) in ('B$GC_ISP_OWNERSHIP') AND P_FNO = 14200 THEN
       V_QUERY := 'INSERT INTO B$GC_ISP_OWNERSHIP (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID,OWNER1_ID)' || 
        'VALUES  ('||RTRIM(v_string_mand,',')||','||V_G3E_ID||' )';
       ElsIF UPPER( REC0.G3E_TABLE) = 'B$GC_OWNERSHIP' THEN
        V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE ||'( G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID,OWNER1_ID ) VALUES ('
        || LTRIM(REC0.G3E_TABLE,'B$') ||'_SEQ.NEXTVAL,'|| V_FNO||','||v_new_g3e_fid||',64,1,'||V_LTT_ID||','||V_G3E_ID||' )';
        -- V_FINAL_QUERY := V_FINAL_QUERY|| V_QUERY||';' ;
        end if;
    ELSIF V_G3E_ID IS NULL THEN
        IF REC0.G3E_TABLE = 'B$GC_OWNERSHIP' THEN
             V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE ||'( G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID ) VALUES ('
            || LTRIM(REC0.G3E_TABLE,'B$') ||'_SEQ.NEXTVAL,'|| V_FNO||','||v_new_g3e_fid||',64,1,'||V_LTT_ID||' )';
        END IF;
    END IF;
  
   END IF;


--DBMS_OUTPUT.PUT_LINE(v_query);

   IF REC0.G3E_TABLE = 'B$GC_NETELEM' THEN

       V_FINAL_QUERY := V_FINAL_QUERY||'ltt_user.setconfiguration('||''''||V_REGION||''''||');' ;
    END IF;
     SELECT DECODE(V_QUERY,null,null,V_QUERY||';') INTO V_QUERY FROM DUAL;
    V_FINAL_QUERY := V_FINAL_QUERY|| V_QUERY ;
   IF REC0.G3E_TABLE = 'B$GC_NETELEM' THEN

       V_FINAL_QUERY := V_FINAL_QUERY||' update b$gc_netelem set region = ' ||''''||V_REGION||''''||' where g3e_fid = '|| v_new_g3e_fid||';';
    END IF;
	
    V_QUERY:=null;
     end loop;
      
          V_FINAL_QUERY:= ' begin '|| V_FINAL_QUERY||' LTT_POST.post;     end;';
    --EXECUTE IMMEDIATE V_FINAL_QUERY;
    DBMS_OUTPUT.PUT_LINE(V_FINAL_QUERY);
      V_FINAL_QUERY := null;     
      --EXECUTE IMMEDIATE  Q'[delete FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' ;
      --commit;
    rollback;
     
    ELSIF V_CHANGE_TYPE =  'update' THEN
        PRC_POST_JOB  ( v_FNO, V_LTT_ID,V_JOB_ID ) ; 
        for rec0 in (SELECT  TC.G3E_TABLE ,TC.IS_MAIN_table,TC.TABLE_ALIAS,TC.G3E_CNO,tc.g3e_fno
                        FROM tb_components TC 
                        where TC.G3E_FNO = v_fno
                        AND upper (TC.required_for_reverse) = 'Y'
                        order by table_order
                )
            loop
			v_new_g3e_fid :=PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID(V_IQGO_VMX_ID);
			-- ADD MANDATORY COLUMN VALUES
			v_string_mand := LTRIM(REC0.G3E_TABLE,'B$')||'_SEQ.NEXTVAL,'|| V_FNO||','||PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID(V_IQGO_VMX_ID)||','||REC0.G3E_CNO||','||V_LTT_ID||',';
             V_STRING1 := null;
            V_STRING := null;
              for rec1 in ( select DM.COLUMN_NAME,DM.DATA_EXCHANGE_FIELD 
                            from data_mapping dm
                            where g3e_fno = rec0.g3e_fno
                            and table_name = rec0.g3e_table
                             AND DM.DATA_EXCHANGE_FIELD is not null
                             and upper(dm.DATA_EXCHANGE_FIELD) NOT in( 'VMX_IN_STRUCTURE','VMX_OUT_STRUCTURE','VMX_N_DUCTS','VMX_ID','VMX_REGION','VMX_ORIENTATION','VMX_CHANGE_TYPE','DATE_INSTALLED',
							 'VMX_MANHOLE','VMX_HOUSING','VMX_N_FIBER_PORTS','VMX_N_FIBER_OUT_PORTS','VMX_HOUSINGS','VMX_CONDUITS','VMX_VALIDATED','VMX_IN_EQUIP','VMX_OUT_EQUIP')
                             )
                loop
                   v_query :=  'SELECT COUNT(1) AS COL FROM '||V_TMP_TABLE_NAME||' where vmx_id = '||''''||V_IQGO_VMX_ID ||''''||' AND ' ||REC1.DATA_EXCHANGE_FIELD||' IS NOT NULL';
                    execute immediate v_query into v_count; 
                    
                    IF v_count <> 0 and UPPER( REC1.DATA_EXCHANGE_FIELD) = ( 'VMX_LOCATION') AND P_FNO in (14900,2700) THEN
                        V_STRING := V_STRING||rec1.column_name||',';
                        V_STRING1 := V_STRING1||' pkg_data_connector_reverse.fun_get_wkb_reverse (VMX_ORIENTATION,'||REC1.DATA_EXCHANGE_FIELD||','''||UPPER(V_REGION)||'''),';
                    
                    ELSIF  v_count <> 0 and UPPER( REC1.DATA_EXCHANGE_FIELD) IN ( 'VMX_LOCATION','VMX_LABEL_LOCATION') and P_FNO!=11800  THEN 
                        V_STRING := V_STRING||rec1.column_name||',';
                        V_STRING1 := V_STRING1||' pkg_data_connector_reverse.fun_get_wkb_reverse ( '||REC1.DATA_EXCHANGE_FIELD||'),';
						
                    ELSIF  v_count <> 0 and UPPER( REC1.DATA_EXCHANGE_FIELD) = 'VMX_LOCATION'  and P_FNO=11800 THEN 
                        V_STRING := V_STRING||rec1.column_name||',';
                        V_STRING1 := V_STRING1||' pkg_data_connector_reverse.fun_get_wkb_reverse_11800 ( '||REC1.DATA_EXCHANGE_FIELD||'),';
						
                    ELSIF v_count <> 0 and UPPER( REC1.DATA_EXCHANGE_FIELD) IN ( 'VMX_BOUNDARY','VMX_PATH') THEN
                        V_STRING := V_STRING||rec1.column_name||',';
                        V_STRING1 := V_STRING1||' pkg_data_connector_reverse.fun_get_wkb_reverse_polygonTo3D ( '||REC1.DATA_EXCHANGE_FIELD||','||P_FNO||'),'; 
                     ELSIF v_count <> 0 and UPPER( REC1.DATA_EXCHANGE_FIELD) IN ( 'VMX_HOUSING') THEN
                     EXECUTE IMMEDIATE  Q'[SELECT  PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID  (VMX_HOUSING) FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' into V_COLUMN_value;     
                      BEGIN 
                      
                       EXECUTE IMMEDIATE 'select G3E_ID '||  
                       'from '||REC0.G3E_TABLE ||
                       ' where g3e_fid = '|| V_COLUMN_value INTO V_G3E_ID;
                       
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        V_ERR_MSG := 'parent id '||V_COLUMN_value||' NOT FOUND IN ' || LTRIM(REC0.G3E_TABLE,'B$') ||' TABLE';
                        RAISE E_NOT_EXISTS;
                    END;
                    ELSIF  v_count <> 0 then
                        V_STRING := V_STRING||rec1.column_name||',';
                     V_STRING1 := V_STRING1||REC1.DATA_EXCHANGE_FIELD||',';
                     
                     elsif v_count = 0 then
                     null;

                     end if;
                    
                end loop;
                    IF REC0.G3E_TABLE = 'B$GC_NETELEM' THEN                        
                        V_FINAL_QUERY := V_FINAL_QUERY||'ltt_user.setconfiguration('||''''||V_REGION||''''||');' ;
                    END IF;
                    
                    IF REC0.G3E_TABLE = 'B$GC_NE_CONNECT' AND P_FNO=2200 THEN
                        --V_FINAL_QUERY := V_FINAL_QUERY||'ltt_user.setconfiguration('||''''||V_REGION||''''||');'
                        EXECUTE IMMEDIATE  Q'[SELECT  PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID  (VMX_IN_STRUCTURE),PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID  (VMX_OUT_STRUCTURE) FROM ]'||
                        V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' into V_COLUMN_value,V_COLUMN_value1;     
                        V_FINAL_QUERY  := V_FINAL_QUERY || 'PRC_PARENT_TAB_UPDATE('||nvl(V_COLUMN_value,0)||','||nvl(V_COLUMN_value1,0)||','||''''||REC0.G3E_TABLE||''''||','||V_VMX_ID||','||V_FNO||','||V_LTT_ID||');';
                        
                    END IF;
					EXECUTE IMMEDIATE  'SELECT  VMX_CONDUITS FROM '|| V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||''''  into V_COLUMN_value;
					
					IF REC0.G3E_TABLE ='B$GC_CONTAIN' AND P_FNO=7200 AND V_COLUMN_value IS NOT NULL  THEN
						
							V_FINAL_QUERY := V_FINAL_QUERY||'DELETE '||REC0.G3E_TABLE||' WHERE G3E_FNO='||P_FNO||' AND G3E_FID='||PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID(V_IQGO_VMX_ID)||';';
							for rec2 in (SELECT PKG_DATA_CONNECTOR_REVERSE.FUN_GET_FNO (strings) AS FNO,PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID (strings) AS FID, CID
													FROM (
															select LEVEL AS CID,regexp_substr(V_COLUMN_value, '[^;]+',1,level) as strings from dual 
																	connect by regexp_substr(V_COLUMN_value, '[^;]+',1,level) is not null
														  )
													)
										loop  
										
												V_FINAL_QUERY := V_FINAL_QUERY || 'INSERT INTO B$GC_CONTAIN (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,LTT_ID,G3E_CID,G3E_OWNERFNO,G3E_OWNERFID )' || 
														'VALUES  ('||v_string_mand||REC2.CID||','||REC2.FNO||','|| REC2.FID ||');';
													--dbms_output.put_line(V_TEMP_QUERY);
											
											
										end loop;
											
							END IF;
					
                
                if V_STRING is not null then
                   IF P_FNO IN (7201,7202,7203) THEN
                        V_FINAL_QUERY := V_FINAL_QUERY ||'UPDATE '||rec0.G3E_TABLE||' TB0 SET ('||V_STRING||'LTT_ID ) =( SELECT '||V_STRING1||V_LTT_ID||
                                        ' FROM '||V_TMP_TABLE_NAME||Q'[ TB1 where SUBSTR (TB1.VMX_ID,INSTR(TB1.VMX_ID,'/')+1) = TB0.G3E_ID)]'
                                        ||'WHERE G3E_ID  = '|| SUBSTR (V_IQGO_VMX_ID,INSTR(V_IQGO_VMX_ID,'/')+1)||';' ;
                   ELSE
                       V_FINAL_QUERY := V_FINAL_QUERY ||'UPDATE '||rec0.G3E_TABLE||' TB0 SET ('||V_STRING||'LTT_ID ) =( SELECT '||V_STRING1||V_LTT_ID||
                                        ' FROM '||V_TMP_TABLE_NAME||Q'[ TB1 where SUBSTR (TB1.VMX_ID,INSTR(TB1.VMX_ID,'/')+1) = TB0.G3E_FID)]'
                                        ||'WHERE G3E_FID  = '|| SUBSTR (V_IQGO_VMX_ID,INSTR(V_IQGO_VMX_ID,'/')+1)||';' ;
                  END IF;
                
                end if;
               
        end loop;
            V_FINAL_QUERY := ' begin '||V_FINAL_QUERY||' LTT_POST.post;     end;';
           --execute immediate V_FINAL_QUERY;
            dbms_output.put_line (V_FINAL_QUERY);
           
           V_FINAL_QUERY := null;
		   --EXECUTE IMMEDIATE  Q'[delete FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' ;
		   --commit;
        ELSIF V_CHANGE_TYPE =  'delete' THEN 
        PRC_POST_JOB  ( P_FNO, V_LTT_ID,V_JOB_ID ) ; 
        V_STRING1 := null;
        V_STRING := null;
        
        for rec0 in (SELECT  TC.G3E_TABLE ,TC.IS_MAIN_table,TC.TABLE_ALIAS,TC.G3E_CNO,tc.g3e_fno
                        FROM tb_components TC 
                        where TC.G3E_FNO = v_fno
						 --and TABLE_DELETE_ORDER IS NOT NULL
                      --  AND upper (TC.required) = 'Y'
                        order by TABLE_DELETE_ORDER 
                )
                
            loop
			
			 IF REC0.G3E_TABLE = 'B$GC_NETELEM' THEN
			   V_STRING := V_STRING||'ltt_user.setconfiguration('||''''||V_REGION||''''||');' ;
			END IF;
            
            V_STRING := V_STRING ||'DELETE FROM '||REC0.G3E_TABLE||' WHERE G3E_FNO = '||V_FNO||
                        Q'[ AND G3E_FID = ( SELECT SUBSTR (A.VMX_ID,INSTR(A.VMX_ID,'/')+1) AS G3E_FID from ]'
                        ||V_TMP_TABLE_NAME||' a where vmx_id = '||''''||V_IQGO_VMX_ID ||''''||') ;';
            
        end loop;
		V_STRING := 'ltt_user.setconfiguration('||''''||V_REGION||''''||');'||V_STRING ;
        V_FINAL_QUERY := ' begin '||V_STRING||' LTT_POST.post;     end;';
		execute immediate V_FINAL_QUERY;
         --dbms_output.put_line(V_FINAL_QUERY);
         V_FINAL_QUERY :=null;
		EXECUTE IMMEDIATE  Q'[delete FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' ;
      commit;
    END IF;

END LOOP;
CLOSE CUR_VMX_ID;
    P_STATUS := 'S';
EXCEPTION
    WHEN E_NOT_EXISTS THEN
    DBMS_OUTPUT.PUT_LINE ( V_ERR_MSG);
    rollback;
    P_STATUS := 'F';
    WHEN E_FEATURE_CHK THEN
    DBMS_OUTPUT.PUT_LINE ( 'G3E_FNO :'||V_FNO||' NOT EXISTS');
    P_STATUS := 'F';
    WHEN E_TB_NOT_EXISTS THEN
    DBMS_OUTPUT.PUT_LINE ( 'TEMP eTABLE '||V_TMP_TABLE_NAME ||' NOT EXISTS, KINDLY CHECK THE CSV FROM IQGEO RECEIVED OR NOT');
    P_STATUS := 'F';
    WHEN E_FID_EXISTS THEN
    DBMS_OUTPUT.PUT_LINE ( 'INSERT FAILED : IQGEO FID '||V_IQGO_VMX_ID ||' ALREADY EXISTS IN '||V_MAIN_TABLE||' OR IN TB_FID_GCOMMS_IQGEO TABLE');
    P_STATUS := 'F';
    --WHEN OTHERS THEN
    --P_STATUS := 'F';
end PRC_REVERSE_DATA_CONNECTER;
PROCEDURE PRC_REVERSE_MAIN (P_DML  IN VARCHAR2,
                                                   P_STATUS OUT VARCHAR2

)
AS

BEGIN
IF P_DML in ('insert','update') then
	FOR REC1 IN (SELECT G3E_FNO,FEATURE_NAME FROM TB_FEATURE where feature_order is not null and CATEGORY IN ('EQUIPMENT','STRUCTURE','CONDUIT','CABLE') ORDER BY feature_order)
	LOOP
	  PKG_DATA_CONNECTOR_REVERSE.PRC_REVERSE_DATA_CONNECTER
		( rec1.G3E_FNO ,   
		  P_dml,   
		  P_STATUS
		);
	END LOOP;
	
ELSIF P_DML ='delete' then 
FOR REC1 IN (SELECT G3E_FNO,FEATURE_NAME FROM TB_FEATURE where feature_order is not null and CATEGORY IN ('EQUIPMENT','STRUCTURE','CONDUIT','CABLE') ORDER BY feature_order desc)
	LOOP
	  PKG_DATA_CONNECTOR_REVERSE.PRC_REVERSE_DATA_CONNECTER
		( rec1.G3E_FNO ,   
		  P_dml,   
		  P_STATUS
		);
	END LOOP;
END IF;
END PRC_REVERSE_MAIN;

END PKG_DATA_CONNECTOR_REVERSE;

/
