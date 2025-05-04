from datetime import datetime, timedelta

2from airflow import DAG

3from airflow.operators.python_operator import PythonOperator

4from airflow.providers.oracle.hooks.oracle import OracleHook

5from airflow.hooks.base_hook import BaseHook

6import sys

7import time

8import csv

9import os

10import cx_Oracle

11import logging

12import pandas as pd

13####### Set the logging level to INFO

14logging.basicConfig(level=logging.INFO)

15logger = logging.getLogger(__name__)

16####### Default Args for DAG

17default_args = {

18    'owner': 'admin',

19    'depends_on_past': False,

20    'start_date': datetime(2024, 1, 1),

21    'retries': 0,

22    'retry_delay': timedelta(minutes=5),

23}

24####### Dag configuration

25dag = DAG(

26    'full_load_structures_data_extraction',

27    default_args=default_args,

28    description='A simple Airflow DAG for Oracle data extraction',

29    schedule_interval=None,  # You can customize the schedule_interval

30)

31####### DB structures

32def get_oracle_connection(conn_id):

33    conn = BaseHook.get_connection(conn_id)

34    return {

35        'user': conn.login,

36        'password': conn.password,

37        'dsn': cx_Oracle.makedsn(conn.host, conn.port, service_name=conn.schema)

38    }

39####### Setup DB structures

40def setup_connection():

41    try:

42        conn_id = 'gcomm-test-db'

43        oracle_conn = get_oracle_connection(conn_id)

44        connection = cx_Oracle.connect(user=oracle_conn['user'], password=oracle_conn['password'], dsn=oracle_conn['dsn'])

45        return connection

46    except cx_Oracle.DatabaseError as db_error:

47        logger.error(f"Failed to connect to the database: {db_error}")

48        raise

49

50

51####### Query Execution

52def execute_query(cursor, fno):

53    try:

54        sequence = 1

55        v_query = cursor.var(str)

56        cursor.callproc('PKG_DATA_CONNECTOR.PRC_GCOMS_AREA_FILTER',[fno,'BELFAST',v_query])

57        #cursor.callproc("PKG_DATA_CONNECTOR.PRC_MIG_GCOMS_FEATURE", [fno, None, 'insert', v_query])

58        query = v_query.getvalue()

59        print("v_query ", v_query)

60        tss_query = time.time()

61        cursor.execute(query)

62        te_query = time.time()

63        logger.info(f"Query executed. Total time taken: {te_query - tss_query}")

64        row_count = cursor.fetchone()

65        if row_count is not None:

66            row_count = row_count[0]

67

68        else:

69            logging.warning("Query did not yield any rows.")

70            row_count = 0

71        #logger.info(f"Row count for the query: {row_count}")

72        return sequence, row_count

73    except cx_Oracle.DatabaseError as db_error:

74        logger.error(f"Error executing the query: {db_error}")

75        raise

76

77######## Data Extraction with Multiple CSV Files ( batch size 100000 record and 1000000 in each csv file)

78def fetch_and_write_csv(cursor, batch_size, folder_path, feature_name, sequence, max_records_per_file):

79    try:

80        records_written = 0

81        total_records_written = 0

82        current_csv_path = None

83        while True:

84            tss_fetch = time.time()

85            rows = cursor.fetchmany(batch_size)

86            te_fetch = time.time()

87            #logger.info(f"Data cursor fetchmany. Time taken: {te_fetch - tss_fetch}")

88            if not rows:

89                break

90            logger.info(f"Data cursor fetchmany. Time taken: {te_fetch - tss_fetch}")  

91            column_names = [col[0].lower() for col in cursor.description]

92            #column_names = column_names[1:]

93            if records_written % max_records_per_file == 0:

94                if current_csv_path:

95                    logger.info(f"CSV file {current_csv_path} reached {max_records_per_file} records.")

96                current_csv_path = os.path.join(folder_path, f"{feature_name}.{(records_written // max_records_per_file)+1}.csv")

97                with open(current_csv_path, 'w', newline='', encoding='utf-8') as file:

98                    tss_file = time.time()

99                    csv_writer = csv.writer(file)

100                    csv_writer.writerow(column_names)

101                    te_file = time.time()

102                    logger.info(f"CSV file created. Time taken: {te_file - tss_file}")

103            with open(current_csv_path, 'a', newline='', encoding='utf-8') as file:

104                tss_file = time.time()

105                csv_writer = csv.writer(file)

106                csv_writer.writerows(rows)

107                te_file = time.time()

108                logger.info(f"Data written to CSV. Time taken: {te_file - tss_file}")

109            records_written += len(rows)

110            total_records_written += len(rows)

111        if current_csv_path:

112            logger.info(f"Last CSV file {current_csv_path} reached {records_written} records.")

113        return total_records_written

114    except cx_Oracle.DatabaseError as db_error:

115        logger.error(f"Error fetching and writing CSV: {db_error}")

116        raise

117

118####### Data Extraction Main functions

119

120summary_data = []     ### Summary report intiated

121def data_extract_to_csv(fno, max_records_per_file, **kwargs):

122    connection = None

123    cursor = None

124    try:

125        connection = setup_connection()

126        cursor = connection.cursor()

127        batch_size = 100000  # Adjust the batch size as needed

128        folder_path = "/usr/data/GCOMM_IQGEO/process/job_fullload/structures"

129        os.makedirs(folder_path, exist_ok=True)

130        for v_fno in fno:

131            feature_name_query = f"select feature_name FROM TB_FEATURE where g3e_fno={v_fno}"  ### To get feature name of FNO from Table

132            cursor.execute(feature_name_query)

133            feature_name = cursor.fetchall()

134            feature_name = feature_name[0][0]

135            feature_name = feature_name.lower()

136            print('feature name', feature_name)

137            #summary_data = []     ### Summary report intiated

138            sequence, row_count = execute_query(cursor, v_fno)

139            total_records_written = 0

140            extraction_start_time = time.time()

141            while True:

142                records_written = fetch_and_write_csv(cursor, batch_size, folder_path, feature_name, sequence, max_records_per_file)

143                total_records_written += records_written

144                sequence += 1

145                if records_written == 0:

146                    break

147            extraction_end_time = time.time()

148            extraction_time = extraction_end_time - extraction_start_time  ## Total Extraction time

149            csv_files = [file for file in os.listdir(folder_path) if file.startswith(f"{feature_name}.")]

150            file_count = len(csv_files)

151            total_data_count_csv = 0

152            for csv_file in csv_files:

153                csv_file_path = os.path.join(folder_path, csv_file)

154                with open(csv_file_path, 'r', encoding='utf-8') as file:

155                     csv_reader = csv.reader(file)

156                     # Skip header row

157                     next(csv_reader, None)

158                     total_data_count_csv += sum(1 for row in csv_reader)

159            summary_data.append([feature_name,  file_count, total_data_count_csv, extraction_time])

160            kwargs['ti'].xcom_push(key='summary_data_key', value=summary_data)

161    finally:

162        # Close the cursor and connection

163        if cursor:

164            cursor.close()

165        if connection:

166            connection.close()

167

168# Creating summary report for the csv data extraction

169def creating_summary_extraction(**kwargs):

170    summary_data = kwargs['ti'].xcom_pull(task_ids='fetch_data_task', key='summary_data_key')

171    current_datetime = datetime.now().strftime("%Y%m%d_%H%M%S")

172    columns = ['feature_name','No_of_csv_files_extracted','total_Data_extraction_count','total_time in sec']

173    summary_df = pd.DataFrame(summary_data, columns=columns)

174    summary_file_path = f'/usr/data/GCOMM_IQGEO/extraction_summary/structures_extraction_summary_{current_datetime}.csv'

175    summary_df.to_csv(summary_file_path, index=False)

176

177# Creating error handling csv

178def fetch_and_write_error_handling_data_to_csv(cursor, csv_prefix, batch_size, max_records_per_file):

179

180

181        row_count = 0

182        file_count = 1

183        column_names = [col[0].lower() for col in cursor.description]

184        # Create the first CSV file

185        csv_file_path = f'{csv_prefix}_{file_count}.csv'

186        csv_writer = csv.writer(open(csv_file_path, 'w', newline='', encoding='utf-8'))

187        csv_writer.writerow(column_names)

188        while True:

189            batch = cursor.fetchmany(batch_size)

190            if not batch:

191                break  # No more rows to fetch

192            for row in batch:

193                csv_writer.writerow(row)

194                row_count += 1

195                if row_count == max_records_per_file:

196                    # Close the current CSV file and create a new one

197                    csv_writer = None

198                    file_count += 1

199                    row_count = 0

200                    csv_file_path = f'{csv_prefix}_{file_count}.csv'

201                    csv_writer = csv.writer(open(csv_file_path, 'w', newline='', encoding='utf-8'))

202                    csv_writer.writerow(column_names)

203

204# creating error handling report

205def error_handling_report_creation(fno_numbers, **kwargs):

206    connection = None

207    cursor = None

208    try:

209        connection = setup_connection()

210        cursor = connection.cursor()

211        batch_size = 10000

212        max_records_per_file = 100000

213        for fid in fno_numbers:     

214           cursor.callproc("PKG_DATA_CONNECTOR.PRC_TRACK_FID", [fid])  

215        query1 = f'select G3E_FNO,TABLE_NAME,G3E_FID,DUPLICATE_CNT  from TB_FID_DUPLICATE_LOG where G3E_FNO in ({fno_numbers[0]},{fno_numbers[1]},{fno_numbers[2]},{fno_numbers[3]},{fno_numbers[4]},{fno_numbers[5]})'

216        cursor.execute(query1)

217        csv_prefix1 = '/usr/data/GCOMM_IQGEO/error_reports/structures_duplicate_fid'

218        fetch_and_write_error_handling_data_to_csv(cursor, csv_prefix1, batch_size, max_records_per_file)

219        query2 = f'select G3E_FNO, TABLE_NAME, G3E_FID from TB_FID_MISS_DETAIL_LOG where G3E_FNO in ({fno_numbers[0]},{fno_numbers[1]},{fno_numbers[2]},{fno_numbers[3]},{fno_numbers[4]},{fno_numbers[5]})'

220        cursor.execute(query2)

221        csv_prefix2 = '/usr/data/GCOMM_IQGEO/error_reports/structures_missing_fid'

222        fetch_and_write_error_handling_data_to_csv(cursor, csv_prefix2, batch_size, max_records_per_file)

223        query3 = f'select G3E_FNO, TABLE_NAME,TOTAL_FID,MISSING_FID, SUCCESS_FID from TB_FID_MISS_SUMMARY_LOG where MISSING_FID <> 0 AND G3E_FNO in ({fno_numbers[0]},{fno_numbers[1]},{fno_numbers[2]},{fno_numbers[3]},{fno_numbers[4]},{fno_numbers[5]})'

224        cursor.execute(query3)

225        csv_prefix3 = '/usr/data/GCOMM_IQGEO/error_reports/structures_missing_fid_summary'

226        fetch_and_write_error_handling_data_to_csv(cursor, csv_prefix3, batch_size, max_records_per_file)

227    finally:

228        # Close the cursor and connection

229        if cursor:

230            cursor.close()

231        if connection:

232            connection.close()

233

234# check for the empty file

235def empty_file_creation(fno_numbers,**kwargs):

236    folder_path = '/usr/data/GCOMM_IQGEO/process/job_fullload/structures'  # Replace with the actual path to your folder

237    file_names = ['manhole.1.csv','tower.1.csv','or_planning_structure.1.csv', 'building.1.csv', 'closure.1.csv','pole.1.csv']

238    connection = None

239    cursor = None

240    for file,v_fno in  zip(file_names, fno_numbers):

241        file_path = os.path.join(folder_path, file)

242        if os.path.exists(file_path):

243            continue

244        else:

245            try:

246                connection = setup_connection()

247                cursor = connection.cursor()

248                sequence = execute_query(cursor, v_fno)

249                column_names = [col[0].lower() for col in cursor.description]

250                column_names = column_names[0:]

251                with open(f"{file_path}", 'w', newline='', encoding='utf-8') as file:

252                    csv_writer = csv.writer(file)

253                    csv_writer.writerow(column_names)

254                print(f"Empty file '{file_path}' created successfully.")

255            finally:

256                # Close the cursor and connection

257                if cursor:

258                    cursor.close()

259                if connection:

260                    connection.close()

261def metadata_file_creation():

262    folder_path = '/usr/data/GCOMM_IQGEO/process/job_fullload/metadata.csv'  # Replace with the actual path to your folder

263    property_names = ['vmx_version', 'design', 'owner', 'owner_email']

264    values = ['v1.11', '', '', '']

265

266    if not os.path.exists(folder_path):

267        with open(folder_path, 'w', newline='', encoding='utf-8') as file:

268            csv_writer = csv.writer(file)

269            csv_writer.writerow(['property', 'value'])

270            for prop, val in zip(property_names, values):

271                csv_writer.writerow([prop, val])

272

273

274fetch_data_task = PythonOperator(

275    task_id='fetch_data_task',

276    python_callable=data_extract_to_csv,

277    provide_context=True,

278    op_kwargs={'fno': [2700, 20600, 14100, 5300, 3200, 14900], 'max_records_per_file': 1000000},

279    dag=dag,

280)

281summary_report_task = PythonOperator(

282    task_id=f'summary_report_task',

283    python_callable=creating_summary_extraction,

284    provide_context=True,

285    dag=dag,

286)

287error_handling = PythonOperator(

288    task_id=f'error_handling_task',

289    python_callable=error_handling_report_creation,

290    provide_context=True,

291    op_kwargs={'fno_numbers': [2700, 3200, 20600, 14100, 5300,  14900]},

292    dag=dag,

293)

294checking_empty_files =  PythonOperator(

295    task_id=f'checking_files',

296    python_callable=empty_file_creation,

297    provide_context=True,

298    op_kwargs={'fno_numbers': [2700, 3200, 5300, 14100, 14900, 20600]},

299    dag=dag,

300)

301creating_metadeta_file =  PythonOperator(

302    task_id=f'creating_metadeta_file',

303    python_callable=metadata_file_creation,

304    provide_context=True,

305    dag=dag,

306)

307fetch_data_task >> summary_report_task >> error_handling >> checking_empty_files >> creating_metadeta_file

308