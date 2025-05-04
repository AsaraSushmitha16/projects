from datetime import datetime, timedelta

2from airflow import DAG

3from airflow.operators.python_operator import PythonOperator

4from airflow.operators.dagrun_operator import TriggerDagRunOperator

5import sys

6import time

7import csv

8import oracledb

9from oracledb.exceptions import DatabaseError

10import  sys

11import pandas as pd

12import os

13from airflow.providers.oracle.hooks.oracle import OracleHook

14from airflow.operators.bash_operator import BashOperator

15from airflow.models import Variable

16import json

17import zipfile

18import shutil

19import os

20import re

21

22# Define default parameters for the DAG

23default_args = {

24    'owner': 'admin',

25    'depends_on_past': False,

26    'start_date': datetime(2023, 12, 1),

27    'retries': 0,

28    'retry_delay': timedelta(minutes=5),

29}

30

31# Create a DAG instance named 'Reverse_data_conn_test' with the specified parameters

32dag = DAG('Reverse_data_conn_updated_dag',

33          default_args=default_args,

34          schedule_interval=None,  # Adjust the schedule as needed

35          catchup=False)

36

37

38# Define source and destination paths for ZIP files

39source_path='/usr/data/IQGEO_GCOMM/input/'

40destination_path = '/usr/data/IQGEO_GCOMM/process/'

41# Define the error folder path

42error_folder = '/usr/data/IQGEO_GCOMM/error/'

43# Define the bash command to move ZIP files from source to destination

44move_command = f'mv {source_path}job_cdc_*.zip {destination_path}'

45

46

47# Function to list and sort ZIP files in the source folder

48def list_and_sort_zip_files(source_folder):

49    # List all files in the source_folder with a '.zip' extension

50    zip_files = [f for f in os.listdir(source_folder) if f.endswith(".zip")]

51    if not zip_files:

52        raise ValueError("No ZIP files found in the source folder. DAG failed.")

53    # Create a list of tuples, where each tuple contains the filename and its timestamp

54    zip_files_with_timestamp = [(f, os.path.getmtime(os.path.join(source_folder, f))) for f in zip_files]

55    # Sort the list of tuples based on the second element of each tuple (timestamp)

56    return sorted(zip_files_with_timestamp, key=lambda x: x[1])

57   

58

59

60

61# Function to unzip files one by one based on their timestamp

62def unzip_files_one_by_one(**kwargs):

63     # Specify the folder where the ZIP files are located

64    source_folder = '/usr/data/IQGEO_GCOMM/process/'

65

66    # Retrieve the sorted list of ZIP files and their timestamps from XCom

67    sorted_zip_files = kwargs['ti'].xcom_pull(task_ids='list_and_sort_task')

68   

69   # Retrieve the list of previously processed files from XCom

70    processed_files = kwargs['ti'].xcom_pull(task_ids='unzip_files_one_by_one_task', key='return_value') or []

71

72   # Iterate over each tuple in the list of sorted ZIP files

73    for zip_file, _ in sorted_zip_files:

74        # Skip files that have already been processed

75        if zip_file in processed_files:

76            continue

77

78      

79  

80        # Construct the full path to the current ZIP file

81        file_path = os.path.join(source_folder, zip_file)

82

83        # Open the ZIP file for reading

84        with zipfile.ZipFile(file_path, 'r') as zip_ref:

85            # Extract all files from the ZIP archive to the source folder

86            zip_ref.extractall(source_folder)

87       

88       

89        return zip_file

90       # file_name = os.path.splitext(zip_file)[0]

91        processed_files.append(zip_file)  # Add the processed file to the list

92       

93    return processed_files

94

95

96

97table_info_structure = [

98    {'table_name': 'manhole', 'fno_numbers': 2700, 'folder_path': '/usr/data/IQGEO_GCOMM/process/structures'},

99    {'table_name': 'closure', 'fno_numbers': 14900, 'folder_path': '/usr/data/IQGEO_GCOMM/process/structures'},

100    {'table_name': 'or_planning_structure', 'fno_numbers': 5300, 'folder_path': '/usr/data/IQGEO_GCOMM/process/structures'},

101    {'table_name': 'building', 'fno_numbers': 14100, 'folder_path': '/usr/data/IQGEO_GCOMM/process/structures'},

102    {'table_name': 'pole', 'fno_numbers': 20600, 'folder_path': '/usr/data/IQGEO_GCOMM/process/structures'},

103    {'table_name': 'tower', 'fno_numbers': 3200, 'folder_path': '/usr/data/IQGEO_GCOMM/process/structures'},

104]

105

106table_info_equipment = [

107    {'table_name': 'fiber_blanking_plate', 'fno_numbers': 7600, 'folder_path': '/usr/data/IQGEO_GCOMM/process/equipment'},

108    {'table_name': 'cassette', 'fno_numbers': 15900, 'folder_path': '/usr/data/IQGEO_GCOMM/process/equipment'},

109    {'table_name': 'fiber_filter', 'fno_numbers': 12301, 'folder_path': '/usr/data/IQGEO_GCOMM/process/equipment'},

110    {'table_name': 'fiber_splitter', 'fno_numbers': 12300, 'folder_path': '/usr/data/IQGEO_GCOMM/process/equipment'},

111    {'table_name': 'fiber_patch_panel', 'fno_numbers': 12200, 'folder_path': '/usr/data/IQGEO_GCOMM/process/equipment'},

112    {'table_name': 'fiber_shelf', 'fno_numbers': 15800, 'folder_path': '/usr/data/IQGEO_GCOMM/process/equipment'},

113    {'table_name': 'fiber_rack', 'fno_numbers': 15700, 'folder_path': '/usr/data/IQGEO_GCOMM/process/equipment'},

114    {'table_name': 'fiber_splice_enclosure', 'fno_numbers': 11800,

115     'folder_path': '/usr/data/IQGEO_GCOMM/process/equipment'},

116    {'table_name': 'room', 'fno_numbers': 14200, 'folder_path': '/usr/data/IQGEO_GCOMM/process/equipment'},

117]

118

119table_info_conduits = [

120    {'table_name': 'conduit', 'fno_numbers': 2200, 'folder_path': '/usr/data/IQGEO_GCOMM/process/conduits'},

121    {'table_name': 'fiber_duct', 'fno_numbers': 4000, 'folder_path': '/usr/data/IQGEO_GCOMM/process/conduits'},

122    {'table_name': 'fiber_inner_duct', 'fno_numbers': 4100, 'folder_path': '/usr/data/IQGEO_GCOMM/process/conduits'},

123    {'table_name': 'swept_tee', 'fno_numbers': 9100, 'folder_path': '/usr/data/IQGEO_GCOMM/process/conduits'},

124    {'table_name': 'or_planning_duct', 'fno_numbers': 5200, 'folder_path': '/usr/data/IQGEO_GCOMM/process/conduits'},

125    {'table_name': 'fiber_duct_bundle', 'fno_numbers': 4001, 'folder_path': '/usr/data/IQGEO_GCOMM/process/conduits'},

126]

127

128table_info_cable = [

129    {'table_name': 'fiber_cable', 'fno_numbers': 7200, 'folder_path': '/usr/data/IQGEO_GCOMM/process/cables'},

130    {'table_name': 'fiber_cable_label', 'fno_numbers': 7201, 'folder_path': '/usr/data/IQGEO_GCOMM/process/cables'},

131    {'table_name': 'fiber_slack', 'fno_numbers': 7202, 'folder_path': '/usr/data/IQGEO_GCOMM/process/cables'},

132    {'table_name': 'fiber', 'fno_numbers': 7203, 'folder_path': '/usr/data/IQGEO_GCOMM/process/cables'},

133

134]

135

136table_info_connections = [

137    {'table_name': 'splice', 'fno_numbers': 11801, 'folder_path': '/usr/data/IQGEO_GCOMM/process/connections'},

138    {'table_name': 'port_connection', 'fno_numbers': 11802, 'folder_path':

139'/usr/data/IQGEO_GCOMM/process/connections'},

140    {'table_name': 'port_range_connection', 'fno_numbers': 11804, 'folder_path': '/usr/data/IQGEO_GCOMM/process/connections'},

141    {'table_name': 'patch_lead', 'fno_numbers': 11803, 'folder_path': '/usr/data/IQGEO_GCOMM/process/connections'},

142

143]

144

145table_info_other = [

146    {'table_name': 'area_boundary', 'fno_numbers': 8000, 'folder_path': '/usr/data/IQGEO_GCOMM/process/other'},

147]      

148

149table_info_categories = {

150    'structures': table_info_structure,

151    'equipment': table_info_equipment,

152    'conduits': table_info_conduits,

153    'cables': table_info_cable,

154    'connections': table_info_connections,

155    'other' : table_info_other,

156   

157}

158def get_dynamic_table_info(folder_path):

159    result = []

160

161    for category, category_info_list in table_info_categories.items():

162        category_path = os.path.join(folder_path, category.lower())  # Assuming category names are lowercase

163        if os.path.exists(category_path):

164            print(f"{', '.join([table_info['table_name'] for table_info in category_info_list])} found in {category}")

165            result += category_info_list 

166            print(result)

167    if not result:

168        print("No folder found")

169

170    return result

171

172# Function to load data into tables

173def load_data_into_tables(zip_file , **kwargs):

174    folder_path = '/usr/data/IQGEO_GCOMM/process/'

175  

176    # Connect to the Oracle database using the configured connection in Airflow

177    oracle_conn_id = "gcomm-test-db"

178    oracle_hook = OracleHook(oracle_conn_id=oracle_conn_id)

179    connection = oracle_hook.get_conn()

180    cursor = connection.cursor()

181    print("connected")

182    try:

183       

184       dynamic_table_info = get_dynamic_table_info(folder_path)

185       for entry in dynamic_table_info:

186          fno_numbers = entry['fno_numbers']

187          table_name = entry['table_name']

188          folder_path = entry['folder_path']

189          print(f"Processing entry - fno_numbers: {fno_numbers}, table_name: {table_name}")

190          csv_file_pattern = f"{table_name}.*.csv"

191          print(csv_file_pattern) 

192          csv_files = [file for file in os.listdir(folder_path) if csv_file_pattern.split('.')[0]==file.split('.')[0]]

193          print(csv_files)

194          if len(csv_files)>0:

195            csv_file_path = os.path.join(folder_path, csv_files[0])

196            print(csv_file_path)

197

198            with open(csv_file_path, 'r') as csv_files:

199              csv_reader=csv.reader(csv_files)

200              next(csv_reader)

201              for row in csv_reader:

202                           

203                              

204                  if table_name in ['fiber_cable_label','fiber_cable']:    

205                        row.append(None)

206                  elif table_name in ['splice','port_connection','port_range_connection','patch_lead']:

207                        row.extend([None, None])   

208                

209                  num_columns = len(row)

210                  placeholders = ','.join([':{}'.format(i + 1) for i in range(num_columns)])

211                  query = f"INSERT INTO TB_{fno_numbers}_{table_name} VALUES ({placeholders})"

212                  print(query)

213                  cursor.execute(query, row)

214            connection.commit()

215            print("Data loaded successfully.")

216    except Exception as e:

217        connection.rollback()

218    

219        print(f"Error loading data: {e}")

220      

221        raise Exception("Some Error occurred")

222    

223

224    finally:

225        connection.close() 

226

227  

228 

229def call_stored_procedure(zip_file, **kwargs):

230   

231    folder_path = '/usr/data/IQGEO_GCOMM/process/'

232    dynamic_table_info = get_dynamic_table_info(folder_path)

233    file_moved = False

234  

235    for table_info_entry in dynamic_table_info:

236      oracle_conn_id = "gcomm-test-db"

237      oracle_hook = OracleHook(oracle_conn_id=oracle_conn_id)

238      connection = oracle_hook.get_conn()

239      cursor = connection.cursor()

240

241      try:

242        fno_numbers = table_info_entry['fno_numbers']

243        filename = os.path.splitext(zip_file)[0]

244       

245        v_query = cursor.var(oracledb.STRING)

246

247        cursor.execute("DELETE FROM TB_REVERSE_RUNTIME_LOG")

248        print("table deleted")

249        # Call the stored procedure with the output parameter P_status

250        cursor.callproc("PKG_DATA_CONNECTOR_REVERSE.PRC_REVERSE_MAIN", [filename,'delete',v_query])

251        print("Deleted")

252        cursor.callproc("PKG_DATA_CONNECTOR_REVERSE.PRC_REVERSE_MAIN", [filename,'insert',v_query])

253        print("Inserted")

254        cursor.callproc("PKG_DATA_CONNECTOR_REVERSE.PRC_REVERSE_MAIN", [filename,'update',v_query])

255        print("Updated")

256

257

258       #calling below procedure for temporary testing for connections

259       # cursor.callproc("PKG_DATA_CONNECTOR_REVERSE_CONNECTIONS.PRC_REVERSE_MAIN", ['delete',v_query])

260        #print("Deleted")

261

262        #cursor.callproc("PKG_DATA_CONNECTOR_REVERSE_CONNECTIONS.PRC_REVERSE_MAIN", ['insert',v_query])

263       # print("Inserted")

264

265       # cursor.callproc("PKG_DATA_CONNECTOR_REVERSE_CONNECTIONS.PRC_REVERSE_MAIN", ['update',v_query])

266       # print("Updated")

267

268        # Get the value of the output parameter

269        p_status= v_query.getvalue()

270       

271        # Simulate a failure condition

272      

273        if p_status == 'S':

274            print("Task successful: no errors")

275        elif p_status == 'F':

276            print(f"Task failed: {fno_numbers}")

277    

278            raise Exception("Some error occurred")

279          

280           

281      except oracledb.DatabaseError as e:

282        connection.rollback()

283   

284        print(f"Error: {e}")

285        raise Exception("Some error occurred")

286      

287      

288       

289      finally:

290        # Close the database connection

291        connection.close()

292       

293def runtime_log_task(**kwargs):

294    oracle_conn_id = "gcomm-test-db"

295    oracle_hook = OracleHook(oracle_conn_id=oracle_conn_id)

296    connection = oracle_hook.get_conn()

297    cursor = connection.cursor()

298    print("connected")

299

300    try:

301

302    # Execute the SQL query

303       cursor.execute("SELECT * FROM TB_REVERSE_RUNTIME_LOG")

304

305    # Fetch all rows from the result set

306       rows = cursor.fetchall()

307

308    # Print each row

309       for row in rows:

310           print(row)

311    except Exception as e:

312        connection.rollback()

313    

314        print(f"Error loading data: {e}")

315      

316        raise Exception("Some Error occurred")

317    finally:

318        connection.close()

319

320def move_to_archive(zip_file, **kwargs):

321    source_folder = '/usr/data/IQGEO_GCOMM/process/'

322    archive_folder = '/usr/data/IQGEO_GCOMM/archive/'

323   

324    # Remove the ".zip" extension from the least timestamp ZIP file

325    archive_dir_name = os.path.splitext(zip_file)[0]

326

327    # Create a directory in the archive folder with the name of the processed ZIP file

328    archive_directory = os.path.join(archive_folder, f"{archive_dir_name}")

329    os.makedirs(archive_directory, exist_ok=True)

330

331    # Move the original ZIP file to the archive directory

332    source_zip_file = os.path.join(source_folder, zip_file)

333    destination_zip_file = os.path.join(archive_directory, zip_file)

334

335    # Check if the source ZIP file exists before attempting to move it

336    if os.path.exists(source_zip_file):

337        try:

338            # Move the original ZIP file to the archive directory

339            shutil.move(source_zip_file, destination_zip_file)

340            print(f"Moved ZIP file {zip_file} to {archive_directory}")

341

342            # Move all unzipped items (files and directories) to the archive directory

343            for item in os.listdir(source_folder):

344                source_item = os.path.join(source_folder, item)

345                destination_item = os.path.join(archive_directory, item)

346

347                # Check if the item is a directory before moving

348                if os.path.isdir(source_item):

349                    shutil.move(source_item, destination_item)

350                    print(f"Moved directory {item} to {archive_directory}")

351                else:

352                    shutil.move(source_item, destination_item)

353                    print(f"Moved file {item} to {archive_directory}")

354        except shutil.Error as e:

355            # Ignore the error caused by the destination path already existing

356            if "already exists" not in str(e):

357                raise

358           

359    else:  

360       print (f"Error: Source file {source_zip_file} not found.")

361                             

362    

363

364def move_to_error(zip_file, **kwargs):

365    # Define source and error directories

366    source_folder = '/usr/data/IQGEO_GCOMM/process/'

367    error_directory = '/usr/data/IQGEO_GCOMM/error/'

368

369    # Create a directory in the error folder with the name of the processed ZIP file

370    error_dir_name = os.path.splitext(zip_file)[0]

371    error_directory = os.path.join(error_directory, f"{error_dir_name}")

372    os.makedirs(error_directory, exist_ok=True)

373

374    # Construct the full paths for the source and destination ZIP files

375    source_zip_file = os.path.join(source_folder, zip_file)

376    destination_zip_file = os.path.join(error_directory, zip_file)

377

378    # Check if the source ZIP file exists before attempting to move it

379    if os.path.exists(source_zip_file):

380        try:

381            # Move the original ZIP file to the error directory

382            shutil.move(source_zip_file, destination_zip_file)

383            print(f"Moved ZIP file {zip_file} to {error_directory}")

384

385            # Move all unzipped items (files and directories) to the error directory

386            for item in os.listdir(source_folder):

387                source_item = os.path.join(source_folder, item)

388                destination_item = os.path.join(error_directory, item)

389

390                # Check if the item is a directory before moving

391                if os.path.isdir(source_item):

392                    shutil.move(source_item, destination_item)

393                    print(f"Moved directory {item} to {error_directory}")

394                else:

395                    shutil.move(source_item, destination_item)

396                    print(f"Moved file {item} to {error_directory}")

397                  

398        except shutil.Error as e:

399            # Ignore the error caused by the destination path already existing

400            if "already exists" not in str(e):

401                raise

402    else:

403        print(f"Error: Source file {source_zip_file} not found.")

404   

405   

406    return 'success'

407

408def check_move_to_error(**kwargs):

409    # Check if the move_to_error_task succeeded

410    move_to_error_task_instance = kwargs['ti'].xcom_pull(task_ids='move_to_error_task', key='return_value')

411    print(move_to_error_task_instance)

412    if move_to_error_task_instance == 'success':

413        raise ValueError("move_to_error_task succeeded. DAG status check failed.")

414    else:

415        print("move_to_error_task failed. DAG status check succeeded.")

416

417# Create the dag_status_check_task

418dag_status_check_task = PythonOperator(

419    task_id='dag_status_check_task',

420    python_callable=check_move_to_error,

421    provide_context=True,

422    #trigger_rule='all_success',  # Trigger rule for the task

423    dag=dag,

424)

425# Create a task to move and unzip files using a BashOperator

426move_and_unzip_task = BashOperator(

427    task_id='move_and_unzip_task',

428    bash_command=move_command,

429    dag=dag,

430)

431

432

433# Create a task to list and sort ZIP files

434list_and_sort_task = PythonOperator(

435    task_id='list_and_sort_task',

436    python_callable=list_and_sort_zip_files,

437    op_args=[source_path],

438    provide_context=True,

439    dag=dag,

440)

441

442# Create a task to move files to the error folder

443move_to_error_task = PythonOperator(

444    task_id='move_to_error_task',

445    python_callable=move_to_error,

446    provide_context=True,

447    op_args=["{{ ti.xcom_pull(task_ids='unzip_files_one_by_one_task') }}"],

448    trigger_rule='all_failed',    # Trigger rule for moving to error folder

449    dag=dag,

450)

451# Create a task to move processed files to the archive

452move_to_archive_task = PythonOperator(

453    task_id='move_to_archive_task',

454    python_callable=move_to_archive,

455    provide_context=True,

456    op_args=["{{ ti.xcom_pull(task_ids='unzip_files_one_by_one_task') }}"],

457    dag=dag,

458)

459

460# Create a task to unzip files one by one

461unzip_files_one_by_one_task = PythonOperator(

462    task_id='unzip_files_one_by_one_task',

463    python_callable=unzip_files_one_by_one,

464    provide_context=True,

465    dag=dag,

466)

467

468#task to read CSV files and load data into tables

469load_data_task = PythonOperator(

470    task_id='load_data_task',

471    python_callable=load_data_into_tables,

472    provide_context=True,

473  #  op_args=[],  # Pass the list as an operational argument

474    op_args=["{{ ti.xcom_pull(task_ids='unzip_files_one_by_one_task') }}"],

475    dag=dag,

476)

477

478# Task to call the stored procedure

479call_procedure_task = PythonOperator(

480    task_id='call_procedure_task',

481    python_callable=call_stored_procedure,

482    provide_context=True,

483  #  op_args=[],

484    op_args=["{{ ti.xcom_pull(task_ids='unzip_files_one_by_one_task') }}"],

485    dag=dag,

486)

487

488runtime_log_task = PythonOperator(

489    task_id='runtime_log_task',

490    python_callable=runtime_log_task,

491    dag=dag

492)

493

494#set dependencies

495list_and_sort_task >> move_and_unzip_task >> unzip_files_one_by_one_task

496unzip_files_one_by_one_task >> load_data_task >>  call_procedure_task >> runtime_log_task >> move_to_archive_task >> move_to_error_task >> dag_status_check_task