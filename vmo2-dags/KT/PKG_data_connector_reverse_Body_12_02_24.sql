--------------------------------------------------------
--  File created - Monday-February-12-2024   
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
    DBMS_OUTPUT.PUT_LINE('j:'||j);
    exit when j = 0;

    t.extend();
    t(t.count) := to_number(substr(s,i,j-i));
     DBMS_OUTPUT.PUT_LINE('t:'||t(t.count));
    i := j+1;
  end loop;
       
       if p_fno = 2200 then
        V_GEOMETRY := SDO_CS.TRANSFORM(SDO_GEOMETRY(3002, 27700, NULL, SDO_ELEM_INFO_ARRAY(1, 2, 1),t),27700);
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
    ********************************************************************************************************/
    FUNCTION fun_get_wkb_reverse(P_ORIENTATION IN VARCHAR2,P_WKB in varchar2)
    RETURN sdo_geometry AS     
    v_radian number;    
    i number:=0;
    j number:=0;
    pi number := 3.14159265;
    flagCheck boolean;
    counter number;
    v_geometry sdo_geometry;
    BEGIN
        
        select tan((P_ORIENTATION * pi)/180) into v_radian from dual;
        j:=1;
        counter :=0;
        flagCheck := true;
        if P_ORIENTATION != 0 then
            while flagCheck loop
                j := j-0.001;
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
        SELECT sdo_cs.transform(SDO_GEOMETRY(2001, 8307, sdo_point_type(R.X,R.y, NULL), NULL, NULL), 27700)
        INTO v_geometry
        FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;

        SELECT SDO_GEOMETRY(3001, NULL, NULL, mdsys.sdo_elem_info_array(1, 1, 1, 4, 1, 0), mdsys.sdo_ordinate_array(R.X,R.y, 0, j, i, 0))
        INTO v_geometry
        FROM(SELECT X.X ,X.y,X.ID  FROM TABLE(sdo_util.getvertices (v_geometry))X)R;
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
	V_QUERY         VARCHAR2(4000);
    V_FINAL_QUERY   VARCHAR2 (32000);
    V_TMP_TABLE_NAME    VARCHAR2(200);
    V_TABLE_NAME    VARCHAR2(200);
    V_G3E_ID NUMBER;
	V_COLUMN_CNT    NUMBER;
    V_LTT_ID        NUMBER;
    V_JOB_ID        NUMBER;
    V_DETAILID    NUMBER;
    V_node_id       number;
    V_node_id_count number;
    V_node1_id number;
    V_node2_id number;
    V_FNO           NUMBER;
    V_TABLE_CNT     NUMBER;
	V_COLUMN_NAME   VARCHAR2(100);
    V_COLUMN_IQGO   VARCHAR2(100);
    V_COLUMN_value   VARCHAR2(500);
	V_MAIN_TABLE    VARCHAR2(50);
	V_VMX_ID        NUMBER;
    V_REGION        VARCHAR2(4);
    v_new_g3e_fid   number;
    V_IQGO_VMX_ID   VARCHAR2(500);
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
    


begin
        V_TMP_TABLE_NAME := pkg_data_connector.fun_table_name (p_FNO);
        IF p_fno = 12301 then
            V_FNO := 12300;
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
        FOR REC2 IN ( SELECT column_name,TABLE_NAME FROM SYS.all_tab_columns WHERE TABLE_NAME = V_TMP_TABLE_NAME)
        LOOP
            
            IF REC2.column_name in ('VMX_HOUSING','VMX_MANHOLE') THEN
               V_COLUMN_IQGO :=  REC2.column_name ;            
            
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
        EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM '||V_MAIN_TABLE||' WHERE G3E_FID = '||V_VMX_ID INTO V_FID_CNT;   
        
	    IF V_CHANGE_TYPE =  'insert'  THEN
            PRC_POST_JOB  ( V_FNO, V_LTT_ID,V_JOB_ID ) ;
       			SELECT count(1)
                INTO V_FID_CNT
                FROM TB_FID_GCOMMS_IQGEO GI
                WHERE GI.IQGEO_FID = V_IQGO_VMX_ID
                and g3e_fno = p_FNO;
                if V_FID_CNT = 0 then
                v_new_g3e_fid := G3E_FID_SEQ.nextval;
                  INSERT INTO TB_FID_GCOMMS_IQGEO(IQGEO_FID,GCOMMS_FID , G3E_FNO)
                  values (V_IQGO_VMX_ID,v_new_g3e_fid,p_fno);
                    
                    
                else                  
                      v_err_msg := 'INSERT FAILED : IQGEO FID '||V_IQGO_VMX_ID ||' ALREADY EXISTS IN '||V_MAIN_TABLE||' OR IN TB_FID_GCOMMS_IQGEO TABLE';
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
                                 ELSIF UPPER( REC1.DATA_EXCHANGE_FIELD) = ( 'VMX_LOCATION') AND P_FNO in (14900,2700) THEN
                                    v_string1 := v_string1||' pkg_data_connector_reverse.fun_get_wkb_reverse (VMX_ORIENTATION,'||REC1.DATA_EXCHANGE_FIELD||'),';
                                 ELSIF  UPPER( REC1.DATA_EXCHANGE_FIELD) IN ( 'VMX_LOCATION','VMX_LABEL_LOCATION') THEN
                                    v_string1 := v_string1||' pkg_data_connector_reverse.fun_get_wkb_reverse ('||REC1.DATA_EXCHANGE_FIELD||'),';
                                    
                                ELSIF UPPER(REC1.DATA_EXCHANGE_FIELD) IN ('VMX_BOUNDARY') THEN
                                    v_string1 := v_string1||' pkg_data_connector_reverse.fun_get_wkb_reverse_polygonTo3D ('||REC1.DATA_EXCHANGE_FIELD||','||P_FNO||'),';
                                ELSIF UPPER(REC1.DATA_EXCHANGE_FIELD) IN ('VMX_PATH') THEN
                                    v_string1 := v_string1||' pkg_data_connector_reverse.fun_get_wkb_reverse_polygonTo3D ('||REC1.DATA_EXCHANGE_FIELD||','||P_FNO||'),';
                                ELSE
                                   v_string1 := v_string1||REC1.DATA_EXCHANGE_FIELD||',';
                                END IF;
                            END IF;

                    end loop;     

    -- ADD MANDATORY COLUMNS
    v_string := 'G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID,'||v_string;
    -------------------------------------------
    v_string := RTRIM (v_string,',')||')';
    v_string := 'INSERT INTO '||REC0.G3E_TABLE||'( '||v_string;    

     -- ADD MANDATORY COLUMN VALUES
     v_string_mand := LTRIM(REC0.G3E_TABLE,'B$')||'_SEQ.NEXTVAL,'|| V_FNO||','||v_new_g3e_fid||','||REC0.G3E_CNO||',1,'||V_LTT_ID||',';
     ---------------------------------------------------------
     v_string1 := RTRIM (v_string1,',');
    -- V_QUERY := v_string1;
     v_string1 := 'SELECT '||nvl(v_string1,'null')||' FROM '||V_TMP_TABLE_NAME ||Q'{ A JOIN TB_FID_GCOMMS_IQGEO TF ON ( TF.IQGEO_FID = A.VMX_ID) AND TF.REVERSED='N' AND G3E_FNO =}'|| P_FNO ||' and vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
      v_null_chk_string := 'SELECT '||ltrim(nvl(v_null_chk_string,'null'),'||')||' FROM '||V_TMP_TABLE_NAME ||Q'{ A JOIN TB_FID_GCOMMS_IQGEO TF ON ( TF.IQGEO_FID = A.VMX_ID) AND TF.REVERSED='N' AND G3E_FNO =}'|| P_FNO ||' and vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
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
    elsif v_null_count = 0 and  REC0.G3E_TABLE in ( 'B$DGC_POLE_P','B$DGC_BLDG_P','B$DGC_CLOSURE_P') then
        V_QUERY := 'INSERT INTO '|| REC0.G3E_TABLE||' (G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID, G3E_DETAILID,G3E_GEOMETRY)' ;
        IF v_fno = 14100 THEN
         
        V_QUERY := V_QUERY || 'SELECT '||RTRIM(v_string_mand,',')||','||V_DETAILID||',PKG_DATA_CONNECTOR_REVERSE.fun_get_wkb_reverse_polygonTo3D(VMX_BOUNDARY,'||P_FNO||') FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
        
        ELSE
        V_QUERY := V_QUERY || 'SELECT '||RTRIM(v_string_mand,',')||','||V_DETAILID||',PKG_DATA_CONNECTOR_REVERSE.FUN_GET_POLYGON(PKG_DATA_CONNECTOR_REVERSE.fun_get_wkb_reverse(VMX_LOCATION),'||V_FNO||') FROM '||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''';
        END IF;
         
        
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
    else
        --DBMS_OUTPUT.PUT_LINE ('Not inserting into table '||REC0.G3E_TABLE||' : all rows to insert are null');
        V_QUERY := 'INSERT INTO '||REC0.G3E_TABLE||'( G3E_ID,G3E_FNO,G3E_FID,G3E_CNO,G3E_CID,LTT_ID )'||' VALUES ('||RTRIM(v_string_mand,',')||')';
       -- DBMS_OUTPUT.PUT_LINE(V_QUERY);
      end if;
       --DBMS_OUTPUT.PUT_LINE(V_COLUMN_IQGO);
      IF V_COLUMN_IQGO = 'VMX_HOUSING' and UPPER( REC0.G3E_TABLE) in ('B$GC_OWNERSHIP','B$GC_ISP_OWNERSHIP') THEN
      
    EXECUTE IMMEDIATE  Q'[SELECT  PKG_DATA_CONNECTOR_REVERSE.FUN_GET_GCOMS_FID (VMX_HOUSING) FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' into V_COLUMN_value;     
      IF V_COLUMN_value IS NOT NULL THEN
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
    END IF;
  
   END IF;


--DBMS_OUTPUT.PUT_LINE(v_query);

   IF REC0.G3E_TABLE = 'B$GC_NETELEM' THEN

       V_FINAL_QUERY := V_FINAL_QUERY||'ltt_user.setconfiguration('||''''||V_REGION||''''||');' ;
    END IF;
   V_FINAL_QUERY := V_FINAL_QUERY|| V_QUERY||';' ;
   IF REC0.G3E_TABLE = 'B$GC_NETELEM' THEN

       V_FINAL_QUERY := V_FINAL_QUERY||' update b$gc_netelem set region = ' ||''''||V_REGION||''''||' where g3e_fid = '|| v_new_g3e_fid||';';
    END IF;
     end loop;
      
          V_FINAL_QUERY:= ' begin '|| V_FINAL_QUERY||' LTT_POST.post;     end;';
     EXECUTE IMMEDIATE V_FINAL_QUERY;
    --DBMS_OUTPUT.PUT_LINE(V_FINAL_QUERY);
      V_FINAL_QUERY := null;
      --ROLLBACK;
       EXECUTE IMMEDIATE  Q'[delete FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' ;
      commit;
    ELSIF V_CHANGE_TYPE =  'update' THEN 
        PRC_POST_JOB  ( v_FNO, V_LTT_ID,V_JOB_ID ) ; 
        for rec0 in (SELECT  TC.G3E_TABLE ,TC.IS_MAIN_table,TC.TABLE_ALIAS,TC.G3E_CNO,tc.g3e_fno
                        FROM tb_components TC 
                        where TC.G3E_FNO = v_fno
                        AND upper (TC.required) = 'Y'
                        order by table_order
                )
            loop
             V_STRING1 := null;
            V_STRING := null;
              for rec1 in ( select DM.COLUMN_NAME,DM.DATA_EXCHANGE_FIELD 
                            from data_mapping dm
                            where g3e_fno = rec0.g3e_fno
                            and table_name = rec0.g3e_table
                             AND DM.DATA_EXCHANGE_FIELD is not null
                             and upper(dm.DATA_EXCHANGE_FIELD) NOT in( 'VMX_ID','VMX_REGION','VMX_ORIENTATION','VMX_CHANGE_TYPE','DATE_INSTALLED','VMX_MANHOLE','VMX_HOUSING','VMX_N_FIBER_PORTS','VMX_N_FIBER_OUT_PORTS')
                             )
                loop
                   v_query :=  'SELECT COUNT(1) AS COL FROM '||V_TMP_TABLE_NAME||' where vmx_id = '||''''||V_IQGO_VMX_ID ||''''||' AND ' ||REC1.DATA_EXCHANGE_FIELD||' IS NOT NULL';
                    execute immediate v_query into v_count; 
                    
                    IF v_count <> 0 and UPPER( REC1.DATA_EXCHANGE_FIELD) = ( 'VMX_LOCATION') AND P_FNO in (14900,2700) THEN
                        V_STRING := V_STRING||rec1.column_name||',';
                        V_STRING1 := V_STRING1||' pkg_data_connector_reverse.fun_get_wkb_reverse (VMX_ORIENTATION,'||REC1.DATA_EXCHANGE_FIELD||'),';
                    
                    ELSIF  v_count <> 0 and UPPER( REC1.DATA_EXCHANGE_FIELD) IN ( 'VMX_LOCATION','VMX_LABEL_LOCATION') THEN 
                        V_STRING := V_STRING||rec1.column_name||',';
                        V_STRING1 := V_STRING1||' pkg_data_connector_reverse.fun_get_wkb_reverse ( '||REC1.DATA_EXCHANGE_FIELD||'),';
                    
                    ELSIF v_count <> 0 and UPPER( REC1.DATA_EXCHANGE_FIELD) IN ( 'VMX_BOUNDARY') THEN
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

                
                if V_STRING is not null then
                   V_FINAL_QUERY := V_FINAL_QUERY ||'UPDATE '||rec0.G3E_TABLE||' TB0 SET ('||V_STRING||'LTT_ID ) =( SELECT '||V_STRING1||V_LTT_ID||
                                    ' FROM '||V_TMP_TABLE_NAME||Q'[ TB1 where SUBSTR (TB1.VMX_ID,INSTR(TB1.VMX_ID,'/')+1) = TB0.G3E_FID)]'
                                    ||'WHERE G3E_FID  = '|| SUBSTR (V_IQGO_VMX_ID,INSTR(V_IQGO_VMX_ID,'/')+1)||';' ;
                  
                
                end if;
               
        end loop;
            V_FINAL_QUERY := ' begin '||V_FINAL_QUERY||' LTT_POST.post;     end;';
           execute immediate V_FINAL_QUERY;
            --dbms_output.put_line (V_FINAL_QUERY);
           
           V_FINAL_QUERY := null;
		   EXECUTE IMMEDIATE  Q'[delete FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' ;
        ELSIF V_CHANGE_TYPE =  'delete' THEN 
        PRC_POST_JOB  ( P_FNO, V_LTT_ID,V_JOB_ID ) ; 
        V_STRING1 := null;
        V_STRING := null;
        
        for rec0 in (SELECT  TC.G3E_TABLE ,TC.IS_MAIN_table,TC.TABLE_ALIAS,TC.G3E_CNO,tc.g3e_fno
                        FROM tb_components TC 
                        where TC.G3E_FNO = v_fno
                      --  AND upper (TC.required) = 'Y'
                        order by table_order DESC
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
		--execute immediate V_FINAL_QUERY;
         dbms_output.put_line(V_FINAL_QUERY);
         V_FINAL_QUERY :=null;
		--EXECUTE IMMEDIATE  Q'[delete FROM ]'||V_TMP_TABLE_NAME ||' WHERE vmx_ID = '||''''||V_IQGO_VMX_ID||'''' ;
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
	FOR REC1 IN (SELECT G3E_FNO,FEATURE_NAME FROM TB_FEATURE where feature_order is not null and CATEGORY IN ('EQUIPMENT','STRUCTURE') ORDER BY feature_order)
	LOOP
	  PKG_DATA_CONNECTOR_REVERSE.PRC_REVERSE_DATA_CONNECTER
		( rec1.G3E_FNO ,   
		  P_dml,   
		  P_STATUS
		);
	END LOOP;
	
ELSIF P_DML ='delete' then 
FOR REC1 IN (SELECT G3E_FNO,FEATURE_NAME FROM TB_FEATURE where feature_order is not null and CATEGORY IN ('EQUIPMENT','STRUCTURE') ORDER BY feature_order desc)
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
