create or replace PACKAGE BODY PKG_DATA_CONNECTOR AS
/***************************************************************************************************************************************************
** Name        : PKG_DATA_CONNECTOR
** Description : Generate scripts based on the DATA_MAPPING table for provided feature number
** Created by  : Thushar Chandran
****************************************************************************************************************************************************
** Change History
****************************************************************************************************************************************************
** Version                                           Date      Developer             Ticket#: Comment 
----------------------------------------------------------------------------------------------------------------------------------------------------------
**0.1                                              22/09/2023    SANTHOSH        CHANGES IN (PRC_MIG_GCOMS_FEATURE)--ADDED NEW CONDTION (VMX_LABEL_ORIENTATION,VMX_HOUSINGS,VMX_VALIDATED)
**0.1                                              25/09/2023    SANTHOSH        ADDED NEW FUNCATION fun_get_out_equip(),  SAME LOGIC AS fun_get_in_equip()
**0.1                                              27/09/2023    SANTHOSH        CHANGES IN (PRC_MIG_GCOMS_FEATURE)--ADDED NEW CONDTION FOR fun_get_in_equip AND fun_get_out_equip
**0.1                                              27/09/2023    SANTHOSH        ADDED NEW FUNCATION LOGIC FOR  fun_get_num_duct()
**0.1                                              03/10/2023    SANTHOSH        ADDED NEW FUNCATION LOGIC FOR  fun_get_fiber_ports()
**0.1                                              22/11/2023    Thushar Chandran Procedure PRC_CDC_PROCESS added for CDC process script generation
**0.1                                              01/12/2023    SANTHOSH        Implemented the reminding 8 features logic to Procedure PRC_CDC_PROCESS
**0.1                                              13/02/2024    SANTHOSH        changed g3e_fid to g3e_id for vmx_id (fiber_cable_label,fiber slack,fiber) as per customer's requirement 
****************************************************************************************************************************************************/
/***************************************************************************************************************************************************************************************888
** PRC_GET_INSRT_DEL_PORTS : To find the deleted and inserted ports for connections after posting the job
** created by : Thushar Chandran
***************************************************************************************************************************************************************************/
PROCEDURE PRC_GET_INSRT_DEL_PORTS AS

        V_COUNT  NUMBER;
        V_CNT    NUMBER;
        V_COUNT1 NUMBER;
        V_PORT   NUMBER;
        V_INLOW  NUMBER;
        V_INHIGH NUMBER;
        V_CNO    NUMBER := 0;
    BEGIN
       DELETE FROM VMESDEV.TB_SPLICE_CONNECT A
        WHERE LTT_STATUS IN ('insert','delete');

    UPDATE VMESDEV.TB_SPLICE_CONNECT A
     SET LTT_STATUS = LTRIM (LTT_STATUS,'I')
    WHERE LTT_STATUS LIKE 'I%';

     UPDATE VMESDEV.TB_SPLICE_CONNECT A
     SET LTT_STATUS ='I'||LTT_STATUS
     WHERE EXISTS (SELECT 1 FROM B$GC_SPLICE_CONNECT WHERE G3E_ID = A.G3E_ID AND LTT_STATUS IS NOT NULL)
     AND G3E_ID IS NOT NULL;
        commit;
        FOR REC1 IN (
                SELECT DISTINCT
                B.G3E_FNO,
                B.IN_FTYPE,
                B.G3E_FID,
                B.IN_FID,
                B.IN_LOW,
                B.IN_HIGH,
                B.OUT_FTYPE,
                B.OUT_FID,
                B.OUT_LOW,
                B.OUT_HIGH
            FROM
                TB_SPLICE_CONNECT B
            WHERE
                LTT_STATUS = 'LTTDEL'
        ) LOOP
            SELECT
                COUNT(1)
            INTO V_COUNT
            FROM
                B$GC_SPLICE_CONNECT A
            WHERE
                    A.G3E_FID = REC1.G3E_FID
                AND A.IN_FID = REC1.IN_FID
                AND REC1.IN_LOW BETWEEN A.IN_LOW AND A.IN_HIGH
                AND REC1.OUT_LOW BETWEEN A.OUT_LOW AND A.OUT_HIGH;

            IF V_COUNT = 0 THEN
                INSERT INTO TB_SPLICE_CONNECT (
                        G3E_FNO,
                    G3E_FID,
                    IN_FTYPE,
                    IN_FID,
                    IN_LOW,
                    IN_HIGH,
                    OUT_FTYPE,
                    OUT_FID,
                    OUT_LOW,
                    OUT_HIGH,
                    LTT_STATUS
                ) VALUES (
                        REC1.G3E_FNO,
                    REC1.G3E_FID,
                    REC1.IN_FTYPE,
                    REC1.IN_FID,
                    REC1.IN_LOW,
                    REC1.IN_HIGH,
                    REC1.OUT_FTYPE,
                    REC1.OUT_FID,
                    REC1.OUT_LOW,
                    REC1.OUT_HIGH,
                    'delete'
                );

            END IF;

        END LOOP;

        FOR REC1 IN (
                SELECT
                B.G3E_FNO,
                B.G3E_FID,
                B.IN_FTYPE,
                B.IN_FID,
                B.IN_LOW,
                B.IN_HIGH,
                B.OUT_FTYPE,
                B.OUT_FID,
                B.OUT_LOW,
                B.OUT_HIGH,
                MAX(A.IN_HIGH)  INHIGH,
                MAX(A.OUT_HIGH) OUTHIGH,
                MIN(A.IN_LOW)   INLOW,
                MIN(A.OUT_LOW)  OUTLOW
            FROM
                B$GC_SPLICE_CONNECT A,
                TB_SPLICE_CONNECT   B
            WHERE
                    A.G3E_FID = B.G3E_FID
                AND A.IN_FID = B.IN_FID
                AND ( B.IN_HIGH BETWEEN A.IN_LOW AND A.IN_HIGH
                      OR B.IN_LOW BETWEEN A.IN_LOW AND A.IN_HIGH )
                AND B.LTT_STATUS <> 'delete'
            GROUP BY
                B.G3E_FNO,
                B.G3E_FID,
                B.IN_FTYPE,
                B.IN_FID,
                B.IN_LOW,
                B.IN_HIGH,
                B.OUT_FTYPE,
                B.OUT_FID,
                B.OUT_LOW,
                B.OUT_HIGH
            UNION
            SELECT DISTINCT
                B.G3E_FNO,
                B.G3E_FID,
                B.IN_FTYPE,
                B.IN_FID,
                B.IN_LOW,
                B.IN_HIGH,
                B.OUT_FTYPE,
                B.OUT_FID,
                B.OUT_LOW,
                B.OUT_HIGH,
                B.IN_HIGH  AS INHIGH,
                B.OUT_HIGH OUTHIGH,
                B.IN_LOW   INLOW,
                B.OUT_LOW  OUTLOW
            FROM
                B$GC_SPLICE_CONNECT A,
                TB_SPLICE_CONNECT   B
            WHERE
                    A.G3E_FID = B.G3E_FID
                AND A.IN_FID = B.IN_FID
                AND ( B.IN_HIGH NOT BETWEEN A.IN_LOW AND A.IN_HIGH
                      AND B.IN_LOW NOT BETWEEN A.IN_LOW AND A.IN_HIGH )
                AND B.LTT_STATUS <> 'delete'
        ) LOOP
            IF REC1.INLOW >= REC1.IN_LOW THEN
                V_INLOW := REC1.IN_LOW;
                V_PORT := REC1.OUT_LOW;
            ELSE
                V_INLOW := REC1.INLOW;
                V_PORT := REC1.OUTLOW;
            END IF;

            IF REC1.INHIGH < REC1.IN_HIGH THEN
                V_INHIGH := REC1.IN_HIGH;
            ELSE
                V_INHIGH := REC1.INHIGH;
            END IF;

            FOR REC IN V_INLOW..V_INHIGH LOOP
                SELECT
                    COUNT(1)
                INTO V_COUNT
                FROM
                    TB_SPLICE_CONNECT A
                WHERE
                        A.G3E_FID = REC1.G3E_FID
                    AND A.IN_FID = REC1.IN_FID
                    AND REC BETWEEN IN_LOW AND IN_HIGH
                    AND LTT_STATUS IN ( 'delete' );


                IF V_COUNT = 0 THEN
                    V_CNO := V_CNO + 1;
                    SELECT
                        COUNT(1)
                    INTO V_COUNT1
                    FROM
                        TB_SPLICE_CONNECT
                    WHERE
                            G3E_FID = REC1.G3E_FID
                        AND IN_FID = REC1.IN_FID
                        AND REC BETWEEN IN_LOW AND IN_HIGH
                        AND LTT_STATUS NOT IN ( 'insert', 'delete' );

                    SELECT
                        COUNT(1)
                    INTO V_COUNT
                    FROM
                        B$GC_SPLICE_CONNECT A
                    WHERE
                            A.G3E_FID = REC1.G3E_FID
                        AND A.IN_FID = REC1.IN_FID
                        AND REC BETWEEN A.IN_LOW AND A.IN_HIGH
                        AND V_PORT BETWEEN A.OUT_LOW AND A.OUT_HIGH;

                    DBMS_OUTPUT.PUT_LINE(V_COUNT
                                         || ','
                                         || REC);
                    IF V_COUNT = 0 THEN
                        DBMS_OUTPUT.PUT_LINE('INSERTED DEL');
                        INSERT INTO TB_SPLICE_CONNECT (
                                G3E_FNO,
                            G3E_FID,
                            IN_FTYPE,
                            IN_FID,
                            IN_LOW,
                            IN_HIGH,
                            OUT_FTYPE,
                            OUT_FID,
                            OUT_LOW,
                            OUT_HIGH,
                            LTT_STATUS
                        ) VALUES (
                                REC1.G3E_FNO,
                            REC1.G3E_FID,
                            REC1.IN_FTYPE,
                            REC1.IN_FID,
                            REC,
                            REC,
                            REC1.OUT_FTYPE,
                            REC1.OUT_FID,
                            V_PORT,
                            V_PORT,
                            'delete'
                        );

                    ELSIF
                        V_COUNT > 0
                        AND V_COUNT1 = 0
                    THEN
                        INSERT INTO TB_SPLICE_CONNECT (
                                G3E_FNO,
                            G3E_FID,
                            IN_FTYPE,
                            IN_FID,
                            IN_LOW,
                            IN_HIGH,
                            OUT_FTYPE,
                            OUT_FID,
                            OUT_LOW,
                            OUT_HIGH,
                            LTT_STATUS
                        ) VALUES (
                                REC1.G3E_FNO,
                            REC1.G3E_FID,
                            REC1.IN_FTYPE,
                            REC1.IN_FID,
                            REC,
                            REC,
                            REC1.OUT_FTYPE,
                            REC1.OUT_FID,
                            V_PORT,
                            V_PORT,
                            'insert'
                        );

                    END IF;

                END IF;

                V_PORT := V_PORT + 1;
            END LOOP;
   ------ for cross connection insert
            SELECT
                COUNT(1)
            INTO V_COUNT
            FROM
                TB_SPLICE_CONNECT A
            WHERE
                    A.G3E_FID = REC1.G3E_FID
                AND A.IN_FID = REC1.IN_FID
                AND LTT_STATUS IN ( 'LTTOLD', 'LTTDEL' )
                AND IN_LOW = REC1.IN_LOW
                AND A.OUT_LOW = REC1.OUT_LOW
                AND ( IN_LOW <> REC1.INLOW
                      OR OUT_LOW <> REC1.OUTLOW );

            IF V_COUNT = 2 THEN
                INSERT INTO TB_SPLICE_CONNECT (
                        G3E_FNO,
                    G3E_FID,
                    IN_FTYPE,
                    IN_FID,
                    IN_LOW,
                    IN_HIGH,
                    OUT_FTYPE,
                    OUT_FID,
                    OUT_LOW,
                    OUT_HIGH,
                    LTT_STATUS
                ) VALUES (
                        REC1.G3E_FNO,
                    REC1.G3E_FID,
                    REC1.IN_FTYPE,
                    REC1.IN_FID,
                    REC1.INLOW,
                    REC1.INHIGH,
                    REC1.OUT_FTYPE,
                    REC1.OUT_FID,
                    REC1.OUTLOW,
                    REC1.OUTHIGH,
                    'insert'
                );

            END IF;

        END LOOP;
------- FOR ADD
/*       FOR REC2 IN (
                SELECT
                MODIFICATIONNUMBER,
                TYPE,
                G3E_FNO,
                G3E_ID,
                G3E_FID,
                'P' PROCESSED
            FROM
                GAO_FIBERTABLEMODLOG MF
            WHERE
                    TO_DATE(MODIFIEDDATE, 'DD-MON-YYYY') >= TO_DATE(SYSDATE - 1, 'DD-MON-YYYY')
                AND MF.LTT_MODE = 'POST'
                AND MF.TYPE = 3
                AND ( TABLENAME = 'GC_SPLICE_CONNECT' )
                AND NOT EXISTS (
                        SELECT
                        1
                    FROM
                        TB_CDC_PROCESS CP
                    WHERE
                        CP.MODIFICATIONNUMBER = MF.MODIFICATIONNUMBER
                )
        ) LOOP
            INSERT INTO TB_CDC_PROCESS (
                    MODIFICATIONNUMBER,
                TYPE,
                G3E_FNO,
                G3E_FID,
                PROCESSED
            ) VALUES (
                    REC2.MODIFICATIONNUMBER,
                REC2.TYPE,
                REC2.G3E_FNO,
                REC2.G3E_ID,
                REC2.PROCESSED
            );

            IF REC2.G3E_FNO IS NOT NULL THEN
                INSERT INTO TB_SPLICE_CONNECT (
                        G3E_FNO,
                    G3E_FID,
                    IN_FTYPE,
                    IN_FID,
                    IN_LOW,
                    IN_HIGH,
                    OUT_FTYPE,
                    OUT_FID,
                    OUT_LOW,
                    OUT_HIGH,
                    LTT_STATUS
                )
                    SELECT
                        G3E_FNO,
                        G3E_FID,
                        IN_FTYPE,
                        IN_FID,
                        IN_LOW,
                        IN_HIGH,
                        OUT_FTYPE,
                        OUT_FID,
                        OUT_LOW,
                        OUT_HIGH,
                        'insert'
                    FROM
                        B$GC_SPLICE_CONNECT A
                    WHERE
                            G3E_ID = REC2.G3E_ID
                        AND G3E_FID = REC2.G3E_FID;

            END IF;

        END LOOP;
*/
    FOR REC2 IN (
                SELECT A.*
            FROM 
            B$GC_SPLICE_CONNECT A,TB_SPLICE_CONNECT B
            WHERE A.G3E_ID= B.G3E_ID
            AND B.LTT_STATUS = 'ADD'

        ) LOOP
            SELECT count(1)
            into V_COUNT
            FROM  TB_SPLICE_CONNECT
            WHERE G3E_FID = REC2.G3E_FID
            AND IN_FID = REC2.IN_FID
            AND REC2.IN_LOW BETWEEN IN_LOW AND IN_HIGH
            AND LTT_STATUS LIKE 'LTT%';

            IF V_COUNT = 0 THEN
                INSERT INTO TB_SPLICE_CONNECT (
                        G3E_FNO,
                    G3E_FID,
                    IN_FTYPE,
                    IN_FID,
                    IN_LOW,
                    IN_HIGH,
                    OUT_FTYPE,
                    OUT_FID,
                    OUT_LOW,
                    OUT_HIGH,
                    LTT_STATUS
                )
              VALUES (     
                        REC2.G3E_FNO,
                    REC2.G3E_FID,
                    REC2.IN_FTYPE,
                    REC2.IN_FID,
                    REC2.IN_LOW,
                    REC2.IN_HIGH,
                    REC2.OUT_FTYPE,
                    REC2.OUT_FID,
                    REC2.OUT_LOW,
                    REC2.OUT_HIGH,
                     'insert'
                     );                  
            END IF;

        END LOOP;
        DELETE FROM TB_SPLICE_CONNECT A
        WHERE
                A.LTT_STATUS = 'insert'
            AND EXISTS (
                    SELECT
                    1
                FROM
                    TB_SPLICE_CONNECT
                WHERE
                    LTT_STATUS IN ( 'LTTOLD' )
                    AND A.IN_LOW BETWEEN IN_LOW AND IN_HIGH
                    AND G3E_FID = A.G3E_FID
            )
            AND NOT EXISTS (
                    SELECT
                    1
                FROM
                    TB_SPLICE_CONNECT B
                WHERE
                    LTT_STATUS IN ( 'delete' )
                    AND A.IN_LOW BETWEEN IN_LOW AND IN_HIGH
                    AND G3E_FID = A.G3E_FID
            );

        DELETE FROM TB_SPLICE_CONNECT A
        WHERE
            A.LTT_STATUS LIKE  'LTT%'
        OR  A.LTT_STATUS = 'ADD';

            DELETE FROM TB_ID_TRACKER WHERE G3E_FNO IN(11801,11802,11803,11804);
/***************************************************************************************************************************************
IN OORDER TO ELIMNATE THE TOTAL RANGE ROWS WHICH IS COMING AS DUPLICATE
****************************************************************************************************************************************/
            DELETE FROM TB_SPLICE_CONNECT A
            WHERE
            A.IN_LOW <> A.IN_HIGH
            AND EXISTS (
                    SELECT
                    1
                    FROM
                    TB_SPLICE_CONNECT B
                    WHERE
                    B.G3E_FID = A.G3E_FID
                    AND B.IN_FID = A.IN_FID
                    AND B.IN_LOW = A.IN_LOW
                    AND B.IN_HIGH = A.IN_LOW
                        );
            COMMIT;

    END PRC_GET_INSRT_DEL_PORTS;
/*********************************************************************************************************************************************************
**  PRC_CDC_PROCESS : This procedure will check the DML operation happened for FIDs under each feature for current date and generate script for CDC process
*****************************************************************************************************************************************/
PROCEDURE PRC_CDC_PROCESS (p_OUT_QUERY  OUT  NOCOPY VARCHAR2 )
AS
   V_CDC_COUNT      NUMBER;  
   V_OUT_QUERY      VARCHAR2(32767);--VARCHAR2(32767);
   V_DELETE_QUERY  VARCHAR2(32767);
   V_INSERT_QUERY  VARCHAR2(32767);
   V_FIDS          VARCHAR2(32767);
   V_DML            VARCHAR2(10);
   V_FNO            NUMBER;
   V_G3E_ID                       VARCHAR2(5000);
   v_fids_del      varchar2(5000);
BEGIN

/* CURSOR for puling all the feature number to check any DML happened in modificationlog table */
    FOR REC0 IN (SELECT * FROM
                              (SELECT DISTINCT F.G3E_FNO AS REF_FNO
                                FROM TB_FEATURE F
                                join modificationlog MF on (f.g3e_fno = FUN_GET_CDC_DEFAULT_FNO(mf.g3e_fno,F.G3E_FNO,MF.MODIFIEDDATE))
                                WHERE  F.G3E_PRIORITY IS NOT NULL
                                                                                                                        and category != 'CONNECTIONS'
                                                                                                                        AND F.G3E_FNO NOT IN (7203,7202,7201)
                                AND TO_DATE(MODIFIEDDATE,'DD-MON-YYYY') >= TO_DATE(SYSDATE-1,'DD-MON-YYYY')
                                AND mf.ltt_id = 0            
                                AND  NOT EXISTS ( SELECT 1 FROM TB_CDC_PROCESS CP
                                                  WHERE CP.MODIFICATIONNUMBER  = MF.MODIFICATIONNUMBER
                                                  AND CP.G3E_FNO= F.G3E_FNO
                                                  AND PROCESSED IN ('Y','P','D')
                                                  )
                               ORDER BY 1
                               )
                        WHERE ROWNUM =1
               )
  LOOP
                              --dbms_output.put_line(REC0.REF_FNO);

        V_FIDS := NULL;
        V_OUT_QUERY := null;
        V_DELETE_QUERY := NULL;
        V_INSERT_QUERY:= NULL;
                              V_G3E_ID := NULL;
                              v_fids_del:=NULL;


        /* this cursor will pull only the rows from modification log table based on the modificationnumber for which cdc process not done for current date  */
        FOR REC1 IN (SELECT MODIFICATIONNUMBER,TYPE, G3E_FNO,G3E_ID,G3E_FID,MODIFIEDDATE,ROW_NUMBER() OVER (PARTITION BY G3E_FNO,TYPE,G3E_FID ORDER BY MODIFICATIONNUMBER DESC ) NUM,
                    ROW_NUMBER() OVER (PARTITION BY G3E_FNO,TYPE,G3E_ID ORDER BY MODIFICATIONNUMBER DESC ) NUM1
                        FROM modificationlog MF
                        WHERE  TO_DATE(MODIFIEDDATE,'DD-MON-YYYY') >= TO_DATE(SYSDATE-1,'DD-MON-YYYY')
                        AND MF.LTT_ID = 0
                        AND EXISTS (SELECT 1 FROM modificationlog ML
                                         WHERE ML.MODIFICATIONNUMBER  = MF.MODIFICATIONNUMBER
                                                AND FUN_GET_CDC_DEFAULT_FNO(ML.g3e_fno,REC0.REF_FNO,MF.MODIFIEDDATE)= REC0.REF_FNO
                                                )
                                         AND  NOT EXISTS ( SELECT 1 FROM TB_CDC_PROCESS CP
                                                         WHERE CP.MODIFICATIONNUMBER  = MF.MODIFICATIONNUMBER
                                                                AND CP.G3E_FNO= REC0.REF_FNO
                                                                AND PROCESSED IN ('Y','P','D')
                                         )
                       )
          LOOP
            BEGIN
                  SELECT COUNT(1)
                  INTO V_CDC_COUNT
                  FROM TB_CDC_PROCESS
                  WHERE MODIFICATIONNUMBER = REC1.MODIFICATIONNUMBER
                  AND G3E_FNO = REC0.REF_FNO;                 
                   --DBMS_OUTPUT.PUT_LINE(V_CDC_COUNT||','||REC0.REF_FNO||','||rEC1.NUM1||'FIRST NUM'||REC1.NUM);

                  IF V_CDC_COUNT = 0 AND (REC1.NUM = 1 OR  (REC1.NUM1 = 1 AND REC0.REF_FNO IN (7201,7202))) THEN -- To track the feature and fid which is under Process
                    IF  REC0.REF_FNO IN (7201,7202) AND V_CDC_COUNT = 0 AND REC1.NUM1 = 1 THEN
                                                                                          INSERT INTO TB_CDC_PROCESS (MODIFICATIONNUMBER,TYPE,G3E_FNO, G3E_FID,PROCESSED)
                                                                                          VALUES (REC1.MODIFICATIONNUMBER,REC1.TYPE,REC0.REF_FNO,REC1.G3E_ID,'P');
                                                                           ELSE
                                                                                          INSERT INTO TB_CDC_PROCESS (MODIFICATIONNUMBER,TYPE,G3E_FNO, G3E_FID,PROCESSED)
                                                                                          VALUES (REC1.MODIFICATIONNUMBER,REC1.TYPE,REC0.REF_FNO,REC1.G3E_FID,'P');
                                                                           END IF;
                     IF REC1.TYPE IN ('3','2') AND REC1.NUM = 1 AND V_FIDS IS NULL THEN ---- To track the feature and fid once script is generated for cdc process with status Y
                         PKG_DATA_CONNECTOR.PRC_MIG_GCOMS_FEATURE(REC0.REF_FNO,NULL,'insert',V_OUT_QUERY);-- generate scripts
                         IF REC0.REF_FNO IN (11802,11803) THEN
                            V_INSERT_QUERY := replace (V_OUT_QUERY,q'['insert']','PKG_DATA_CONNECTOR.fun_get_cdc_type('||REC0.REF_FNO||',tb0.in_fid)');
                         ELSIF REC0.REF_FNO IN (7201,7202) THEN
                                                                                                         V_INSERT_QUERY := replace (V_OUT_QUERY,q'['insert']','PKG_DATA_CONNECTOR.fun_get_cdc_type('||REC0.REF_FNO||',tb0.g3e_id)');
                                                                                          ELSE
                            V_INSERT_QUERY := replace (V_OUT_QUERY,q'['insert']','PKG_DATA_CONNECTOR.fun_get_cdc_type('||REC0.REF_FNO||',tb0.g3e_fid)');
                         END IF;
                         V_FIDS := REC1.G3E_FID;                    
                    ELSIF REC1.TYPE IN ('3','2') AND REC1.NUM = 1 AND V_FIDS IS NOT NULL THEN
                            V_FIDS := V_FIDS||','||REC1.G3E_FID;                    
                    ELSIF REC1.TYPE IN ('1') AND REC1.NUM = 1 THEN
                                                                           --DBMS_OUTPUT.PUT_LINE(REC1.TYPE ||V_G3E_ID);
                                                                                                         IF REC0.REF_FNO IN (7201,7202) THEN    
                                IF  V_G3E_ID IS  NULL then
                                    V_G3E_ID := PKG_DATA_CONNECTOR.fun_get_id(REC0.REF_FNO,REC1.G3E_FID,TO_DATE(REC1.MODIFIEDDATE));
                                                                                                                        PKG_DATA_CONNECTOR.PRC_MIG_GCOMS_FEATURE(REC0.REF_FNO,NULL,'delete',V_OUT_QUERY);
                                                                                                                                       V_OUT_QUERY := REPLACE (V_OUT_QUERY,'fun_get_vmx_id (','fun_get_vmx_id (g3e_fid');
                                    V_DELETE_QUERY := V_OUT_QUERY;
                                END IF;
                                V_G3E_ID := V_G3E_ID||','|| PKG_DATA_CONNECTOR.fun_get_id(REC0.REF_FNO,REC1.G3E_FID,TO_DATE(REC1.MODIFIEDDATE));
                                                                                          ELSE

                            IF v_fids_del IS NULL THEN
                                PKG_DATA_CONNECTOR.PRC_MIG_GCOMS_FEATURE(REC0.REF_FNO,NULL,'delete',V_OUT_QUERY);
                                                                                                                        V_OUT_QUERY := REPLACE (V_OUT_QUERY,'fun_get_vmx_id (','fun_get_vmx_id (g3e_fid');
                                V_DELETE_QUERY := V_OUT_QUERY;
                            END IF;
                            v_fids_del := v_fids_del||','||REC1.G3E_FID;
                                                                                          END IF;

                        -- UPDATE TB_CDC_PROCESS
                         --   SET PROCESSED = 'Y'
                         --   WHERE MODIFICATIONNUMBER = REC1.MODIFICATIONNUMBER;
                           -- COMMIT;
                            V_OUT_QUERY := null;

                    END IF;


                  ELSIF V_CDC_COUNT = 0 AND (REC1.NUM <> 1 OR (REC1.NUM1<> 1 AND REC0.REF_FNO IN (7201,7202)))  THEN -- To track the feature and fid which is Duplicate
                                                                           IF REC0.REF_FNO IN (7201,7202) AND REC1.NUM1 <> 1 THEN
                                                                                          INSERT INTO TB_CDC_PROCESS (MODIFICATIONNUMBER,TYPE,G3E_FNO, G3E_FID,PROCESSED)
                                                                                          VALUES (REC1.MODIFICATIONNUMBER,REC1.TYPE,REC0.REF_FNO,REC1.G3E_ID,'D');
                                                                           ELSE
                                                                                           INSERT INTO TB_CDC_PROCESS (MODIFICATIONNUMBER,TYPE,G3E_FNO, G3E_FID,PROCESSED)
                                                                                          VALUES (REC1.MODIFICATIONNUMBER,REC1.TYPE,REC0.REF_FNO,REC1.G3E_FID,'D');
                                                                           END IF;
                  END IF;
                                                            COMMIT;

           EXCEPTION
                WHEN OTHERS THEN
                --DBMS_OUTPUT.PUT_LINE(LENGTH (V_OUT_QUERY));
                UPDATE tb_cdc_process
                SET processed = 'E'
                WHERE MODIFICATIONNUMBER = REC1.MODIFICATIONNUMBER;
                COMMIT;
            END;


          END LOOP;
          IF V_DELETE_QUERY IS NOT NULL THEN
            IF  REC0.REF_FNO IN (7201,7202) THEN
                V_DELETE_QUERY := V_DELETE_QUERY||q'[ where PROCESSED IN ('P') and type = '1' AND   G3E_FID IN (]'||LTRIM(V_G3E_ID,',')||')';
            ELSE
                V_DELETE_QUERY := V_DELETE_QUERY||q'[ where PROCESSED IN ('P') AND type = '1' and G3E_FID IN (]'||LTRIM(v_fids_del,',')||')';
            END IF;
            --DBMS_OUTPUT.PUT_LINE(V_DELETE_QUERY);
          END IF;

          if V_DELETE_QUERY IS NOT NULL AND  V_INSERT_QUERY IS NOT NULL THEN
            IF REC0.REF_FNO  IN(11802,11803) THEN
                    V_INSERT_QUERY :=  REPLACE (V_INSERT_QUERY,'ORDER BY G3E_ID,LVL) TB0',' AND TB0.g3e_FID IN (')|| V_FIDS|| ') ORDER BY G3E_ID,LVL) TB0';
              ELSE
                    V_INSERT_QUERY := V_INSERT_QUERY||' AND TB0.G3E_FID IN ('||V_FIDS||')';
              END IF ;
            V_DELETE_QUERY := LTRIM (V_DELETE_QUERY,' UNION ALL ');
            p_OUT_QUERY := V_DELETE_QUERY ||' UNION ALL '||V_INSERT_QUERY||';'||RTRIM (PKG_DATA_CONNECTOR.FUN_FEATURE_NAME(REC0.REF_FNO),'/');

          ELSif V_INSERT_QUERY IS NOT NULL AND  V_DELETE_QUERY IS NULL THEN
           IF REC0.REF_FNO IN(11802,11803) THEN
                    V_INSERT_QUERY :=  REPLACE (V_INSERT_QUERY,'ORDER BY G3E_ID,LVL) TB0',' AND TB0.IN_FID IN (')|| V_FIDS|| ') ORDER BY G3E_ID,LVL) TB0';
              ELSE
                    V_INSERT_QUERY := V_INSERT_QUERY||' AND TB0.G3E_FID IN ('||V_FIDS||')';
              END IF ;
            p_OUT_QUERY := V_INSERT_QUERY||';'||RTRIM (PKG_DATA_CONNECTOR.FUN_FEATURE_NAME(REC0.REF_FNO),'/');

          ELSif V_INSERT_QUERY IS NULL AND  V_DELETE_QUERY IS NOT NULL THEN

            p_OUT_QUERY := LTRIM (V_DELETE_QUERY,' UNION ALL ')||';'||RTRIM (PKG_DATA_CONNECTOR.FUN_FEATURE_NAME(REC0.REF_FNO),'/');

          END IF;
         --DBMS_OUTPUT.PUT_LINE(p_OUT_QUERY);

  END LOOP;

END PRC_CDC_PROCESS;
-- function get the number between

/*********************************************************************************************************************************************************
**  PRC_CDC_PROCESS_FIBERMODLOG : This procedure WILL PROVIDE ONLY CDC PROCESS DELETE SCRIPT FOR CONNECTIONS BASED ON GAO_FIBERTABLEMODLOG LOG TABLE
*****************************************************************************************************************************************/

PROCEDURE PRC_CDC_PROCESS_CONNECTIONS  (p_OUT_QUERY  OUT  NOCOPY VARCHAR2 )
AS
   V_CDC_COUNT      NUMBER;
   v_SPLICE_TMP_COUNT NUMBER := 0;
   v_SPLICE_COUNT NUMBER := 0;
   V_OUT_QUERY      VARCHAR2(32767);--VARCHAR2(32767);
   V_DELETE_QUERY  VARCHAR2(32767);
   V_DELETE_QUERY1 VARCHAR2(32767);
   V_INSERT_QUERY  VARCHAR2(32767);
   V_SUB_QUERY              VARCHAR2(32767);
   V_FIDS          VARCHAR2(32767);
   V_DML            VARCHAR2(10);
   V_FNO            NUMBER;
   v_g3e_fids       VARCHAR2(20000);
   V_G3E_IDS         VARCHAR2(20000);  
   V_G3E_IDS1         VARCHAR2(20000);
   V_count                                          NUMBER;
   v_in_low           number;
   v_out_low           number;
     v_in_high           number;
   v_out_high           number;
   V_MIN_IN_LOW           NUMBER;
   v_id             number := 0;
BEGIN
    --PRC_GET_INSRT_DEL_PORTS;     
                 -- prc_upd_splice_connect_temp;
      V_OUT_QUERY := null;
       FOR REC0 IN (SELECT  F.G3E_FNO AS REF_FNO,GCOMMS_FNO g3e_fno
                                FROM TB_FEATURE F
                                WHERE  f.category = 'CONNECTIONS'
                                AND NOT EXISTS (SELECT 1 FROM TB_ID_TRACKER WHERE G3E_FNO = F.G3E_FNO )
                                                                                                                        ORDER BY 1
                               )                    
  LOOP
            v_count   := 0;
            V_OUT_QUERY := null;
            v_SPLICE_TMP_COUNT := 0;
            v_SPLICE_COUNT := 0;
            INSERT INTO TB_ID_TRACKER (G3E_FNO) VALUES (REC0.REF_FNO);
            commit;
            BEGIN



                        IF  REC0.REF_FNO =  11801   THEN                        
                                PKG_DATA_CONNECTOR.PRC_MIG_GCOMS_FEATURE(REC0.REF_FNO,null,'delete',V_OUT_QUERY);
                                    V_OUT_QUERY := V_OUT_QUERY ||q'[ where LTT_STATUS IN ('delete','insert') and IN_FTYPE = 7200 AND OUT_FTYPE = 7200 AND G3E_FNO IN (11800,15700) ]';
                                SELECT COUNT(1)
                                INTO v_count
                                FROM tb_splice_connect
                                where IN_FTYPE = 7200 AND OUT_FTYPE = 7200 AND G3E_FNO IN (11800,15700);
                                IF V_COUNT = 0 THEN
                                    V_OUT_QUERY := NULL;
                                END IF;

                        ELSIF REC0.REF_FNO = 11802   THEN
                                PKG_DATA_CONNECTOR.PRC_MIG_GCOMS_FEATURE(REC0.REF_FNO,null,'delete',V_OUT_QUERY);
                                V_OUT_QUERY := V_OUT_QUERY||q'[ WHERE LTT_STATUS IN ('delete','insert') and g3e_fno <> 12400  AND (( in_ftype = 7200 and out_ftype in( 12300 )) or (in_ftype in( 12300) and out_ftype = 7200 ))]';
                                SELECT COUNT(1)
                                INTO v_count
                                FROM tb_splice_connect
                                WHERE g3e_fno <> 12400  AND (( in_ftype = 7200 and out_ftype in( 12300 )) or (in_ftype in( 12300) and out_ftype = 7200 ));
                                IF V_COUNT = 0 THEN
                                    V_OUT_QUERY := NULL;
                                END IF;                        
                        ELSIF  REC0.REF_FNO = 11804   THEN                           
                                PKG_DATA_CONNECTOR.PRC_MIG_GCOMS_FEATURE(REC0.REF_FNO,null,'delete',V_OUT_QUERY);
                                V_OUT_QUERY := V_OUT_QUERY||q'[ where LTT_STATUS IN ('delete','insert') and g3e_fno <> 12400  AND (( in_ftype = 7200 and out_ftype in( 12200,15900 )) or (in_ftype in( 12200,15900 ) and out_ftype = 7200 ))]';
                              SELECT COUNT(1)
                                INTO v_count
                                FROM tb_splice_connect
                                WHERE  g3e_fno <> 12400  AND (( in_ftype = 7200 and out_ftype in( 12200,15900 )) or (in_ftype in( 12200,15900 ) and out_ftype = 7200 ));
                                IF V_COUNT = 0 THEN
                                    V_OUT_QUERY := NULL;
                                END IF;
                        ELSIF   REC0.REF_FNO = 11803   THEN
                           PKG_DATA_CONNECTOR.PRC_MIG_GCOMS_FEATURE(REC0.REF_FNO,null,'delete',V_OUT_QUERY);
                                V_OUT_QUERY := V_OUT_QUERY||q'[ WHERE LTT_STATUS IN ('delete','insert') and  g3e_fno <> 12400  AND in_ftype IN (12300,12200,15900) AND out_ftype IN (12300,12200,15900 ) ]';
                                SELECT COUNT(1)
                                INTO v_count
                                FROM tb_splice_connect
                                WHERE g3e_fno <> 12400  AND in_ftype IN (12300,12200,15900) AND out_ftype IN (12300,12200,15900 ) ;
                                IF V_COUNT = 0 THEN
                                    V_OUT_QUERY := NULL;
                                END IF;
                            END IF;                    

            END;

          if  V_OUT_QUERY IS NOT NULL THEN
                p_OUT_QUERY := V_OUT_QUERY||';'||RTRIM (PKG_DATA_CONNECTOR.FUN_FEATURE_NAME(REC0.REF_FNO),'/');

         END IF;         

         if v_count >= 1 then
         exit;
         end if;
               END LOOP;

END PRC_CDC_PROCESS_CONNECTIONS ;

PROCEDURE PRC_CDC_PROCESS_FIBER (p_OUT_QUERY  OUT  NOCOPY VARCHAR2 )
AS
   V_CDC_COUNT      NUMBER;  
   V_OUT_QUERY      VARCHAR2(32767);--VARCHAR2(32767);
   V_DELETE_QUERY  VARCHAR2(32767);
   V_INSERT_QUERY  VARCHAR2(32767);
   V_SUB_QUERY              VARCHAR2(32767);
   V_FIDS          VARCHAR2(32767);
   V_DML            VARCHAR2(10);
   V_FNO            NUMBER;
   V_G3E_FID                     NUMBER;
   V_G3E_FID_1                 VARCHAR2(32767);
   V_NUM                                          NUMBER;
   V_COUNT                                       NUMBER;
BEGIN

                  FOR REC0 IN (
                                                                                                                            SELECT  F.G3E_FNO AS REF_FNO,GCOMMS_FNO
                                FROM TB_FEATURE F
                                                                                                                        WHERE UPPER(FEATURE_NAME) IN ('FIBER','FIBER_SLACK','FIBER_CABLE_LABEL')
                                                                                                            ORDER BY 1

               )
  LOOP
                              V_COUNT := 0;
        V_FIDS := NULL;
        V_OUT_QUERY := null;
        V_DELETE_QUERY := NULL;
        V_INSERT_QUERY:= NULL;
                              V_G3E_FID_1 := NULL;


        /* this cursor will pull only the rows from modification log table based on the modificationnumber for which cdc process not done for current date  */
        FOR REC1 IN (SELECT MODIFICATIONNUMBER,TYPE, G3E_FNO,G3E_FID,G3E_ID,MODIFIEDDATE,ROW_NUMBER() OVER (PARTITION BY G3E_FNO,TYPE,G3E_ID ORDER BY MODIFICATIONNUMBER DESC ) NUM
                        FROM GAO_FIBERTABLEMODLOG MF
                        WHERE  TO_DATE(MODIFIEDDATE,'DD-MON-YYYY') >= TO_DATE(SYSDATE-1,'DD-MON-YYYY')                                                                                      
                        AND MF.LTT_ID = 0
                        AND MF.G3E_FNO = REC0.GCOMMS_FNO
                                                                                          AND DECODE(TABLENAME,'GC_FELEMENT',7203,'GC_FCBL_T',7201,'GC_FCBLSLACK_T',7202) =  REC0.REF_FNO
                                                                                          AND  NOT EXISTS ( SELECT 1 FROM TB_CDC_PROCESS CP
                                                                                                                                                        WHERE CP.MODIFICATIONNUMBER  = MF.MODIFICATIONNUMBER
                                                                                                                                                        AND PROCESSED IN ('Y','P','D')

                                         )

                       )
          LOOP
            BEGIN
                                                                           V_G3E_FID :=REC1.G3E_ID;
                                                                           V_NUM := REC1.NUM;
                                                                           V_SUB_QUERY :=' AND TB0.G3E_ID IN (';

                  SELECT COUNT(1)
                  INTO V_CDC_COUNT
                  FROM TB_CDC_PROCESS
                  WHERE MODIFICATIONNUMBER = REC1.MODIFICATIONNUMBER;
                  IF  V_CDC_COUNT = 0 AND REC1.NUM = 1   THEN -- To track the feature and fid which is under Process
                                                              V_COUNT :=1;
                                                                                          INSERT INTO TB_CDC_PROCESS (MODIFICATIONNUMBER,TYPE,G3E_FNO, G3E_FID,PROCESSED)
                                                                                          VALUES (REC1.MODIFICATIONNUMBER,REC1.TYPE,REC0.REF_FNO,REC1.G3E_ID,'P');
                                                                                          COMMIT;
                     IF REC1.TYPE IN ('3','2') AND REC1.NUM = 1 THEN ---- To track the feature and fid once script is generated for cdc process with status Y
                         IF V_FIDS IS NULL THEN
                                                                                          PKG_DATA_CONNECTOR.PRC_MIG_GCOMS_FEATURE(REC0.REF_FNO,NULL,'insert',V_OUT_QUERY);-- generate scripts
                                                                                                         V_INSERT_QUERY := replace (V_OUT_QUERY,q'['insert']','PKG_DATA_CONNECTOR.fun_get_cdc_type('||REC0.REF_FNO||',TB0.G3E_id)');
                                                                                          END IF;
                         V_FIDS := V_FIDS||','||V_G3E_FID;
                    ELSIF REC1.TYPE IN ('1') AND REC1.NUM = 1 THEN
                                                                                          IF V_G3E_FID_1 IS NULL then                            
                                                                                          PKG_DATA_CONNECTOR.PRC_MIG_GCOMS_FEATURE(REC0.REF_FNO,NULL,'delete',V_OUT_QUERY);
                                                                                                         V_DELETE_QUERY :=REPLACE (V_OUT_QUERY,'vmx_id ( ','vmx_id ( G3E_FID');
                                                                                          END IF;
                            V_G3E_FID_1 := V_G3E_FID_1||','||REC1.G3E_ID;-- because holding g3e_id as g3e_fid in tb_cdc_procees table for (7201,7202,7203)
                    END IF;

                  ELSIF V_CDC_COUNT = 0 AND REC1.NUM <> 1    THEN -- To track the feature and fid which is Duplicate

                                                                                          INSERT INTO TB_CDC_PROCESS (MODIFICATIONNUMBER,TYPE,G3E_FNO, G3E_FID,PROCESSED)
                                                                                          VALUES (REC1.MODIFICATIONNUMBER,REC1.TYPE,REC0.REF_FNO,V_G3E_FID,'D');
                                                                                          COMMIT;

                  END IF;

           EXCEPTION
                WHEN OTHERS THEN
                --DBMS_OUTPUT.PUT_LINE(LENGTH (V_OUT_QUERY));
                UPDATE TB_CDC_PROCESS
                SET processed = 'E'
                WHERE MODIFICATIONNUMBER = REC1.MODIFICATIONNUMBER;
                COMMIT;
            END;

          END LOOP;
                                IF V_DELETE_QUERY IS NOT NULL THEN
                                             V_DELETE_QUERY := V_DELETE_QUERY||q'[ where PROCESSED IN ('P') and G3E_FNO = ]'||REC0.REF_FNO||Q'[ AND type = '1' AND G3E_FID IN (]'||LTRIM(V_G3E_FID_1,',')||')';
                                END IF;

                                IF V_INSERT_QUERY IS NOT NULL THEN
                                             V_INSERT_QUERY := V_INSERT_QUERY||V_SUB_QUERY||LTRIM(V_FIDS,',')||')';
                                END IF;

          IF V_DELETE_QUERY IS NOT NULL AND  V_INSERT_QUERY IS NOT NULL THEN

            p_OUT_QUERY := V_DELETE_QUERY ||' UNION ALL '||V_INSERT_QUERY||';'||RTRIM (PKG_DATA_CONNECTOR.FUN_FEATURE_NAME(REC0.REF_FNO),'/');

          ELSif V_INSERT_QUERY IS NOT NULL AND  V_DELETE_QUERY IS NULL THEN
            p_OUT_QUERY := V_INSERT_QUERY||';'||RTRIM (PKG_DATA_CONNECTOR.FUN_FEATURE_NAME(REC0.REF_FNO),'/');

          ELSif V_INSERT_QUERY IS NULL AND  V_DELETE_QUERY IS NOT NULL THEN
            p_OUT_QUERY := V_DELETE_QUERY||';'||RTRIM (PKG_DATA_CONNECTOR.FUN_FEATURE_NAME(REC0.REF_FNO),'/');

          END IF;
                                IF V_COUNT = 1 THEN
                                             EXIT;
                                 END IF;
         --DBMS_OUTPUT.PUT_LINE(p_OUT_QUERY);
               END LOOP;

END PRC_CDC_PROCESS_FIBER;

FUNCTION FUN_GET_PORT
(P_FID IN NUMBER ,
p_modnumber in number,
p_low  number,
P_high number
)
RETURN NUMBER AS
V_PORT NUMBER;
v_count number := 0;
BEGIN
            select g3e_cid
            into v_port
                from GAO_FIBERTABLEMODLOG
                where g3e_fID =P_FID
                AND TABLENAME = 'GC_FELEMENT'
               -- and g3e_fno = 7200
                and type =2
                and ltt_mode = 'POST'
                and  MODIFICATIONNUMBER = p_modnumber
                and g3e_cid between p_low and p_high;


       RETURN V_PORT;
EXCEPTION
    WHEN OTHERS THEN
    RETURN NULL;
END FUN_GET_PORT;
PROCEDURE PRC_TB_SPLICE_CONNECT_INSERT
(P_ID IN NUMBER)
AS
BEGIN
    FOR rec0 IN (
            SELECT
            *
        FROM
            tb_splice_connect
        WHERE
            g3e_id = P_ID
    ) LOOP
    DELETE FROM tb_splice_connect WHERE g3e_id = P_ID;
        FOR rec1 IN (
                SELECT
                g3e_cid,modificationnumber
            FROM
                gao_fibertablemodlog
            WHERE
                    g3e_fid = rec0.in_fid
                AND ltt_mode = 'POST'
                AND TO_DATE(modifieddate, 'DD-MON-YYYY') >= TO_DATE(sysdate - 1, 'DD-MON-YYYY')
                and g3e_cid between rec0.in_low and rec0.in_high
                ORDER BY modificationnumber

        ) LOOP

            INSERT INTO tb_splice_connect (
                    g3e_id,
                g3e_fno,
                g3e_fid,
                g3e_cno,
                g3e_cid,
                in_ftype,
                in_fid,
                in_low,
                in_high,
                out_ftype,
                out_fid,
                out_low,
                out_high
            ) VALUES (
                    rec0.g3e_id,
                rec0.g3e_fno,
                rec0.g3e_fid,
                rec0.g3e_cno,
                rec0.g3e_cid,
                rec0.in_ftype,
                rec0.in_fid,
                rec1.g3e_cid,
                rec1.g3e_cid,
                rec0.out_ftype,
                rec0.out_fid,
                NULL,
                NULL
            );

        END LOOP;

        FOR rec1 IN (
                SELECT
                g3e_cid,
                modificationnumber
            FROM
                gao_fibertablemodlog
            WHERE
                    g3e_fid = rec0.out_fid
                AND ltt_mode = 'POST'
                AND TO_DATE(modifieddate, 'DD-MON-YYYY') >= TO_DATE(sysdate - 1, 'DD-MON-YYYY')
                and g3e_cid between rec0.out_low and rec0.out_high
                ORDER BY modificationnumber

        ) LOOP
            UPDATE tb_splice_connect
            SET
                out_low = rec1.g3e_cid,
                out_high = rec1.g3e_cid
            WHERE

                 g3e_id = rec0.g3e_id
                and in_low = ( select min(in_low) from tb_splice_connect a where out_low IS NULL and a.g3e_id = g3e_id)
                ;

        END LOOP;
commit;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
    NULL;
END;
FUNCTION FUN_GET_CDC_DEFAULT_FNO
(P_FNO IN NUMBER,
P_REF_FNO IN NUMBER,
P_DATE VARCHAR2
)
RETURN NUMBER AS
V_FNO NUMBER;
v_count number;
BEGIN
    IF P_FNO=7200 THEN
                              --DBMS_OUTPUT.PUT_LINE('INSIDE');
        IF P_REF_FNO = 7201 THEN
                              SELECT count(*) into v_count FROM modificationlog WHERE G3E_FNO=7200  AND LTT_ID=0 AND TABLENAME='GC_FCBL_T' AND  MODIFIEDDATE >= TO_DATE(P_DATE,'DD-MON-YY');
                                             if v_count >=1 then
                                                            V_FNO := P_REF_FNO;
                                             end if;
                                             --DBMS_OUTPUT.PUT_LINE('7201 '||v_count);
            --V_FNO := P_REF_FNO;
        ELSIF P_REF_FNO = 7202 THEN
                                             SELECT count(*) into v_count FROM modificationlog WHERE G3E_FNO=7200 AND LTT_ID=0 AND TABLENAME='GC_FCBLSLACK_T' AND MODIFIEDDATE >= TO_DATE(P_DATE,'DD-MON-YY');
                                             if v_count >=1 then
            V_FNO := P_REF_FNO;
                                             end if;
                                             --DBMS_OUTPUT.PUT_LINE('7202 '||v_count);
            --V_FNO := P_REF_FNO;

        ELSIF P_REF_FNO=7203 THEN
                                             SELECT count(*) into v_count FROM GAO_FIBERTABLEMODLOG WHERE G3E_FNO=7200 AND LTT_ID=0 AND TABLENAME='GC_FELEMENT' AND MODIFIEDDATE >= TO_DATE(P_DATE,'DD-MON-YY');
                                             if v_count >=1 then
                                                            V_FNO := P_REF_FNO;
                                             end if;
                                             --DBMS_OUTPUT.PUT_LINE('7203 '||v_count);
                --V_FNO := P_REF_FNO;
        ELSIF P_REF_FNO=7200 THEN
                V_FNO := P_REF_FNO;
        END IF;
        RETURN NVL(V_FNO,P_FNO);
    ELSIF P_FNO = 11800  THEN
        IF P_REF_FNO = 11801 THEN
            V_FNO := P_REF_FNO;
        ELSIF  P_REF_FNO = 11802 THEN
            V_FNO := P_REF_FNO;
        ELSIF  P_REF_FNO = 11803 THEN
            V_FNO := P_REF_FNO;
        ELSIF  P_REF_FNO = 11804 THEN
            V_FNO := P_REF_FNO;
        ELSIF P_REF_FNO = 11800 THEN
            V_FNO := P_REF_FNO;
        END IF;
        RETURN V_FNO;
     ELSIF P_FNO = 12300 THEN
        IF  P_REF_FNO = 12301 THEN
            V_FNO := P_REF_FNO;
        ELSIF P_REF_FNO = 11802 THEN -- if features no is 12300 then we need genrate 11802 csv for corresponding fids
            V_FNO := P_REF_FNO;
        ELSIF P_REF_FNO = 11803 THEN -- if features no is 12300 then we need genrate 11803 csv for corresponding fids
            V_FNO := P_REF_FNO;
        ELSIF  P_REF_FNO = 11804 THEN
            V_FNO := P_REF_FNO;
        ELSIF P_REF_FNO = 12300 THEN
            V_FNO := P_REF_FNO;
        END IF;
        RETURN V_FNO;
    ELSIF P_FNO =12200 THEN
        IF P_REF_FNO = 11802 THEN --if features no is 12200 then we need genrate 11802 csv for corresponding fids
            V_FNO := P_REF_FNO;
        ELSIF P_REF_FNO = 11803 THEN -- if features no is 12200 then we need genrate 11803 csv for corresponding fids
            V_FNO := P_REF_FNO;
        ELSIF  P_REF_FNO = 11804 THEN
            V_FNO := P_REF_FNO;
        ELSIF P_REF_FNO = 12200 THEN
            V_FNO := P_REF_FNO;
        END IF;
        RETURN V_FNO;
    ELSIF P_FNO =15900 THEN
        IF P_REF_FNO = 11802 THEN -- if features no is 15900 then we need genrate 11802 csv for corresponding fids
            V_FNO := P_REF_FNO;
        ELSIF P_REF_FNO = 11803 THEN -- if features no is 15900 then we need genrate 11803 csv for corresponding fids
            V_FNO := P_REF_FNO;
        ELSIF  P_REF_FNO = 11804 THEN
            V_FNO := P_REF_FNO;
        ELSIF P_REF_FNO = 15900 THEN
            V_FNO := P_REF_FNO;
        END IF;
        RETURN V_FNO;
    ELSIF P_FNO =4000 THEN
            IF P_REF_FNO = 4001 THEN -- if features no is 15900 then we need genrate 11802 csv for corresponding fids
                V_FNO := P_REF_FNO;
            ELSIF P_REF_FNO = 4000 THEN
                V_FNO := P_REF_FNO;
            END IF;
            RETURN V_FNO;
    ELSE
        RETURN P_FNO;
    END IF;
EXCEPTION 
   WHEN OTHERS THEN
    RETURN P_FNO;
END FUN_GET_CDC_DEFAULT_FNO;

/*******************************************************************************************************
**  fun_get_cdc_type :  
*********************************************************************************************************/

function fun_get_cdc_type
    (p_fno in number,
    p_fid  in number
    )
return varchar2 as
pragma autonomous_transaction;
v_type varchar2(10);
v_count number;
v_modificationnumber  NUMBER(38,4);
begin
select type into v_type from (
        select  DECODE (TYPE,1,'delete',2,'update',3,'insert',NULL) type
    from tb_cdc_process
    where processed in('Y', 'P')
    and g3e_fno = p_fno
    and g3e_fid = p_fid
               order by modificationnumber desc
               )
    where  rownum =1;

return v_type;
exception
    when others then
        return null;

end fun_get_cdc_type;


/*******************************************************************************************************
**  fun_get_RXPorts :  In order to fetch the proper oridinal based on the deviceordinal for RX side only for IQGEO
*********************************************************************************************************/

function fun_get_RXPorts
    (P_equip_fid in number,
    p_port_name  in number
    )
return number as
v_port_number number;

begin
select  TB0.GAO_ORDINAL
    into v_port_number
    FROM GAO_FIBERPORT TB0
    INNER JOIN GAO_FIBERPORTGROUP TB1 ON (TB1.GAO_FPGNO = TB0.GAO_FPGNO  AND TB0.GAO_DEVICEORDINAL  = p_port_name)
    INNER JOIN GAO_FIBERDEVICE TB2 ON (TB2.GAO_FDNO = TB1.GAO_FDNO )
    INNER JOIN B$GC_NETELEM TB3 ON (TB3.MIN_MATERIAL = TB2.GAO_MATERIAL)
    WHERE TB3.g3e_fid = P_equip_fid;

return v_port_number;
exception
    when no_data_found then
        select  TB0.GAO_ORDINAL
    into v_port_number
    FROM GAO_FIBERPORT TB0
    INNER JOIN GAO_FIBERPORTGROUP TB1 ON (TB1.GAO_FPGNO = TB0.GAO_FPGNO  AND TB0.GAO_DEVICEORDINAL  = p_port_name)
    INNER JOIN GAO_FIBERDEVICE TB2 ON (TB2.GAO_FDNO = TB1.GAO_FDNO )
    INNER JOIN TB_MIN_MATERIAL TB3 ON (TB3.MIN_MATERIAL = TB2.GAO_MATERIAL)
    WHERE TB3.g3e_fid = P_equip_fid;

    return v_port_number;

end fun_get_RXPorts;
/*******************************************************************************************************
**  fun_get_id :  to get cable g3e_id for cdc process, it is dedicated function only for cable objects
*********************************************************************************************************/

function fun_get_id
    (p_fno in number,
    p_fid  in number,
               P_DATE date
    )
return number as
V_OUT number;
BEGIN

IF P_FNO =7201 THEN

                SELECT distinct G3E_ID
                              INTO V_OUT
                FROM modificationlog
                WHERE G3E_FNO=7200
                              AND G3E_FID =P_FID
                              AND TABLENAME='GC_FCBL_T'
                              AND  trunc(MODIFIEDDATE) >= trunc(P_DATE)
                              AND LTT_ID =0;
ELSIF P_FNO =7202 THEN
               SELECT DISTINCT
                              g3e_id
               INTO v_out
               FROM
                              modificationlog
               WHERE
                                             g3e_fno = 7200
                              AND g3e_fid = p_fid
                              AND tablename = 'GC_FCBLSLACK_T'
                              AND trunc(MODIFIEDDATE) >= trunc(P_DATE)
                              AND LTT_ID =0;
--P_FNO =7203 WE ARE HANDLING THIS DIFFERENT PROCEDURE

 ELSE
  V_OUT:=p_fid;
 END IF;

 IF V_OUT IS NULL THEN
               V_OUT :=0;
END IF;

return V_OUT;
exception
    when no_data_found then
                              V_OUT :=0;
        return V_OUT;

end fun_get_id;

/*******************************************************************************************************
**  FUN_GET_ARRAY : SDO_UTIL.GETNUMVERTICES > 499 causing too many vlues error, to avoid that string will pull into array before converting wkb               
*********************************************************************************************************/
function FUN_GET_ARRAY
(   p_str           IN clob,
    p_GEOMETRY_TYPE IN NUMBER)
return CLOB
is
  s clob := P_str||',';
  i number;
  j number;
  V_STRING CLOB;
  v_outWKB CLOB;
  t sdo_ordinate_array := sdo_ordinate_array();
begin



--DBMS_OUTPUT.PUT_LINE('s:'||s);
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

  if p_geometry_type = 2 then
        v_outWKB := blob_to_hex(SDO_UTIL.TO_WKBGEOMETRY(SDO_CS.TRANSFORM(SDO_GEOMETRY(2002, 27700, NULL, SDO_ELEM_INFO_ARRAY(1, 2, 1),t),8307))) ;
       -- v_outWKB := SDO_UTIL.TO_WKTGEOMETRY(SDO_CS.TRANSFORM(SDO_GEOMETRY(3002, 27700, NULL, SDO_ELEM_INFO_ARRAY(1, 2, 1),t),27700)) ;


  elsif p_geometry_type = 3 then
   v_outWKB := blob_to_hex(SDO_UTIL.TO_WKBGEOMETRY(SDO_CS.TRANSFORM(SDO_GEOMETRY(2003, 27700, NULL, SDO_ELEM_INFO_ARRAY(1, 1003, 1),t),8307))) ;
-- v_outWKB := SDO_UTIL.TO_WKTGEOMETRY(SDO_CS.TRANSFORM(SDO_GEOMETRY(3003, 27700, NULL, SDO_ELEM_INFO_ARRAY(1, 1003, 1),t),27700)) ;


  END IF; 
    return  v_outWKB;

end;
/*******************************************************************************************************
**  fun_get_orientation : to get orientation for point geometry              
*********************************************************************************************************/
function fun_get_orientation
    (   p_geometry in sdo_geometry ,P_REGION IN VARCHAR2
               )
    return number as

    v_out number;
               x varchar2(300);
               y varchar2(300);
               v_geometry sdo_geometry;
               v_final_geometry sdo_geometry;
               P_FNO NUMBER :=9100;
begin
   if p_geometry is not null then

                              v_geometry:= p_geometry;

                              IF UPPER(P_REGION) ='NI'  THEN                            
                                                            V_geometry.sdo_srid := 27700;                                               
                                                            SELECT SDO_CS.TRANSFORM(V_geometry,29902) into V_geometry from dual;                               
                              END IF;

    IF sdo_geometry.get_gtype(V_geometry) = 1 THEN
                              y := sdo_util.get_coordinate(V_geometry,2).SDO_POINT.Y;
                              x := sdo_util.get_coordinate(V_geometry,2).SDO_POINT.X;
                              If x is null then
                              x:=0;
                              elsif y is null then
                              y:=0;
                              end if;
                              if (x !=0 and y !=0) then
                                             v_out:= round (sdo_util.convert_unit(ATAN2(Y,X),
                    'Radian','Degree'),2) ;
                              else
                                             v_out:=0;
                              end if;
                              v_out:=nvl(v_out,0);
                              return v_out;
    else
         return 0;
    end if;
  else
  return null;
  end if;
end fun_get_orientation;
/*******************************************************************************************************
**  fun_get_conduit : to get vmx_conduits based on G3E_OWNERFID           
*********************************************************************************************************/
function fun_get_conduit
    (   P_FID in number ,
        p_fno in number
    )
    return varchar2 as
    v_out  varchar2(2000);

begin

    --SELECT LISTAGG('conduit/'||G3E_OWNERFID, ';') WITHIN GROUP (ORDER BY G3E_OWNERFID)
               SELECT LISTAGG(DECODE (lower(tf.feature_name)||'/' ||G3E_OWNERFID,lower(tf.feature_name)||'/',NULL,lower(tf.feature_name)||'/0',NULL,lower(tf.feature_name)||'/' ||G3E_OWNERFID),';') WITHIN GROUP (ORDER BY G3E_OWNERFID)
    into v_out
    FROM  B$GC_CONTAIN bc
               join tb_feature tf on (tf.g3e_fno= bc.g3e_ownerfno )
    where bc.g3e_fno = p_fno
    and bc.g3e_fid = P_FID
    and bc.LTT_ID = 0
               and bc.g3e_ownerfno in (2200,5200);



               return v_out;


exception
    when others then
        return null;
end fun_get_conduit;
/*******************************************************************************************************
**  blob_to_hex : to convert BLOB to CLOB           
*********************************************************************************************************/

FUNCTION blob_to_hex(blob_in IN BLOB)
RETURN CLOB
AS
    v_clob     CLOB;
    v_raw      RAW(32767);
    v_chunk    VARCHAR2(32767);
    v_start    PLS_INTEGER := 1;
    v_chunk_size PLS_INTEGER := 1000;
BEGIN
    DBMS_LOB.CREATETEMPORARY(v_clob, TRUE);

    FOR i IN 1..CEIL(DBMS_LOB.GETLENGTH(blob_in) / v_chunk_size)
    LOOP
        v_raw := DBMS_LOB.SUBSTR(blob_in, v_chunk_size, v_start);
        v_chunk := RAWTOHEX(v_raw);
        DBMS_LOB.WRITEAPPEND(v_clob, LENGTH(v_chunk), v_chunk);
        v_start := v_start + v_chunk_size;
    END LOOP;

    RETURN v_clob;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_LOB.FREETEMPORARY(v_clob);
        RAISE;
END blob_to_hex;


/*******************************************************************************************************
**  fun_get_WKB : to convert geometry to wkb format             
*********************************************************************************************************/
function fun_get_WKB
    (p_geometry in sdo_geometry)
return CLOB as
    v_sring CLOB;
    v_loop  number:=0;
    v_outWKB CLOB;
    V_geometry_type number;
begin
    if p_geometry is null then
        return null;
    end if;
    V_geometry_type := sdo_geometry.get_gtype(p_geometry);
    IF V_geometry_type = 1 THEN
        SELECT blob_to_hex(SDO_UTIL.TO_WKBGEOMETRY(SDO_CS.TRANSFORM(SDO_GEOMETRY(2001, 27700, SDO_POINT_TYPE(R.X,R.Y, NULL), NULL, NULL), 8307))) A
        into v_outWKB
         FROM(SELECT X.X ,X.Y,X.ID  FROM TABLE(SDO_UTIL.GETVERTICES (p_geometry))X)R;
    ELSIF V_geometry_type in(2,3) THEN
        for rec2 in (
                         SELECT X.X ,X.Y,X.ID  FROM TABLE(SDO_UTIL.GETVERTICES (p_geometry)) X
            )
            loop
                v_loop := v_loop +1;
                if v_loop = 1 then
                    v_sring := to_clob(rec2.X)||','||to_clob(rec2.Y);
                else
                    v_sring := v_sring ||','||to_clob(rec2.X)||','||to_clob(rec2.Y);
                end if;
            End Loop;
        If V_Geometry_Type = 2 Then
           V_Outwkb := Fun_Get_Array (V_Sring,V_Geometry_Type);          
        Elsif V_Geometry_Type = 3 Then
            V_Outwkb := Fun_Get_Array (V_Sring,V_Geometry_Type);          
        End If; 
    Else
    Return Null;
    End If;
  Return  V_Outwkb;  
end fun_get_WKB;





/*******************************************************************************************************
**  fun_get_fiber_ports : to get vmx_n_fiber_ports value based on G3E_FID and G3E_FNO     CREATED_DATE: 03-OCT-2023      
*********************************************************************************************************/
function fun_get_fiber_ports
    (   P_FID in number ,
        p_fno in number
    )
    return number as
    v_out  number;

begin

       SELECT count(*)
       INTO v_out
       FROM b$gc_felement
       WHERE g3e_fno =p_fno
       AND g3e_fid =p_FID
       AND LTT_ID =0;


    return v_out;
exception
    when others then
        return 0;
end fun_get_fiber_ports;

/*******************************************************************************************************
**  fun_get_num_ducts : to get vmx_n_ducts based on G3E_FID and G3E_FNO     CREATED_DATE: 27-SEP-2023      
*********************************************************************************************************/
function fun_get_num_ducts
    (   P_FID in number ,
        p_fno in number
    )
    return number as
    v_out  number;

begin

       SELECT num_ducts
       INTO v_out
       FROM b$gc_form bf
       JOIN b$gc_contain bc ON (bf.g3e_fid =bc.g3e_fid and bf.g3e_fno=2400)
       WHERE
       bc.g3e_ownerfid=P_FID
       and (bf.ltt_id =0 and bc.ltt_id=0)
       and bc.g3e_ownerfno=p_fno;


    return v_out;
exception
    when others then
        return 0;
end fun_get_num_ducts;

/*******************************************************************************************************
**  fun_get_in_equip : to get vmx_fun_in_equip based on G3E_FID           
*********************************************************************************************************/
function fun_get_in_equip
    (   P_FID in number ,
        p_fno in number
    )
    return varchar2 as
    v_out  varchar2(2000);

begin

    SELECT lower (feature_name)||'/'||a.in_fid in_equip
    into v_out
    FROM b$gc_nr_connect a
    join tb_feature c on (c.g3e_fno = a.in_fno)
    WHERE  a.g3e_fid =P_FID
    and a.g3e_fno = p_fno
    and a.LTT_ID = 0;

    return v_out;
exception
    when others then
        return null;
end fun_get_in_equip;

/*******************************************************************************************************
**  fun_get_out_equip : to get vmx_fun_out_equip based on G3E_FID           
*********************************************************************************************************/
function fun_get_out_equip
    (   P_FID in number ,
        p_fno in number
    )
    return varchar2 as
    v_out  varchar2(2000);

begin

     SELECT lower (feature_name)||'/'||a.out_fid out_equip
    into v_out
    FROM b$gc_nr_connect a
    join tb_feature c on (c.g3e_fno = a.out_fno)
    WHERE  a.g3e_fid =P_FID
    and a.g3e_fno = p_fno
    and a.LTT_ID = 0;

    return v_out;
exception
    when others then
        return null;
end fun_get_out_equip;

/*******************************************************************************************************
**  fun_get_vmx_id : to get vmx_ID based on G3E_FID           
*********************************************************************************************************/
function fun_get_vmx_id
    (   P_FID in number ,
        p_fno in number
    )
    return varchar2 as
    v_out  varchar2(2000);

begin

    SELECT lower (feature_name)||'/'||P_FID VMX_ID
    into v_out
    FROM tb_feature
    WHERE G3E_FNO = p_fno;

    return v_out;
exception
    when others then
        return null;
end fun_get_vmx_id;

/*******************************************************************************************************
**  fun_get_VMX_MANHOLE : to get vmx_VMX_MANHOLE based on G3E_FID and G3E_FNO         
*********************************************************************************************************/
function fun_get_vmx_manhole
    (   P_FID in number ,
        p_fno in number
    )
    return varchar2 as
    v_out  varchar2(2000);

begin

    SELECT 'manhole/'|| b.G3E_FID
    INTO v_out
    from b$gc_ne_connect a
    join b$gc_ne_connect b on( a.node1_id = b.node1_id and b.g3e_fno=2700)
    where a.g3e_fid=P_FID
    and a.g3e_fno=p_fno;


    return v_out;
exception
    when others then
        return null;
end fun_get_vmx_manhole;

/*******************************************************************************************************
**  fun_get_VMX_IN_STRUCTURE : to get vmx_in_structure based on G3E_FID and G3E_FNO         
*********************************************************************************************************/
function fun_get_vmx_in_structure
    (   P_FID in number ,
        p_fno in number
    )
    return varchar2 as
    v_out  varchar2(2000);

begin

SELECT lower (c.feature_name)||'/'||b.G3E_FID
INTO v_out
FROM B$GC_NE_CONNECT a
JOIN B$GC_NE_CONNECT b on (a.NODE1_ID = b.NODE1_ID and a.NODE1_ID!=0)
join tb_feature c on (c.g3e_fno = b.g3e_fno)
WHERE a.G3E_FID = P_FID
and a.G3E_FNO = p_fno
 and b.G3E_FNO in (2700,14100,14900,20600)
AND ROWNUM=1
ORDER BY b.G3E_FNO;

    return v_out;
exception
    when others then
        return null;
end fun_get_vmx_in_structure;

/*******************************************************************************************************
**  fun_get_VMX_OUT_STRUCTURE : to get vmx_out_structure based on G3E_FID and G3E_FNO         
*********************************************************************************************************/
function fun_get_vmx_out_structure
    (   P_FID in number ,
        p_fno in number
    )
    return varchar2 as
    v_out  varchar2(2000);

begin

SELECT fun_feature_name(b.g3e_fno)||b.G3E_FID
INTO v_out
FROM B$GC_NE_CONNECT a
JOIN B$GC_NE_CONNECT b on (a.NODE2_ID = b.NODE2_ID and a.NODE2_ID!=0)
WHERE a.G3E_FID = P_FID
and a.G3E_FNO = p_fno
 and b.G3E_FNO in (2700,14100,14900,20600)
AND ROWNUM=1
ORDER BY b.G3E_FNO;


    return v_out;
exception
    when others then
        return null;
end fun_get_vmx_out_structure;

/*******************************************************************************************************
**  fun_get_housing : to get vmx_house based on G3E_FID           
*********************************************************************************************************/
function fun_get_housing
    (   P_FID in number ,
        p_fno in number
    )
    return varchar2 as
    v_out  varchar2(2000);

begin

IF (p_fno = 14200) then

    SELECT lower (feature_name)||'/'||b.g3e_fid name_house
    into v_out
    FROM b$gc_isp_ownership a   
    join b$gc_isp_ownership b on (a.owner1_id = b.g3e_id and b.LTT_ID = 0)
    join tb_feature c on (c.g3e_fno = b.g3e_fno)
    WHERE  a.g3e_fid =P_FID
    and a.g3e_fno = p_fno
    and a.LTT_ID = 0;

ELSIF (p_fno = 4000) then

    --SELECT LISTAGG('conduit/'||G3E_OWNERFID, ';') WITHIN GROUP (ORDER BY G3E_OWNERFID)
               SELECT LISTAGG(DECODE ('conduit/' ||G3E_OWNERFID,'conduit/',NULL,'conduit/' ||G3E_OWNERFID),';' ) WITHIN GROUP (ORDER BY G3E_OWNERFID)
    into v_out
    FROM  B$GC_CONTAIN 
    where g3e_fno = p_fno
    and g3e_fid = p_fid
    and LTT_ID = 0;

ELSIF (P_FNO =4100) THEN
               --FIBER INNER DUCT NEED ONLY BUNDLE MICRODUCT
    SELECT lower (tf.feature_name)||'/'||bn.G3E_FID
    INTO v_out
    FROM 
    B$GC_CONTAIN bc
               join B$GC_FDUCT FD  ON (FD.G3E_FID= bc.G3E_OWNERFID AND FD.FEATURE_TYPE = 'Bundled duct')
               JOIN B$GC_NETELEM bn on (bn.G3E_FID = FD.G3E_FID and bn.G3E_FNO =4000)
               JOIN tb_feature tf on (tf.g3e_fno = 4001)
    WHERE  bc.G3E_FID =P_FID
    AND bc.G3E_FNO = p_fno
               AND bc.LTT_ID =0;

ELSE

    SELECT lower (feature_name)||'/'||b.g3e_fid name_house
    into v_out
    FROM b$gc_ownership a   
    join b$gc_ownership b on (a.owner1_id = b.g3e_id )
    join tb_feature c on (c.g3e_fno = b.g3e_fno)
    WHERE  a.g3e_fid =P_FID
    and a.g3e_fno = p_fno
    and a.LTT_ID = 0;

END IF;


    return v_out;
exception
    when others then
        return null;
end fun_get_housing;

/*******************************************************************************************************
**  fun_get_table_alias : to get table alias based on table name and p_fno         
*********************************************************************************************************/
function fun_get_table_alias
    (
            p_table_name varchar2,
        p_fno in number
    )
    return varchar2 as
    v_out  varchar2(10);
    v_count number;

begin
SELECT count(1)
    into v_count
    FROM TB_COMPONENTS a
    WHERE  a.g3e_TABLE =p_table_name
    and a.g3e_fno = p_fno;

    IF v_count  >= 1 THEN
        SELECT TABLE_ALIAS
        into v_out
        FROM TB_COMPONENTS a
        WHERE  a.g3e_TABLE =p_table_name
        and a.g3e_fno = p_fno;
    END IF;

    return v_out;
exception
    when others then
        return null;
end fun_get_table_alias;

/*******************************************************************************************************
**  fun_table_name : to get table_name for report         
*********************************************************************************************************/
function fun_table_name
    ( p_fno in number)
    return varchar2 as
    v_out  varchar2(200);

begin

    SELECT 'TB_'||G3E_FNO||'_'||UPPER(feature_name)
    into v_out
    FROM TB_FEATURE
    WHERE G3E_FNO=p_fno;


    return v_out;
exception
    when others then
        return null;
end fun_table_name;

/*******************************************************************************************************
**  fun_get_equip_side :        
*********************************************************************************************************/
function fun_get_port_name
    ( p_type in number,
      p_fid in number,
     p_low in number
    )
    return varchar2 as
    V_MIN_M VARCHAR2(3000);
    V_PORT_LABEL VARCHAR2(300);

BEGIN

IF (p_type in (12300,12200,15900)) THEN

/*
    SELECT MIN_MATERIAL
    INTO V_MIN_M
    FROM B$GC_NETELEM 
    WHERE G3E_FID = p_fid
    AND MIN_MATERIAL != 'N/A';
*/
  begin
     select  TB0.GAO_USERNAME
     INTO V_PORT_LABEL
     FROM GAO_FIBERPORT TB0
     INNER JOIN GAO_FIBERPORTGROUP TB1 ON (TB1.GAO_FPGNO = TB0.GAO_FPGNO  AND GAO_DEVICEORDINAL = p_low)
     INNER JOIN GAO_FIBERDEVICE TB2 ON (TB2.GAO_FDNO = TB1.GAO_FDNO)
     INNER JOIN B$GC_NETELEM TB3 ON (TB3.MIN_MATERIAL = TB2.GAO_MATERIAL)
     WHERE TB3.g3e_fid = p_fid;
  exception
    when no_data_found then
    /******* for delete cdc ( deleted min_material and fid holding in tb_min_material) **************/
    select  TB0.GAO_USERNAME
     INTO V_PORT_LABEL
     FROM GAO_FIBERPORT TB0
     INNER JOIN GAO_FIBERPORTGROUP TB1 ON (TB1.GAO_FPGNO = TB0.GAO_FPGNO  AND GAO_DEVICEORDINAL = p_low)
     INNER JOIN GAO_FIBERDEVICE TB2 ON (TB2.GAO_FDNO = TB1.GAO_FDNO)
     INNER JOIN tb_min_material TB3 ON (TB3.MIN_MATERIAL = TB2.GAO_MATERIAL)
     WHERE TB3.g3e_fid = p_fid;
  end;
    RETURN  V_PORT_LABEL;
ELSE

    RETURN NULL;   
END IF;

exception
    when others then
        return null;
end fun_get_port_name;
/*******************************************************************************************************
**  fun_get_equip_side :        
*********************************************************************************************************/
    FUNCTION fun_get_equip_side (
            p_fid IN NUMBER,
        p_low IN NUMBER
    ) RETURN VARCHAR2 AS
        v_equip_side VARCHAR2(5);
    BEGIN
        BEGIN
            SELECT
                decode(substr(tb0.gao_username, 1, 2), 'BP', 'TX', 'FP', 'RX',
                       NULL)
            INTO v_equip_side
            FROM
                     gao_fiberport tb0
                INNER JOIN gao_fiberportgroup tb1 ON ( tb1.gao_fpgno = tb0.gao_fpgno
                                                       AND gao_deviceordinal = p_low )
                INNER JOIN gao_fiberdevice    tb2 ON ( tb2.gao_fdno = tb1.gao_fdno )
                INNER JOIN b$gc_netelem       tb3 ON ( tb3.min_material = tb2.gao_material )
            WHERE
                tb3.g3e_fid = p_fid;

        EXCEPTION
            WHEN no_data_found THEN
                SELECT
                    decode(substr(tb0.gao_username, 1, 2), 'BP', 'TX', 'FP', 'RX',
                           NULL)
                INTO v_equip_side
                FROM
                         gao_fiberport tb0
                    INNER JOIN gao_fiberportgroup tb1 ON ( tb1.gao_fpgno = tb0.gao_fpgno
                                                           AND gao_deviceordinal = p_low )
                    INNER JOIN gao_fiberdevice    tb2 ON ( tb2.gao_fdno = tb1.gao_fdno )
                    INNER JOIN tb_min_material    tb3 ON ( tb3.min_material = tb2.gao_material )
                WHERE
                    tb3.g3e_fid = p_fid;

        END;

        RETURN v_equip_side;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END fun_get_equip_side;


/*******************************************************************************************************
**  fun_get_fiber_out_ports :   TO GET vmx_n_fiber_out_ports maxmium ports for the particular equipement
*********************************************************************************************************/
function fun_get_fiber_out_ports
    ( p_min_material in varchar2
    )
    return number as
    v_out  number;

BEGIN

SELECT MAX(GAO_DEVICEORDINAL)
INTO v_out
FROM GAO_FIBERPORT TB0
INNER JOIN GAO_FIBERPORTGROUP TB1 ON (TB1.GAO_FPGNO = TB0.GAO_FPGNO)
INNER JOIN GAO_FIBERDEVICE TB2 ON (TB2.GAO_FDNO = TB1.GAO_FDNO)
--INNER JOIN B$GC_NETELEM TB3 ON (TB3.MIN_MATERIAL = TB2.GAO_MATERIAL)
WHERE TB2.GAO_MATERIAL  = p_min_material;

RETURN  v_out;

exception
    when others then
        return null;
end fun_get_fiber_out_ports;

/*******************************************************************************************************
**  fun_feature_name : to get FEATURE_name for report         
*********************************************************************************************************/
function fun_feature_name
    ( p_fno in number)
    return varchar2 as
    v_out  varchar2(200);

begin

    SELECT LOWER(feature_name)||'/'
    into v_out
    FROM TB_FEATURE
    WHERE G3E_FNO=p_fno;


    return v_out;
exception
    when others then
        return null;
end fun_feature_name;
/*******************************************************************************************************
**  fun_get_equip_name : to get FEATURE_name for EQUIPMENT           
*********************************************************************************************************/
function fun_get_equip_name
    (   P_FID in number ,
        p_fno in number
    )
    return varchar2 as
    v_out  varchar2(2000):=NULL;
               v_count NUMBER:=0;


begin
               IF P_FNO = 12300 THEN
                              SELECT COUNT(1) INTO V_COUNT
                              FROM B$GC_NETELEM WHERE LTT_ID = 0 AND G3e_FNO = P_FNO
                              AND MIN_MATERIAL IN('FTTP_16way_Spli','FTTP_2way_Split','FTTP_32way_Spli','FTTP_4way_Split','XGS_LT_16Port','XGS_NT_8Port','FTTP_8way_Split')
                              AND G3E_FID=P_fid;
                              IF V_COUNT >0 THEN
                              V_OUT:=PKG_DATA_CONNECTOR.FUN_GET_VMX_ID(P_FID,P_FNO);
                              RETURN V_OUT;
                              END IF;

               SELECT COUNT(1) INTO V_COUNT
                              FROM  B$GC_NETELEM WHERE LTT_ID = 0 AND G3e_FNO = P_FNO
                              AND MIN_MATERIAL IN('OR3144H','POC-MOUNT1','POC-MOUNT2','POC-MOUNT3','POC-MOUNT4','TM CO-04','TM CO-04','TM CO-05','TM CO-1-A','TM CO-1-Ad','TM MDU-8632','TM MDU-8632','TM SC-1-B')
                              AND G3E_FID=P_FID;
                              IF V_COUNT >0 THEN
                              V_OUT:=PKG_DATA_CONNECTOR.FUN_GET_VMX_ID(P_FID,12301);
                              RETURN V_OUT;
                              END IF;
    elsif p_fno=4000 then
        SELECT COUNT(1) INTO V_COUNT
                              FROM  B$GC_fduct WHERE LTT_ID = 0 AND G3e_FNO = P_FNO and g3e_fid=p_fid and lower(feature_type)='bundled duct';
        IF V_COUNT >0 THEN
                              V_OUT:=PKG_DATA_CONNECTOR.FUN_GET_VMX_ID(P_FID,4001);
                              RETURN V_OUT;
                              END IF;
        SELECT COUNT(1) INTO V_COUNT
                              FROM  B$GC_fduct WHERE LTT_ID = 0 AND G3e_FNO = P_FNO and g3e_fid=p_fid and lower(feature_type)<>'bundled duct';
        IF V_COUNT >0 THEN
                              V_OUT:=PKG_DATA_CONNECTOR.FUN_GET_VMX_ID(P_FID,4000);
                              RETURN V_OUT;
                              END IF;
               ELSE
                              V_OUT:=PKG_DATA_CONNECTOR.FUN_GET_VMX_ID(P_FID,P_FNO);
               END IF;

               RETURN V_OUT;

EXCEPTION
WHEN OTHERS THEN
NULL;

end fun_get_equip_name;

/*******************************************************************************************************
**  fun_convert_double :   it conver the value into double type with two precision        
*********************************************************************************************************/
function fun_convert_double
( P_VALUE in number)
    return varchar2 as
    V_OUT  varchar2(200);

BEGIN
V_OUT := CASE WHEN P_VALUE = TRUNC(P_VALUE) THEN
            TO_CHAR(P_VALUE,'FM9999999990.00')
            ELSE
            TO_CHAR(P_VALUE,'FM9999999990.00')
            END;

RETURN V_OUT;

EXCEPTION
    WHEN OTHERS THEN
    RETURN NULL;           

END fun_convert_double;




/**************************************************************************************************
************* PROCEDURE PRC_TABLE_MIN_MAX : TO GET MINMUM AND MAXIMUM OF MAIN TABLE
*****************************************************************************************/
PROCEDURE PRC_TABLE_MIN_MAX
(
    P_FNO IN NUMBER,
P_MIN OUT NUMBER,
P_MAX OUT NUMBER
)
AS
V_TABLE_NAME VARCHAR2(3000);
BEGIN
SELECT G3E_TABLE INTO V_TABLE_NAME FROM TB_COMPONENTS WHERE IS_MAIN_TABLE='Y' AND G3E_FNO=P_FNO;
EXECUTE IMMEDIATE 'SELECT MIN(G3E_ID),MAX(G3E_ID) FROM '||V_TABLE_NAME INTO P_MIN,P_MAX ;

END PRC_TABLE_MIN_MAX;

/**************************************************************************************************
************* PROCEDURE PRC_TRACK_FID : TO TRACK ALL FIDs DURING FORWARD SENARIO
*****************************************************************************************/
PROCEDURE PRC_TRACK_FID
(   p_fno IN    NUMBER  )
AS
    v_count         NUMBER;
    v_string1       VARCHAR2(500);
    v_string2       VARCHAR2(1500);
    cur_fid         SYS_REFCURSOR;
    v_fid1          NUMBER;
    v_fid2          NUMBER;
    v_count1        NUMBER:=0;
    v_table_main    VARCHAR2(100);
    v_table_alias   VARCHAR2(10);
    v_string3       VARCHAR2(500);

BEGIN
        -- GET THE COUNT OF FID FROM MAIN TABLE GOING TO PROCESS
        SELECT  g3e_table, table_alias
        INTO v_table_main,v_table_alias
        FROM tb_components
        WHERE g3e_fno = p_fno
        AND UPPER (is_main_table) = 'Y';
        v_string1 := ' select count(1) from ' ||v_table_main ||' where ltt_id = 0 and g3e_fno = '|| p_fno;
        EXECUTE IMMEDIATE v_string1 INTO v_count;
        -- DELETE ALL THE REPORT TABLES BASED ON fno
           DELETE FROM tb_fid_miss_summary_log WHERE g3e_fno = p_fno;
           DELETE FROM tb_fid_miss_detail_log  WHERE g3e_fno = p_fno;
           DELETE FROM tb_fid_duplicate_log WHERE g3e_fno = p_fno;
        -- INSERT THE MAIN TABLE FID COUNTS IN SUMMARY TABLE 
        INSERT INTO tb_fid_miss_summary_log (g3e_fno,table_name ,total_fid,missing_fid,success_fid)
        VALUES (p_fno,v_table_main,v_count,0,v_count);
        --CURSOR FOR PULLING OTHER TABLE FID BASED FNO  
        FOR rec1 IN (SELECT  g3e_table , is_main_table,table_alias
                        FROM tb_components
                        WHERE g3e_fno = p_fno
                        AND UPPER (REQUIRED_FOR_IQGEO) = 'Y'
                        ORDER BY is_main_table
                       )
        LOOP

          IF rec1.is_main_table = 'N' THEN
              -- INSERT ALL MISSING FIDs IN DETAIL TABLE
               EXECUTE IMMEDIATE 'insert into TB_FID_MISS_DETAIL_LOG (G3E_FNO,TABLE_NAME,G3E_FID )
                 select '||p_fno||','||''''||rec1.g3e_table||''''||',tb0.g3e_fid
                 FROM '|| v_table_main||' TB0 left JOIN '||rec1.g3e_table ||' TB2 ON ( TB0.G3E_FID = TB2.G3E_FID AND TB2.LTT_ID = 0 ) 
                 WHERE TB0.LTT_ID = 0 AND TB0.G3e_FNO = '||p_fno ||' and tb2.g3e_fid is null
                 and  not exists (select 1 from TB_FID_MISS_DETAIL_LOG where G3E_FNO = tb0.G3E_FNO and TABLE_NAME = '||''''||rec1.g3e_table||''''||
                ' and G3E_FID = tb0.g3e_fid )';
                -- PULLING COUNT OF PROCESSED FID FOR OTHER MANDATORY TABLES BASED ON FNO
                EXECUTE IMMEDIATE 'select count(DISTINCT ' ||rec1.table_alias||'.G3E_FID)
                 FROM '|| v_table_main||' '||v_table_alias||' JOIN '||rec1.g3e_table ||' '||rec1.table_alias||' ON ('|| v_table_alias||'.G3E_FID = '||rec1.table_alias||'.G3E_FID AND '||rec1.table_alias||'.LTT_ID = 0 ) 
                 WHERE '||v_table_alias||'.LTT_ID = 0 AND '||v_table_alias||'.G3e_FNO = '||p_fno INTO v_count1 ;
            -- DBMS_OUTPUT.PUT_LINE (V_STRING3);
               -- INSERTING DETAILS IN SUMMARY LOG TABLE FOR OTHER MANDATORY TABLES
                INSERT INTO tb_fid_miss_summary_log (g3e_fno,table_name ,total_fid,missing_fid,success_fid)
                VALUES (p_fno,rec1.g3e_table,v_count,v_count-v_count1,v_count1);
                -- TO PULL DUPLICATE FIDs IN EACH TABLE BASED ON FNO
                 EXECUTE IMMEDIATE      'insert into tb_fid_duplicate_log (g3e_fno, table_name,g3e_fid, duplicate_cnt )'||
                    ' select '||p_fno||','''||rec1.g3e_table||''','||rec1.table_alias||'.G3E_FID , count(1)
                 FROM '|| v_table_main||' '||v_table_alias||' JOIN '||rec1.g3e_table ||' '||rec1.table_alias||' ON ('|| v_table_alias||'.G3E_FID = '||rec1.table_alias||'.G3E_FID AND '||rec1.table_alias||'.LTT_ID = 0 ) 
                 WHERE '||v_table_alias||'.LTT_ID = 0 AND '||v_table_alias||'.G3e_FNO = '||p_fno
                 ||' GROUP BY '||p_fno||','''||rec1.g3e_table||''','||rec1.table_alias||'.G3E_FID HAVING COUNT(1) > 1';
             --dbms_output.put_line (v_string3);
        END IF;
    END LOOP;


    COMMIT;
EXCEPTION
     WHEN OTHERS THEN
     NULL;
END PRC_TRACK_FID;
/**********************************************************************
** prc_upd_splice_connect_temp : TO UPDATE MODIFICATION NUMBER IN tb_splice_connect FOR TYPE 2 (UPDATE)
*************************************************************************/
PROCEDURE prc_upd_splice_connect_temp
AS
begin
for rec0 in (select * from tb_splice_connect where in_MODIFICATIONNUMBER is null)
loop
FOR REC1 IN (  select MODIFICATIONNUMBER,g3e_cid   
                from GAO_FIBERTABLEMODLOG
                where g3e_fID =rec0.in_fid
                AND TABLENAME = 'GC_FELEMENT'
                and TO_DATE(MODIFIEDDATE, 'DD-MON-YYYY') >= TO_DATE(SYSDATE - 1, 'DD-MON-YYYY')
                and type =2
                and ltt_mode = 'POST'
                order by MODIFICATIONNUMBER
                    )
    LOOP

          update TB_splice_connect
          set IN_MODIFICATIONNUMBER = rec1.MODIFICATIONNUMBER
           WHERE IN_LOW <= REC1.g3e_cid
           AND IN_HIGH >= REC1.g3e_cid
           and IN_MODIFICATIONNUMBER is null;

    END LOOP;
end loop;
for rec0 in (select * from tb_splice_connect where out_MODIFICATIONNUMBER is null)
loop
FOR REC1 IN (  select MODIFICATIONNUMBER,g3e_cid   
                from GAO_FIBERTABLEMODLOG
                where g3e_fID =rec0.out_fid
                AND TABLENAME = 'GC_FELEMENT'
                 and TO_DATE(MODIFIEDDATE, 'DD-MON-YYYY') >= TO_DATE(SYSDATE - 1, 'DD-MON-YYYY')
                and type =2
                and ltt_mode = 'POST'
                order by MODIFICATIONNUMBER
                    )
    LOOP

          update TB_splice_connect
          set out_MODIFICATIONNUMBER = rec1.MODIFICATIONNUMBER
           WHERE out_LOW <= REC1.g3e_cid
           AND out_HIGH >= REC1.g3e_cid
           and out_MODIFICATIONNUMBER is null;

    END LOOP;
end loop;
COMMIT;
end prc_upd_splice_connect_temp;
/**********************************************************************
** PRC_AREA_FILTER : To generate sql for CSV based on feature and area wise
*************************************************************************/
PROCEDURE PRC_GCOMS_AREA_FILTER
(   P_FNO           IN NUMBER,
               P_area                                IN VARCHAR2,
    p_query         OUT VARCHAR2
    )
AS
                              V_FNO  NUMBER;
BEGIN
        IF P_FNO IN (7201,7202,7203) THEN
           V_FNO := 7200;
        ELSIF P_FNO IN(11801,11802,11803,11804) THEN
            V_FNO := 11800;
        ELSIF P_FNO = 12301 THEN
            V_FNO := 12300;
                              ELSIF P_FNO = 4001 THEN
            V_FNO := 4000;
        ELSE
           V_FNO := P_FNO;
        END IF;
                              PRC_MIG_GCOMS_FEATURE(P_FNO,NULL,'insert',p_query);

                              IF P_FNO = 11803 THEN
            p_query := REPLACE (p_query, 'LVL BETWEEN IN_LOW AND IN_HIGH ','LVL BETWEEN IN_LOW AND IN_HIGH AND EXISTS (SELECT 1 FROM TB_FID_REGION_WISE WHERE G3E_FID = tb0.G3E_FID )');
        ELSIF P_FNO=11802 THEN
            p_query := REPLACE (p_query, 'LVL BETWEEN IN_LOW AND IN_HIGH ','LVL BETWEEN IN_LOW AND IN_HIGH AND EXISTS (SELECT 1 FROM TB_FID_REGION_WISE WHERE  G3E_FID = tb0.G3E_FID  )');
        ELSIF P_FNO=11804 THEN
            p_query := p_query || ' AND EXISTS (SELECT 1 FROM TB_FID_REGION_WISE WHERE   G3E_FID = tb0.G3E_FID )';      
        --ELSIF P_FNO IN (12300,12301) THEN
            --p_query := p_query || q'[ AND EXISTS (SELECT 1 from B$GC_NETELEM where g3e_fno=12300 AND G3e_fid= tb0.g3e_fid AND switch_centre_clli = 'Belfast' )]';
        ELSE
            p_query := p_query || ' AND EXISTS (SELECT 1 FROM TB_FID_REGION_WISE WHERE G3E_FID = TB0.G3E_FID  )';
        END IF;
        --DBMS_OUTPUT.PUT_LINE('Final SQL Query: ' || p_query);

END PRC_GCOMS_AREA_FILTER;

/**********************************************************************
** PRC_MIG_GCOMS_FEATURE : To generate sql for CSV based on feature
*************************************************************************/
PROCEDURE PRC_MIG_GCOMS_FEATURE
(   P_FNO           IN NUMBER,
    P_FID           IN NUMBER,
    P_DML           IN VARCHAR2 DEFAULT 'insert',
    p_query         out VARCHAR2
    )
AS

                L_COUNT   NUMBER := 0;
                v_fno  NUMBER;
                V_LOOP NUMBER :=0;
                V_STRING VARCHAR2(5000) := null;
                V_STRING1 VARCHAR2(5000):= null;
                V_STRING0 VARCHAR2(1000):= null;
                v_MAIN_ALIAS VARCHAR2(10);
                V_TABLE_NAME VARCHAR2(200):=null;
                V_IN_HIGH NUMBER :=0;
                                                            V_REGION VARCHAR(10);


BEGIN
      IF UPPER (P_DML) = 'DELETE' AND P_FNO =11801 THEN
        p_query := Q'[select distinct LTT_STATUS vmx_change_type,pkg_data_connector.fun_get_vmx_id(g3e_fid,g3e_fno) vmx_housing, pkg_data_connector.FUN_FEATURE_NAME(in_ftype)||in_fid cable1, in_low cable1_low,in_high cable1_high,pkg_data_connector.FUN_FEATURE_NAME(out_ftype)||out_fid cable2, out_low cable2_low,out_high cable2_high from TB_splice_connect ]';
       ELSIF UPPER (P_DML) = 'DELETE' AND P_FNO =11802 THEN  
        P_QUERY := q'[ SELECT DISTINCT LTT_STATUS as vmx_change_type,pkg_data_connector.fun_get_vmx_id(g3e_fid,g3e_fno) as structure,DECODE(IN_FTYPE,7200,pkg_data_connector.fun_get_equip_name(OUT_fid, OUT_ftype) ,pkg_data_connector.fun_get_equip_name(iN_fid, in_ftype)) as equip, DECODE(IN_FTYPE,7200,pkg_data_connector.fun_get_port_name(OUT_ftype,OUT_fid,OUT_LOW), pkg_data_connector.fun_get_port_name(in_ftype,in_fid,IN_LOW)) as port_name, ]'||
                            'DECODE(IN_FTYPE,7200,pkg_data_connector.fun_get_vmx_id(IN_fid,IN_ftype),pkg_data_connector.fun_get_vmx_id(out_fid,out_ftype) )as cable,'||
                           ' DECODE(IN_FTYPE,7200,IN_LOW,out_low) AS fiber_no FROM  tb_splice_connect ';
       ELSIF UPPER (P_DML) = 'DELETE' AND P_FNO =11804 THEN  
        P_QUERY :=  q'[ SELECT distinct LTT_STATUS as vmx_change_type,pkg_data_connector.fun_get_vmx_id(g3e_fid,g3e_fno) as structure,DECODE(IN_FTYPE,7200,pkg_data_connector.fun_get_equip_name(OUT_fid, OUT_ftype) ,pkg_data_connector.fun_get_equip_name(iN_fid, in_ftype)) as equip, decode (in_ftype,7200,pkg_data_connector.fun_get_equip_side(out_fid, out_low),pkg_data_connector.fun_get_equip_side(in_fid, in_low)) equip_side,]'||
                            'DECODE(IN_FTYPE,7200,pkg_data_connector.fun_get_RXPorts(out_fid,out_low),pkg_data_connector.fun_get_RXPorts(iN_fid,in_low)) equip_low ,'||
                            'DECODE(IN_FTYPE,7200,pkg_data_connector.fun_get_RXPorts(out_fid,out_high),pkg_data_connector.fun_get_RXPorts(iN_fid,in_high)) equip_high,'||
                            'DECODE(IN_FTYPE,7200,pkg_data_connector.fun_get_equip_name(IN_fid,IN_ftype),pkg_data_connector.fun_get_equip_name(out_fid,out_ftype) )as cable,'||
                            'DECODE(IN_FTYPE,7200,in_low,out_low) cable_low,'||
                            'DECODE(IN_FTYPE,7200,in_high,out_high)  cable_high'||
                           ' FROM  tb_splice_connect ';
      ELSIF UPPER (P_DML) = 'DELETE' AND P_FNO =11803 THEN 
        p_query := q'[ SELECT distinct LTT_STATUS as vmx_change_type,pkg_data_connector.fun_get_vmx_id(g3e_fid,g3e_fno) as structure,pkg_data_connector.fun_get_vmx_id(in_fid, in_ftype)  as equip1, pkg_data_connector.fun_get_port_name(in_ftype,in_fid,in_low) as equip1_port_name, ]'||
                            'pkg_data_connector.fun_get_vmx_id(out_fid,out_ftype) as equp2,'||
                           ' pkg_data_connector.fun_get_port_name(out_ftype,out_fid,out_low) AS equip2_port_name FROM  tb_splice_connect ';


      END IF;
      IF UPPER (P_DML) = 'DELETE' AND P_FNO not in( 11801,11803,11802,11804) THEN
         FOR REC0 IN ( 
                            SELECT  *
                        FROM (
                                        SELECT   COLUMN_ORDER,DATA_EXCHANGE_FIELD
                                    FROM tb_components TC
                                    INNER join DATA_MAPPING DM on (tc.G3E_TABLE = dm.table_name)
                                    where  TC.G3E_FNO = DM.G3E_FNO
                                    AND upper (TC.REQUIRED_FOR_IQGEO) = 'Y'
                                    and upper (dm.required_for_iqgeo) = 'Y'
                                    and TC.G3E_FNO = P_FNO
                                    and dm.DATA_EXCHANGE_FIELD is not null
                                    )

                        WHERE COLUMN_ORDER IS NOT NULL
                        ORDER BY COLUMN_ORDER                     
                    )                  
        LOOP
        IF UPPER (REC0.DATA_EXCHANGE_FIELD ) ='VMX_ID'  THEN
                V_STRING := V_STRING || 'pkg_data_connector.fun_get_vmx_id ( '||P_FID||','||P_FNO||' ) as '||REC0.DATA_EXCHANGE_FIELD||',';
        ELSIF UPPER (REC0.DATA_EXCHANGE_FIELD ) ='VMX_CHANGE_TYPE'  THEN
                V_STRING := V_STRING || ''''||P_DML||''''||' as '||REC0.DATA_EXCHANGE_FIELD||',';       
        ELSE
            V_STRING := V_STRING ||' NULL AS '||REC0.DATA_EXCHANGE_FIELD||',';
        END IF;
            p_query := 'select '||RTRIM(V_STRING,',')||' from tb_cdc_process ';
        END LOOP;

      elsif UPPER (P_DML) in ( 'INSERT','UPDATE') THEN

        IF P_FNO IN (7201,7202,7203) THEN
           V_FNO := 7200;
        ELSIF P_FNO IN(11801,11802,11803,11804) THEN
            V_FNO := 11800;
        ELSIF P_FNO = 12301 THEN
            V_FNO := 12300;
                              ELSIF P_FNO = 4001 THEN
            V_FNO := 4000;
        ELSE
           V_FNO := P_FNO;
        END IF;
   --- Cursor for pulling columns as per the order
        FOR REC1 IN ( 
                            SELECT  *
                        FROM (
                                        SELECT   TC.G3E_TABLE ,TC.IS_MAIN_table,DM.COLUMN_NAME,COLUMN_ORDER,TC.TABLE_ALIAS,DATA_EXCHANGE_FIELD,TC.FEAT_USERNAME,DM.DATA_TYPE
                                    FROM tb_components TC
                                    INNER join DATA_MAPPING DM on (tc.G3E_TABLE = dm.table_name)
                                    where  TC.G3E_FNO = DM.G3E_FNO
                                    AND upper (TC.REQUIRED_FOR_IQGEO) = 'Y'
                                    and upper (dm.required_for_iqgeo) = 'Y'
                                    and TC.G3E_FNO = P_FNO
                                    and dm.DATA_EXCHANGE_FIELD is not null
                                    )

                        WHERE COLUMN_ORDER IS NOT NULL
                        ORDER BY COLUMN_ORDER                     
                    )                  
        LOOP


            IF upper ( REC1.IS_MAIN_TABLE) = 'Y'  THEN 
                v_MAIN_ALIAS := REC1.TABLE_ALIAS;

            END IF;

            IF REC1.COLUMN_NAME = 'G3E_GEOMETRY' AND UPPER (REC1.DATA_EXCHANGE_FIELD ) <> 'VMX_ORIENTATION' AND  UPPER (REC1.DATA_EXCHANGE_FIELD ) <> 'VMX_LABEL_ORIENTATION' THEN
                    --IF P_FNO IN(11800,7200,7201,7202,7203) THEN
                      --  V_STRING := V_STRING||'PKG_DATA_CONNECTOR.fun_get_wkb(NVL('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME|| ','||fun_get_table_alias( REPLACE(REC1.G3E_TABLE ,'B$GC','B$DGC' ),P_FNO)||'.'||REC1.COLUMN_NAME||')) as ' || REC1.DATA_EXCHANGE_FIELD || ',';
                    --ELSE
                    V_STRING := V_STRING||'PKG_DATA_CONNECTOR.fun_get_wkb('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';
                    --END IF;

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'VMX_ORIENTATION'  OR UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'VMX_LABEL_ORIENTATION'  THEN
                --V_STRING := V_STRING || 'pkg_data_connector.fun_convert_double(PKG_DATA_CONNECTOR.fun_get_orientation ('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME|| ')) as ' || REC1.DATA_EXCHANGE_FIELD || ',';
                                                            V_STRING := V_STRING || 'pkg_data_connector.fun_convert_double(PKG_DATA_CONNECTOR.fun_get_orientation ('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||','||PKG_DATA_CONNECTOR.fun_get_table_alias('B$GC_NETELEM',P_FNO)||'.REGION )) as ' || REC1.DATA_EXCHANGE_FIELD || ',';
                --V_STRING := V_STRING||'LTRIM (TO_CHAR(PKG_DATA_CONNECTOR.fun_get_orientation ('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME|| '),'||q'['999999.99')) as ]' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF REC1.G3E_TABLE = 'B$GC_CONTAIN' OR REC1.G3E_TABLE = 'B$GC_FCBL' AND UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'VMX_HOUSINGS' THEN
                V_STRING := V_STRING||'pkg_data_connector.fun_get_conduit ('||v_MAIN_ALIAS||'.G3E_FID,'||V_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF (UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'VMX_HOUSING' OR UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'VMX_HOUSINGS' OR UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'VMX_BUNDLE') AND P_FNO NOT IN (11801,7200)  THEN
                V_STRING := V_STRING||'pkg_data_connector.fun_get_housing('||v_MAIN_ALIAS||'.g3e_fid,'||V_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

                                             ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'VMX_HOUSING' AND P_FNO = 11801 THEN
                V_STRING := V_STRING||'pkg_data_connector.fun_get_vmx_id('||v_MAIN_ALIAS||'.g3e_fid,'||v_MAIN_ALIAS||'.g3e_fNO ) as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'VMX_STRUCTURE' THEN
                V_STRING := V_STRING||'pkg_data_connector.fun_get_housing('||v_MAIN_ALIAS||'.g3e_fid,'||P_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'VMX_CHANGE_TYPE' THEN
                V_STRING := V_STRING||''''||P_DML||''''||' as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'VMX_VALIDATED' THEN
                V_STRING := V_STRING||''''||'false'||''''||' as ' || REC1.DATA_EXCHANGE_FIELD || ','; 

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='VMX_IN_EQUIP'  THEN
                V_STRING :=  V_STRING||'pkg_data_connector.fun_get_in_equip ('||v_MAIN_ALIAS||'.G3E_FID,'||V_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF  UPPER (REC1.DATA_EXCHANGE_FIELD ) ='VMX_OUT_EQUIP'  THEN
                V_STRING :=  V_STRING||'pkg_data_connector.fun_get_out_equip ('||v_MAIN_ALIAS||'.G3E_FID,'||V_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF  UPPER (REC1.DATA_EXCHANGE_FIELD ) ='VMX_N_DUCTS'  THEN
                V_STRING :=  V_STRING||'pkg_data_connector.fun_get_num_ducts ('||v_MAIN_ALIAS||'.G3E_FID,'||V_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF  UPPER (REC1.DATA_EXCHANGE_FIELD ) ='VMX_N_FIBER_PORTS' AND P_FNO != 12301 THEN
                V_STRING :=  V_STRING||'pkg_data_connector.fun_get_fiber_ports ('||v_MAIN_ALIAS||'.G3E_FID,'||V_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='VMX_ID'  THEN
                                                            IF P_FNO IN (7201,7202,7203) THEN
                                                                           V_STRING := V_STRING || 'pkg_data_connector.fun_get_vmx_id ('||v_MAIN_ALIAS||'.G3E_ID,'||P_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';
                                                            ELSE
                                                                           V_STRING := V_STRING || 'pkg_data_connector.fun_get_vmx_id ('||v_MAIN_ALIAS||'.G3E_FID,'||P_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';
                                                            END IF;

                                             ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='STRUCTURE' AND P_FNO IN (11802,11803,11804) THEN
                                                            V_STRING := V_STRING || 'pkg_data_connector.fun_get_vmx_id ('||v_MAIN_ALIAS||'.G3E_FID,'||v_MAIN_ALIAS||'.G3E_FNO) as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='VMX_CABLE' THEN
                V_STRING := V_STRING || 'pkg_data_connector.fun_get_equip_name('||v_MAIN_ALIAS||'.G3E_FID,'||v_MAIN_ALIAS||'.G3E_FNO'|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='VMX_MANHOLE'  THEN
                V_STRING := V_STRING || 'pkg_data_connector.fun_get_vmx_manhole ('||v_MAIN_ALIAS||'.G3E_FID,'||P_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='VMX_IN_STRUCTURE'  THEN
                V_STRING := V_STRING || 'pkg_data_connector.fun_get_vmx_in_structure ('||v_MAIN_ALIAS||'.G3E_FID,'||P_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='VMX_OUT_STRUCTURE'  THEN
                V_STRING := V_STRING || 'pkg_data_connector.fun_get_vmx_out_structure ('||v_MAIN_ALIAS||'.G3E_FID,'||P_FNO|| ') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='PORT_NAME' THEN

                                                            V_STRING := V_STRING || ' decode(in_ftype, 7200,pkg_data_connector.fun_get_port_name(tb0.out_ftype, tb0.out_fid, tb0.out_low + ROW_NUMBER()
            OVER(PARTITION BY g3e_id ORDER BY g3e_id) - 1),pkg_data_connector.fun_get_port_name(tb0.in_ftype, tb0.in_fid, tb0.in_low + ROW_NUMBER()
OVER(PARTITION BY g3e_id ORDER BY g3e_id) - 1) ) AS ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='FIBER_NO' THEN
                V_STRING := V_STRING || 'decode(in_ftype, 7200,IN_LOW,out_low)+ROW_NUMBER() OVER (PARTITION BY G3E_ID ORDER BY G3E_ID) -1  as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='EQUIP1_PORT_NAME'  THEN
                V_STRING := V_STRING || ' pkg_data_connector.fun_get_port_name ('||v_MAIN_ALIAS||'.IN_FTYPE,'||v_MAIN_ALIAS||'.IN_FID,'||v_MAIN_ALIAS||'.IN_LOW+ ROW_NUMBER()OVER(PARTITION BY g3e_id ORDER BY g3e_id) - 1 ) as ' || REC1.DATA_EXCHANGE_FIELD || ',';
                                                            --V_STRING := V_STRING || 'LVL as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='EQUIP2_PORT_NAME'  THEN
                V_STRING := V_STRING || ' pkg_data_connector.fun_get_port_name ('||v_MAIN_ALIAS||'.OUT_FTYPE,'||v_MAIN_ALIAS||'.OUT_FID,'||v_MAIN_ALIAS||'.OUT_LOW+ROW_NUMBER() OVER (PARTITION BY G3E_ID ORDER BY G3E_ID) -1 ) as ' || REC1.DATA_EXCHANGE_FIELD || ',';
                                                            --V_STRING := V_STRING || 'OUT_LOW+ROW_NUMBER() OVER (PARTITION BY G3E_ID ORDER BY G3E_ID) -1 as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='VMX_N_FIBER_OUT_PORTS' OR (UPPER (REC1.DATA_EXCHANGE_FIELD ) ='VMX_N_FIBER_PORTS' AND P_FNO = 12301) THEN
                V_STRING := V_STRING || 'pkg_data_connector.fun_get_fiber_out_ports ('||REC1.TABLE_ALIAS||'.MIN_MATERIAL ) as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_TYPE ) = 'DATE' THEN
                V_STRING := V_STRING || 'TO_CHAR('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME|| ',''YYYY-MM-DD'') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='CABLE1' THEN
                V_STRING := V_STRING || 'CONCAT(pkg_data_connector.fun_feature_name('||v_MAIN_ALIAS||'.IN_FTYPE),'||v_MAIN_ALIAS||'.IN_FID ) as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='CABLE2' THEN
                V_STRING := V_STRING || 'CONCAT(pkg_data_connector.fun_feature_name('||v_MAIN_ALIAS||'.OUT_FTYPE),'||v_MAIN_ALIAS||'.OUT_FID ) as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.COLUMN_NAME ) = 'DIAMETER' AND P_FNO = 7200 THEN
                V_STRING := V_STRING || 'DECODE (LENGTH(TO_CHAR(MOD(ABS('||v_MAIN_ALIAS||'.'||REC1.COLUMN_NAME||'),1)))-1,0,'||v_MAIN_ALIAS||'.'||REC1.COLUMN_NAME||q'[||'.00',1,]'||v_MAIN_ALIAS||'.'||REC1.COLUMN_NAME||q'[||'0') as ]' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.COLUMN_NAME ) =  'ACTUAL_LENGTH' OR UPPER (REC1.COLUMN_NAME ) = 'PLANNED_LENGTH' OR        
                UPPER (REC1.DATA_EXCHANGE_FIELD ) ='ADDR_DISTANCE' OR UPPER (REC1.DATA_EXCHANGE_FIELD ) ='SADDR_DISTANCE' OR
                UPPER (REC1.DATA_EXCHANGE_FIELD ) ='LENGTH_IN_TRENCH' OR
                UPPER (REC1.DATA_EXCHANGE_FIELD ) ='MEASURED_LENGTH' OR UPPER (REC1.DATA_EXCHANGE_FIELD ) ='SLACK_START_LOCATION' OR
                UPPER (REC1.DATA_EXCHANGE_FIELD ) ='NUMBER_OF_COAX_TUBES' OR UPPER (REC1.DATA_EXCHANGE_FIELD ) ='H_FREQ_ACTUAL' THEN
                V_STRING := V_STRING || 'pkg_data_connector.fun_convert_double('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||')  as ' || REC1.DATA_EXCHANGE_FIELD || ',';
                --V_STRING := V_STRING || 'DECODE ( TRUNC('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||'),0,TO_CHAR('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||','||q'['FM9999999990.00'),TO_CHAR(]'||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||','||q'['FM9999999990.00')) as ]' || REC1.DATA_EXCHANGE_FIELD || ',';
                --V_STRING := V_STRING || 'DECODE (LENGTH(TO_CHAR(MOD(ABS('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||'),1)))-1,0,'||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||q'[||'.00',1,]'||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||q'[||'0',2,]'||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||' ) as ' || REC1.DATA_EXCHANGE_FIELD || ',';

                 --V_STRING := V_STRING || 'to_binary_float('||v_MAIN_ALIAS||'.'||REC1.COLUMN_NAME||') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='TOTAL_LENGTH' AND  P_FNO = 9100 THEN
                V_STRING := V_STRING || 'pkg_data_connector.fun_convert_double('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||')  as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF  UPPER (REC1.DATA_EXCHANGE_FIELD ) ='EQUIP1'  THEN
                V_STRING := V_STRING || 'pkg_data_connector.fun_get_equip_name ('||v_MAIN_ALIAS||'.IN_FID,'||v_MAIN_ALIAS||'.IN_FTYPE ) as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'VMX_LABEL_ALIGNMENT' OR UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'PIA_STRUCT_OBJECTID' OR
            UPPER (REC1.DATA_EXCHANGE_FIELD ) ='TOTAL_LENGTH' THEN
                V_STRING := V_STRING || 'ROUND('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'POSITION' AND P_FNO IN (12300,12301) THEN
                V_STRING := V_STRING || 'ROUND('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF (UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'HEIGHT' OR UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'WIDTH' OR UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'DEPTH' OR UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'LENGTH' OR UPPER (REC1.DATA_EXCHANGE_FIELD ) = 'POLE_LENGTH') AND P_FNO !=2700 THEN
                V_STRING := V_STRING || 'ROUND('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF (UPPER (REC1.DATA_EXCHANGE_FIELD ) =  'HEIGHT' OR UPPER (REC1.DATA_EXCHANGE_FIELD  ) = 'WIDTH' OR
            UPPER (REC1.DATA_EXCHANGE_FIELD  ) = 'LENGTH' OR UPPER (REC1.DATA_EXCHANGE_FIELD  ) = 'FRAME_SIZE' OR
            UPPER (REC1.DATA_EXCHANGE_FIELD  ) = 'COVER_DIAMETER') and P_FNO = 2700 THEN
                V_STRING := V_STRING || 'pkg_data_connector.fun_convert_double('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||')  as ' || REC1.DATA_EXCHANGE_FIELD || ',';
                --V_STRING := V_STRING || 'DECODE (LENGTH(TO_CHAR(MOD(ABS('||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||'),1)))-1,0,'||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||q'[||'.00',1,]'||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME||q'[||'0' ) as ]' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF  UPPER (REC1.DATA_EXCHANGE_FIELD ) ='EQUIP2' THEN
                V_STRING := V_STRING || 'pkg_data_connector.fun_get_equip_name ('||v_MAIN_ALIAS||'.OUT_FID,'||v_MAIN_ALIAS||'.OUT_FTYPE ) as ' || REC1.DATA_EXCHANGE_FIELD || ',';
                --V_STRING := V_STRING || 'DECODE(IN_FTYPE,7200,''RX'',''TX'') as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='EQUIP_SIDE' THEN
                V_STRING := V_STRING || 'decode (in_ftype,7200,pkg_data_connector.fun_get_equip_side(out_fid, out_low) , pkg_data_connector.fun_get_equip_side(in_fid, in_low) )  as ' || REC1.DATA_EXCHANGE_FIELD || ',';
            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='EQUIP_LOW' THEN
                V_STRING := V_STRING || 'decode ( in_ftype,7200,pkg_data_connector.fun_get_RXPorts(tb0.out_fid,TB0.out_low),pkg_data_connector.fun_get_RXPorts(tb0.in_fid,tb0.in_low )) as ' || REC1.DATA_EXCHANGE_FIELD || ',';
            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='EQUIP_HIGH' THEN
                V_STRING := V_STRING || 'decode ( in_ftype,7200,pkg_data_connector.fun_get_RXPorts(tb0.out_fid,TB0.out_high),pkg_data_connector.fun_get_RXPorts(tb0.in_fid,tb0.IN_HIGH)) as ' || REC1.DATA_EXCHANGE_FIELD || ',';
           ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='CABLE_LOW' THEN
                V_STRING := V_STRING || 'decode ( in_ftype,7200,TB0.in_low,tb0.out_low ) as ' || REC1.DATA_EXCHANGE_FIELD || ',';
            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='CABLE_HIGH' THEN
                V_STRING := V_STRING || 'decode ( in_ftype,7200,TB0.IN_high,tb0.OUT_HIGH) as ' || REC1.DATA_EXCHANGE_FIELD || ',';        
            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='EQUIP' THEN
                V_STRING := V_STRING || 'decode ( in_ftype,7200,pkg_data_connector.fun_get_equip_name(out_fid,out_ftype),
  pkg_data_connector.fun_get_equip_name(in_fid, in_ftype)) as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIF UPPER (REC1.DATA_EXCHANGE_FIELD ) ='CABLE'  THEN
                V_STRING := V_STRING || 'decode ( in_ftype,7200,pkg_data_connector.fun_get_vmx_id(tb0.in_fid, tb0.in_ftype),
  pkg_data_connector.fun_get_equip_name(tb0.out_fid, tb0.out_ftype)) as ' || REC1.DATA_EXCHANGE_FIELD || ',';

            ELSIf REC1.COLUMN_NAME is not null then
                V_STRING := V_STRING||REC1.TABLE_ALIAS||'.'||REC1.COLUMN_NAME|| ' as ' || REC1.DATA_EXCHANGE_FIELD || ',';
            END IF;
        END LOOP;

        -- Cursor to create the From clause                        
        FOR REC2 IN (  SELECT  TC.G3E_TABLE ,TC.IS_MAIN_table,TC.TABLE_ALIAS
                        FROM tb_components TC
                        where TC.G3E_FNO = P_FNO
                        AND upper (TC.REQUIRED_FOR_IQGEO) = 'Y' )
        LOOP
            IF upper ( REC2.IS_MAIN_TABLE) = 'Y'    THEN     
                V_STRING0 := REC2.G3E_TABLE ||' '||REC2.TABLE_ALIAS;
            ELSE
                V_STRING1 := V_STRING1 ||chr(10)||' LEFT JOIN '||REC2.G3E_TABLE ||' '||REC2.TABLE_ALIAS||' ON ( '||v_MAIN_ALIAS||'.G3E_FID = '||REC2.TABLE_ALIAS||'.G3E_FID AND '||REC2.TABLE_ALIAS||'.'||'LTT_ID = 0 ) ';
            END IF;

        END LOOP;


       p_query := 'SELECT ' ||RTRIM(V_STRING,',')||chr(10)||' FROM '||V_STRING0||V_STRING1||' WHERE '||v_MAIN_ALIAS||'.LTT_ID = 0 AND '||v_MAIN_ALIAS||'.G3e_FNO = '||V_FNO;
       IF P_FNO = 7203 THEN
          p_query := 'SELECT ' ||RTRIM(V_STRING,',')||chr(10)||' FROM '||V_STRING0||V_STRING1||' WHERE '||v_MAIN_ALIAS||'.LTT_ID = 0 AND '||v_MAIN_ALIAS||'.G3e_FNO = 7200';
          END IF;
        IF P_FNO = 11803 THEN
        /**** To improve the performance query result inserted into a table ****************************/
        execute immediate ' TRUNCATE TABLE tb_level_patchlead ';
        insert into tb_level_patchlead
            SELECT
                    level lvl
            FROM
                    dual
            CONNECT BY
                    level < 2000;
        /***************************************************************************************************/
        SELECT MAX(IN_HIGH) +2
            INTO  V_IN_HIGH
            FROM B$GC_SPLICE_CONNECT
            WHERE G3E_FNO <> 12400
            AND G3E_FNO <> 12400
            AND IN_FTYPE IN (12300,12200,15900)
            AND OUT_FTYPE IN (12300,12200,15900);
        p_query :=  REPLACE (p_query,'FROM B$GC_SPLICE_CONNECT TB0',' FROM B$GC_SPLICE_CONNECT TB0,tb_level_patchlead TB1 ');
        p_query :=  REPLACE (p_query,'TB0.G3e_FNO = 11800','G3E_FNO <> 12400') || ' AND IN_FTYPE IN (12300,12200,15900) AND OUT_FTYPE IN (12300,12200,15900) AND  tb1.LVL BETWEEN IN_LOW AND IN_HIGH ORDER BY G3E_ID,LVL';
        --p_query := REPLACE (p_query,'ROWNUM AS UNIQUE_ID,','');
        p_query := 'SELECT TB0.* FROM ('||p_query||') TB0';

                              ELSIF P_FNO = 11801 THEN
                                             p_query :=  REPLACE (p_query,'TB0.G3e_FNO = 11800', ' OUT_FTYPE=7200 AND IN_FTYPE=7200 AND G3E_FNO IN (11800,15700)');

        ELSIF P_FNO = 11802 THEN
            SELECT MAX(IN_HIGH) +2
            INTO  V_IN_HIGH
            FROM B$GC_SPLICE_CONNECT
            WHERE G3E_FNO <> 12400
            AND IN_FTYPE = 12300
            AND OUT_FTYPE =7200;
            p_query :=  REPLACE (p_query,'FROM B$GC_SPLICE_CONNECT TB0','FROM B$GC_SPLICE_CONNECT TB0,tb_level_patchlead TB2 ');
            p_query :=  REPLACE (p_query,'TB0.G3e_FNO = 11800','G3E_FNO <> 12400') || '  AND (( in_ftype = 7200 and out_ftype = 12300) or (in_ftype = 12300 and out_ftype = 7200 )) AND  LVL BETWEEN IN_LOW AND IN_HIGH  ORDER BY G3E_ID,LVL';
            --p_query := REPLACE (p_query,'ROWNUM AS UNIQUE_ID,','');
            p_query := 'SELECT TB0.* FROM ('||p_query||') TB0';
         --p_query :=  REPLACE (p_query,'TB0.G3e_FNO = 11800','G3E_FNO <> 12400') || ' AND IN_FTYPE IN (12300,12200,15900) AND OUT_FTYPE =7200 ' ;
         ELSIF P_FNO = 11804 THEN
             p_query :=  REPLACE (p_query,'TB0.G3e_FNO = 11800','G3E_FNO <> 12400') || ' AND (( in_ftype = 7200 and out_ftype in( 12200,15900 )) or (in_ftype in( 12200,15900 ) and out_ftype = 7200 ))';

        ELSIF V_FNO = 12300 THEN

            IF P_FNO = 12301 THEN

                p_query := p_query || ' AND MIN_MATERIAL IN(''OR3144H'',''POC-MOUNT1'',''POC-MOUNT2'',''POC-MOUNT3'',''POC-MOUNT4'',''TM CO-04'',''TM CO-04'',''TM CO-05'',''TM CO-1-A'',''TM CO-1-Ad'',''TM MDU-8632'',''TM MDU-8632'',''TM SC-1-B'')';
            ELSE

                p_query := p_query || ' AND MIN_MATERIAL IN(''FTTP_16way_Spli'',''FTTP_2way_Split'',''FTTP_32way_Spli'',''FTTP_4way_Split'',''XGS_LT_16Port'',''XGS_NT_8Port'',''FTTP_8way_Split'')';
            END IF;
                              ELSIF V_FNO =4000 THEN
                                             IF P_FNO =4001 THEN
                                                            p_query :=  REPLACE (p_query,'AND TB0.G3e_FNO = 4000',' AND (UPPER(tb0.feature_type)=''BUNDLED DUCT'' OR tb0.feature_type is null)  AND TB0.G3e_FNO = 4000');
                                             ELSE
                                                            p_query :=  REPLACE (p_query,'AND TB0.G3e_FNO = 4000',' AND (UPPER(tb0.feature_type)!=''BUNDLED DUCT'' OR tb0.feature_type is null) AND TB0.G3e_FNO = 4000');
                                             END IF;
        END IF;


    --BELFAST
    /*
        IF P_FNO = 11803 THEN
            p_query := REPLACE (p_query, 'LVL BETWEEN IN_LOW AND IN_HIGH ','LVL BETWEEN IN_LOW AND IN_HIGH AND EXISTS (SELECT 1 FROM TB_FID_REGION_WISE WHERE G3E_FID = IN_FID AND G3E_FNO =12200 ' || q'[ AND AREA_NAME = 'Belfast' )]');
        ELSIF P_FNO=11802 THEN
            p_query := REPLACE (p_query, 'LVL BETWEEN IN_LOW AND IN_HIGH ','LVL BETWEEN IN_LOW AND IN_HIGH AND EXISTS (SELECT 1 FROM TB_FID_REGION_WISE WHERE  G3E_FID = IN_FID AND G3E_FNO =12200 ' || q'[ AND AREA_NAME = 'Belfast' )]');
        ELSIF P_FNO=11804 THEN
            p_query := p_query || ' AND EXISTS (SELECT 1 FROM TB_FID_REGION_WISE WHERE   G3E_FID = IN_FID AND G3E_FNO =12200 ' || q'[ AND AREA_NAME = 'Belfast' )]';      
        --ELSIF P_FNO IN (12300,12301) THEN
            --p_query := p_query || q'[ AND EXISTS (SELECT 1 from B$GC_NETELEM where g3e_fno=12300 AND G3e_fid= tb0.g3e_fid AND switch_centre_clli = 'Belfast' )]';
        ELSE
            p_query := p_query || ' AND EXISTS (SELECT 1 FROM TB_FID_REGION_WISE WHERE G3E_FID = TB0.G3E_FID AND G3E_FNO ='||V_FNO||q'[ AND AREA_NAME = 'Belfast' )]';
        END IF;
        */
        /*
        IF P_FNO = 2200 THEN
            p_query := 'Create table '||fun_table_name(P_FNO)||' as '||p_query;
            execute immediate p_query;
        END IF;

        V_TABLE_NAME := pkg_data_connector.fun_table_name(P_FNO);
    */


         IF P_FID IS NOT NULL THEN
             IF P_FNO IN(11802,11803) THEN
                p_query :=  REPLACE (p_query,'ORDER BY G3E_ID,LVL) TB0','AND TB0.G3E_FID = ')|| P_FID|| ' ORDER BY G3E_ID,LVL) TB0';
             ELSE
             p_query:= p_query|| ' AND TB0.G3E_FID = ' || P_FID;
             END IF;
         END IF;



  end if;     
  END PRC_MIG_GCOMS_FEATURE;

END PKG_DATA_CONNECTOR;
