from datetime import datetime, timedelta

2from airflow import DAG

3from airflow.operators.python_operator import PythonOperator

4from airflow.providers.oracle.hooks.oracle import OracleHook

5import sys

6from airflow.operators.python_operator import ShortCircuitOperator

7import time

8import csv

9import cx_Oracle

10from airflow.hooks.base_hook import BaseHook

11import  sys

12import pandas as pd

13import os

14import zipfile

15import shutil

16import smtplib

17from airflow.models import Variable

18from email.message import EmailMessage

19import pytz

20

21default_args = {

22    'owner': 'airflow',

23    'depends_on_past': False,

24    'start_date': datetime(2023, 12, 1),

25    'retries': 0,

26    'retry_delay': timedelta(minutes=5),

27}

28

29dag = DAG('forward_cdc_data_connector',

30          default_args=default_args,

31          schedule_interval=None,  # Adjust the schedule as needed

32          catchup=False)

33

34###### DB other

35

36def get_oracle_connection(conn_id):

37    conn = BaseHook.get_connection(conn_id)

38    return {

39        'user': conn.login,

40        'password': conn.password,

41        'dsn': cx_Oracle.makedsn(conn.host, conn.port, service_name=conn.schema)

42    }

43   

44

45####### Setup DB other

46

47def setup_connection():

48    try:

49        conn_id = 'gcomm-dev-db'

50        oracle_conn = get_oracle_connection(conn_id)

51        connection = cx_Oracle.connect(user=oracle_conn['user'], password=oracle_conn['password'], dsn=oracle_conn['dsn'])

52        return connection

53

54    except cx_Oracle.DatabaseError as db_error:

55        print("Failed to connect to the database: {db_error}")

56        raise

57

58def get_reverse_dag_state():

59    from airflow.models import DagRun

60   

61   # current_datetime = datetime.utcnow()  

62    current_datetime = datetime.now(tz=pytz.utc)

63    check_value=True

64   

65    # Find the most recent DAG run that is not in the state "None"

66    dagrun = DagRun.find(dag_id='Reverse_data_conn_test_dag')

67    # If a DAG run is found, retrieve its state

68    #print("the dagrun is",dagrun)

69    if dagrun:

70        dag_state = dagrun[-1].state

71    else:

72        dag_state = 'None'  # No DAG run found at the exact present time

73   # Variable.set('reverse_dag_state', dag_state)

74    print("Thedag state is",dag_state)

75    if dag_state == "running" :

76        check_value=False

77    return bool(check_value)   

78

79

80

81def fetch_query(**kwargs):

82    connection = None

83    cursor = None

84    connection = setup_connection()

85    cursor = connection.cursor()

86    current_datetime = datetime.now().strftime("%d%m%Y_%H%M%S")

87    v_query = cursor.var(str)

88    data_list = []

89

90    #### Triggering the CDC procedure 

91

92    cursor.callproc("PKG_DATA_CONNECTOR.PRC_CDC_PROCESS", [v_query])

93    v_query_value = v_query.getvalue()

94    print(v_query_value)

95    if v_query_value is None:

96

97        print("No CDC data is present in the GCOMMS at the current_date_time",current_datetime)

98    kwargs['ti'].xcom_push(key='data_list_key', value=data_list)

99    kwargs['ti'].xcom_push(key='current_datetime',value=current_datetime)

100    kwargs['ti'].xcom_push(key='query_key', value=v_query_value)

101    return bool(v_query_value)

102       

103

104def data_extract_to_csv(**kwargs):

105

106    #### function to execute the query  fetch the data  and write inte into csv files 

107

108    data_list1= kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features',key='data_list_key')

109    v_query_value = kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features', key='query_key')

110    current_datetime=kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features', key='current_datetime')

111    print(v_query_value)   

112    flag = True

113    maxRow = 1000000

114    sequence = 1

115    folder_name=''

116    while v_query_value is not None:

117

118            ### #splitting the query to take the feature name and giving it as csv file name

119

120            individual_query = v_query_value.split(';')[0].strip()

121            csv_name = v_query_value.split(';')[-1].strip().rstrip('/')

122

123            ### defining the object names to give it as foldername for respective features

124

125            structure_objects = ['building', 'closure', 'manhole', 'pole', 'tower', 'or_planning_structure']

126            equipment_objects = ['room', 'fiber_splice_enclosure', 'fiber_rack', 'fiber_shelf', 'fiber_patch_panel','fiber_splitter', 'fiber_filter', 'cassette', 'fiber_blanking_plate']

127            conduit_objects = ['conduit', 'fiber_duct','fiber_duct_bundle', 'swept_tee', 'or_planning_duct', 'fiber_inner_duct']

128            cable_objects = ['fiber_cable', 'fiber_cable_label', 'fiber_slack', 'fiber']

129            connection_objects = ['splice', 'port_connection', 'port_range_connection', 'patch_lead']

130            other_objects = ['cable', 'coax_cable', 'area_boundary']

131

132            if csv_name in structure_objects:

133                folder_name='structures'

134            elif csv_name in equipment_objects:

135                folder_name='equipment'

136            elif csv_name in conduit_objects:

137                folder_name='conduits'

138            elif csv_name in cable_objects:

139                folder_name='cables'

140            elif csv_name in connection_objects:

141                folder_name='connections'

142            else:

143                folder_name='other'

144            folder_path = f"/usr/data/GCOMM_IQGEO/process/job_cdc_{current_datetime}/{folder_name}"

145            print('folder_path ',folder_path)

146            print('csv name', csv_name)

147            os.makedirs(folder_path, exist_ok=True)

148            connection = None

149            cursor = None

150            connection = setup_connection()

151            cursor = connection.cursor()

152            tss = time.time()

153            cursor.execute(individual_query)

154            rows = cursor.fetchall()

155            te = time.time()

156            execution_time = te - tss

157            db_count = len(rows)

158            print('db_count',db_count)

159            print("Sql execution time", te - tss)

160

161            #Fetching column names and converting them to lowercase

162

163            column_names = [col[0].lower() for col in cursor.description]

164            for start in range(0, len(rows), maxRow):

165                stop = start + maxRow

166                chunk = rows[start:stop]

167

168               # Writing column names and the data in to CSV file

169

170                with open(f"{folder_path}/{csv_name}.{sequence}.csv", 'w', newline='', encoding='utf-8') as file:

171                        te1=time.time()

172                        csv_writer = csv.writer(file)

173                        csv_writer.writerow(column_names)

174                        file_count = len(chunk)

175                        csv_writer.writerows(chunk)

176                        te2 = time.time() 

177                        data_export = te2 - te1

178                        print(sequence, "  Data extraction with CSV file completed. t- ", te2 - te1)

179                        sequence += 1

180                        data_list1.append([csv_name, execution_time, data_export, db_count, file_count,1 ])

181                        kwargs['ti'].xcom_push(key='data_list_key', value=data_list1)

182

183            #####Triggering the procedure for next time for the next feature, This process will be continous untill the procedures returns no query

184

185            v_query = cursor.var(str)

186            cursor.callproc("PKG_DATA_CONNECTOR.PRC_CDC_PROCESS", [v_query])

187            v_query_value = v_query.getvalue()

188            print(v_query_value)

189            sequence = 1

190

191

192def fetch_query2(**kwargs):

193

194    current_datetime=kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features', key='current_datetime')

195    connection = None

196    cursor = None

197    connection = setup_connection()

198    cursor = connection.cursor()

199    current_datetime = datetime.now().strftime("%d%m%Y_%H%M%S")

200    v_query = cursor.var(str)

201

202    #### Triggering the CDC procedure 

203

204    cursor.callproc("PKG_DATA_CONNECTOR.PRC_CDC_PROCESS_FIBER", [v_query])

205    v_query_value2 = v_query.getvalue()

206    print(v_query_value2)

207    if v_query_value2 is None:

208        print("No CDC data is present in the GCOMMS at the current_date_time",current_datetime)

209

210    kwargs['ti'].xcom_push(key='query_key', value=v_query_value2)

211    return bool(v_query_value2)

212

213def data_extract_to_csv2(**kwargs):

214

215    #### function to execute the query  fetch the data  and write inte into csv files 

216

217    data_list2= kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features',key='data_list_key')

218    v_query_value2 = kwargs['ti'].xcom_pull(task_ids='fetch_query_for_fiber_task', key='query_key')

219    current_datetime=kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features', key='current_datetime')

220    print(v_query_value2)   

221    flag = True

222    maxRow = 1000000

223    sequence = 1

224    folder_name=''

225    while v_query_value2 is not None:

226

227            ### #splitting the query to take the feature name and giving it as csv file name

228

229            individual_query = v_query_value2.split(';')[0].strip()

230            csv_name = v_query_value2.split(';')[-1].strip().rstrip('/')

231

232            ### defining the object names to give it as foldername for respective features

233

234            structure_objects = ['building', 'closure', 'manhole', 'pole', 'tower', 'or_planning_structure']

235            equipment_objects = ['room', 'fiber_splice_enclosure', 'fiber_rack', 'fiber_shelf', 'fiber_patch_panel','fiber_splitter', 'fiber_filter', 'cassette', 'fiber_blanking_plate']

236            conduit_objects = ['conduit', 'fiber_duct','fiber_duct_bundle', 'swept_tee', 'or_planning_duct', 'fiber_inner_duct']

237            cable_objects = ['fiber_cable', 'fiber_cable_label', 'fiber_slack', 'fiber']

238            connection_objects = ['splice', 'port_connection', 'port_range_connection', 'patch_lead']

239            other_objects = ['cable', 'coax_cable', 'area_boundary']

240            if csv_name in structure_objects:

241                folder_name='structures'

242            elif csv_name in equipment_objects:

243                folder_name='equipment'

244            elif csv_name in conduit_objects:

245                folder_name='conduits'

246            elif csv_name in cable_objects:

247                folder_name='cables'

248            elif csv_name in connection_objects:

249                folder_name='connections'

250            else:

251                folder_name='other'

252            folder_path = f"/usr/data/GCOMM_IQGEO/process/job_cdc_{current_datetime}/{folder_name}"

253            print('folder_path ',folder_path)

254            print('csv name', csv_name)

255            os.makedirs(folder_path, exist_ok=True)

256            connection = None

257            cursor = None

258            connection = setup_connection()

259            cursor = connection.cursor()

260            print("individual query is : ",individual_query)

261            tss = time.time()

262            cursor.execute(individual_query)

263            rows = cursor.fetchall()

264            te = time.time()

265            execution_time = te - tss

266            db_count = len(rows)

267            print('db_count',db_count)

268            print("Sql execution time", te - tss)

269

270            #Fetching column names and converting them to lowercase

271

272            column_names = [col[0].lower() for col in cursor.description]

273            for start in range(0, len(rows), maxRow):

274                stop = start + maxRow

275                chunk = rows[start:stop]

276

277

278               # Writing column names and the data in to CSV file

279

280                with open(f"{folder_path}/{csv_name}.{sequence}.csv", 'w', newline='', encoding='utf-8') as file:

281                        te1=time.time()

282                        csv_writer = csv.writer(file)

283                        csv_writer.writerow(column_names)

284                        file_count = len(chunk)

285                        csv_writer.writerows(chunk)

286                        te2 = time.time() 

287                        data_export = te2 - te1

288                        print(sequence, "  Data extraction with CSV file completed. t- ", te2 - te1)

289                        sequence += 1

290                        data_list2.append([csv_name, execution_time, data_export, db_count, file_count,1 ])

291                        kwargs['ti'].xcom_push(key='data_list_key', value=data_list2)

292

293

294            #####Triggering the procedure for next time for the next feature, This process will be continous untill the procedures returns no query

295

296            v_query = cursor.var(str)

297            cursor.callproc("PKG_DATA_CONNECTOR.PRC_CDC_PROCESS_FIBER", [v_query])

298            v_query_value2 = v_query.getvalue()

299            print(v_query_value2)

300            sequence = 1

301

302def fetch_query3(**kwargs):

303

304    current_datetime=kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features', key='current_datetime')

305    connection = None

306    cursor = None

307    connection = setup_connection()

308    cursor = connection.cursor()

309    current_datetime = datetime.now().strftime("%d%m%Y_%H%M%S")

310    v_query = cursor.var(str)

311

312    #### Triggering the CDC procedure 

313

314    cursor.callproc("PKG_DATA_CONNECTOR.PRC_CDC_PROCESS_CONNECTIONS", [v_query])

315    v_query_value3 = v_query.getvalue()

316    print(v_query_value3)

317    if v_query_value3 is None:

318        print("No CDC data is present in the GCOMMS at the current_date_time",current_datetime)

319

320    kwargs['ti'].xcom_push(key='query_key', value=v_query_value3)

321    return bool(v_query_value3)

322def data_extract_to_csv3(**kwargs):

323

324    #### function to execute the query  fetch the data  and write inte into csv files 

325

326    data_list3= kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features',key='data_list_key')

327    v_query_value3 = kwargs['ti'].xcom_pull(task_ids='fetch_query_for_connections_task', key='query_key')

328    current_datetime=kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features', key='current_datetime')

329    print(v_query_value3)   

330    flag = True

331    maxRow = 1000000

332    sequence = 1

333    folder_name=''

334    while v_query_value3 is not None:

335

336            ### #splitting the query to take the feature name and giving it as csv file name

337

338            individual_query = v_query_value3.split(';')[0].strip()

339            csv_name = v_query_value3.split(';')[-1].strip().rstrip('/')

340

341            ### defining the object names to give it as foldername for respective features

342

343            structure_objects = ['building', 'closure', 'manhole', 'pole', 'tower', 'or_planning_structure']

344            equipment_objects = ['room', 'fiber_splice_enclosure', 'fiber_rack', 'fiber_shelf', 'fiber_patch_panel','fiber_splitter', 'fiber_filter', 'cassette', 'fiber_blanking_plate']

345            conduit_objects = ['conduit', 'fiber_duct', 'fiber_duct_bundle','swept_tee', 'or_planning_duct', 'fiber_inner_duct']

346            cable_objects = ['fiber_cable', 'fiber_cable_label', 'fiber_slack', 'fiber']

347            connection_objects = ['splice', 'port_connection', 'port_range_connection', 'patch_lead']

348            other_objects = ['cable', 'coax_cable', 'area_boundary']

349

350            if csv_name in structure_objects:

351                folder_name='structures'

352            elif csv_name in equipment_objects:

353                folder_name='equipment'

354            elif csv_name in conduit_objects:

355                folder_name='conduits'

356            elif csv_name in cable_objects:

357                folder_name='cables'

358            elif csv_name in connection_objects:

359                folder_name='connections'

360            else:

361                folder_name='other'

362            folder_path = f"/usr/data/GCOMM_IQGEO/process/job_cdc_{current_datetime}/{folder_name}"

363            print('folder_path ',folder_path)

364            print('csv name', csv_name)

365            os.makedirs(folder_path, exist_ok=True)

366            connection = None

367            cursor = None

368            connection = setup_connection()

369            cursor = connection.cursor()

370            tss = time.time()

371            cursor.execute(individual_query)

372            rows = cursor.fetchall()

373            te = time.time()

374            execution_time = te - tss

375            db_count = len(rows)

376            print('db_count',db_count)

377            print("Sql execution time", te - tss)

378

379            #Fetching column names and converting them to lowercase

380

381            column_names = [col[0].lower() for col in cursor.description]

382            for start in range(0, len(rows), maxRow):

383                stop = start + maxRow

384                chunk = rows[start:stop]

385

386               # Writing column names and the data in to CSV file

387

388                with open(f"{folder_path}/{csv_name}.{sequence}.csv", 'w', newline='', encoding='utf-8') as file:

389                        te1=time.time()

390                        csv_writer = csv.writer(file)

391                        csv_writer.writerow(column_names)

392                        file_count = len(chunk)

393                        csv_writer.writerows(chunk)

394                        te2 = time.time() 

395                        data_export = te2 - te1

396                        print(sequence, "  Data extraction with CSV file completed. t- ", te2 - te1)

397                        sequence += 1

398                        data_list3.append([csv_name, execution_time, data_export, db_count, file_count,1 ])

399                        kwargs['ti'].xcom_push(key='data_list_key', value=data_list3)

400

401            #####Triggering the procedure for next time for the next feature, This process will be continous untill the procedures returns no query

402

403            v_query = cursor.var(str)

404            cursor.callproc("PKG_DATA_CONNECTOR.PRC_CDC_PROCESS_CONNECTIONS", [v_query])

405            v_query_value3 = v_query.getvalue()

406            print(v_query_value3)

407            sequence = 1

408

409

410

411

412def creating_summary_extraction(**kwargs):

413

414    #####function for writing the summary extraction file

415

416    data_list_1 = kwargs['ti'].xcom_pull(task_ids='data_extract_for_all_remaining_features_task', key='data_list_key') or []

417    ## Pull data_list from data_extract_to_csv2

418    data_list_2 = kwargs['ti'].xcom_pull(task_ids='data_extract_for_fiber_task', key='data_list_key') or []

419    data_list_3 = kwargs['ti'].xcom_pull(task_ids='data_extract_for_connections_tast', key='data_list_key') or []

420    # Combine both data_lists

421    data_list = data_list_1 + data_list_2 + data_list_3

422    print(data_list)

423    current_datetime=kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features', key='current_datetime')

424    summary_file_name = f"/usr/data/GCOMM_IQGEO/extraction_summary/extraction_summary_cdc_{current_datetime}.csv"

425

426    with open(summary_file_name, 'w', newline='', encoding='utf-8') as file:

427        csv_writer = csv.writer(file)

428        csv_writer.writerow(["feature_name", 'execution_time', 'data_export_time', "db_count", "Data_extract_count"])

429    columns = ['feature_name','execution_time','data_export_time','db_count','total_Data_extraction_count_in_files','No_of_csv_files_extracted']

430    df = pd.DataFrame(data_list, columns=columns)

431    columns_to_sum = ['data_export_time','total_Data_extraction_count_in_files','No_of_csv_files_extracted']

432    grouped_value1 = df.groupby('feature_name')[['execution_time','db_count']].first().reset_index()

433    print(grouped_value1) 

434    summed_columns = df.groupby('feature_name')[columns_to_sum].sum().reset_index()

435    print(summed_columns)

436    final_df = pd.merge(grouped_value1, summed_columns, on='feature_name')

437    final_df['total_time']=final_df['execution_time']+final_df['data_export_time']

438    print('final_df',final_df)

439    final_df.to_csv(f"/usr/data/GCOMM_IQGEO/extraction_summary/extraction_summary_cdc_{current_datetime}.csv", index=False)   

440

441########### function to create the metadata file

442

443def metadata_file_creation(**kwargs):

444    current_datetime = kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features', key='current_datetime')

445    folder_path = f'/usr/data/GCOMM_IQGEO/process/job_cdc_{current_datetime}'

446    os.makedirs(folder_path, exist_ok=True)

447    file_path = os.path.join(folder_path, 'metadata.csv')

448    property_names = ['vmx_version', 'design', 'owner', 'owner_email']

449    values = ['v1.12', '', '', '']

450    with open(file_path, 'w', newline='', encoding='utf-8') as file:

451        csv_writer = csv.writer(file)

452        csv_writer.writerow(['property', 'value'])

453        for prop, val in zip(property_names, values):

454            csv_writer.writerow([prop, val])

455

456############# Fucntion to zip the files and move to output folder and move theunzipped folder to archeice directory

457

458def zip_and_move_files(**kwargs):

459    current_datetime=kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features', key='current_datetime')

460    source_folder = f"/usr/data/GCOMM_IQGEO/process/job_cdc_{current_datetime}"

461    archeive_folder = f"/usr/data/GCOMM_IQGEO/archive_process"

462    output_zip = f"/usr/data/GCOMM_IQGEO/process/job_cdc_{current_datetime}.zip"

463    destination_folder = "/usr/data/GCOMM_IQGEO/output"

464

465

466    ### Zip the contents of the source folder

467

468    with zipfile.ZipFile(output_zip, 'w') as zipf:

469      

470        for root, dirs, files in os.walk(source_folder):

471            for file in files:

472                zipf.write(os.path.join(root, file), os.path.relpath(os.path.join(root, file), source_folder))

473

474    ### Moving the zip file to the destination folder

475

476    shutil.move(output_zip, destination_folder)

477

478    #### moving Sourcr folder to Archeive folder

479

480    shutil.move(source_folder, archeive_folder)

481

482def error_handling_report_creation(**kwargs):

483

484    ### function  to get the error handling report

485

486    connection = None

487    cursor = None

488    connection = setup_connection()

489    cursor = connection.cursor()

490    current_datetime=kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features', key='current_datetime')

491    query1 = "SELECT * FROM tb_cdc_process WHERE PROCESSED='E'"

492    cursor.execute(query1)

493    rows = cursor.fetchall()

494    column_names = [col[0].lower() for col in cursor.description]

495    column_names = column_names[0:]

496    with open(f"/usr/data/GCOMM_IQGEO/error_reports/cdc_error_fid_{current_datetime}.csv", 'w', newline='', encoding='utf-8') as file:

497       csv_writer = csv.writer(file)

498       csv_writer.writerow(column_names)

499       for row in rows:

500           csv_writer.writerow(row[0:])

501

502def send_email(recipients,context):

503

504    #############  function to send the email with the summary file attached 

505

506   

507    current_datetime = context['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features', key='current_datetime')

508    sender = 'No-reply@virginmediao2.co.uk'

509    subject = 'Airflow Email'

510    content = 'HI, plesae find the attached Extraction summarty.'

511    msg = EmailMessage()

512    msg['From'] = sender

513    msg['To'] = ', '.join(recipients)

514    msg['Subject'] = subject

515    msg.set_content(content)

516    file_path = f"/usr/data/GCOMM_IQGEO/extraction_summary/extraction_summary_cdc_{current_datetime}.csv"

517

518    with open(file_path, 'rb') as file:

519        filename = os.path.basename(file_path)

520        msg.add_attachment(file.read(), maintype='text', subtype='plain', filename=filename)

521

522

523    try:

524

525        smtp_obj = smtplib.SMTP('localhost')

526        smtp_obj.send_message(msg)

527        smtp_obj.quit()

528        print("Email sent successfully!")

529

530    except Exception as e:

531

532        print("Failed to send email:", str(e))

533def update_query(**kwargs):

534    connection = None

535    cursor = None

536    connection = setup_connection()

537    cursor = connection.cursor()

538    #### Triggering the Update query

539    cursor.execute("UPDATE TB_CDC_PROCESS SET PROCESSED = 'Y' WHERE PROCESSED = 'P'")

540    cursor.execute("TRUNCATE table TB_splice_connect")

541    connection.commit()

542

543update_query_task = PythonOperator(

544    task_id='update_query_task',

545    python_callable=update_query,

546    provide_context=True,

547    dag=dag,

548)   

549creating_metadata_file =  PythonOperator(

550    task_id=f'creating_metadata_file',

551    python_callable=metadata_file_creation,

552    provide_context=True,

553    dag=dag,

554)

555email_task = PythonOperator(

556    task_id='email_task',

557    python_callable=lambda **context: send_email(Variable.get("RECIPIENTS").split(','), context=context),

558    op_kwargs={},

559    dag=dag,

560)

561

562error_handling_task = PythonOperator(

563    task_id='error_handling_task',

564    python_callable=error_handling_report_creation,

565    provide_context=True,

566    dag=dag,

567)

568

569zip_and_move_task = PythonOperator(

570    task_id='zip_and_move_task',

571    python_callable=zip_and_move_files,

572    provide_context=True,

573    dag=dag,

574)

575

576

577fetch_query_for_all_remaining_features = PythonOperator(

578    task_id='fetch_query_for_all_remaining_features',

579    python_callable=fetch_query,

580    provide_context=True,

581    dag=dag,

582)

583

584store_reverse_dag_state_task = ShortCircuitOperator(

585    task_id='store_reverse_dag_state_task',

586    python_callable=get_reverse_dag_state,

587    dag=dag,

588)

589

590

591data_extract_for_all_remaining_features_task = PythonOperator(

592    task_id='data_extract_for_all_remaining_features_task',

593    python_callable=data_extract_to_csv,

594    provide_context=True,

595    dag=dag,

596

597)

598

599fetch_query_for_fiber_task = PythonOperator(

600    task_id='fetch_query_for_fiber_task',

601    python_callable=fetch_query2,

602    provide_context=True,

603    dag=dag,

604)                     

605

606data_extract_for_fiber_task = PythonOperator(

607    task_id='data_extract_for_fiber_task',

608    python_callable=data_extract_to_csv2,

609    provide_context=True,

610    dag=dag,

611)

612

613summary_report = PythonOperator(

614    task_id='summary_task',

615    python_callable=creating_summary_extraction,

616    provide_context=True,

617    dag=dag,

618)

619

620

621def check_fetch_tasks(**kwargs):

622    fetch_query_result = kwargs['ti'].xcom_pull(task_ids='fetch_query_for_all_remaining_features')

623    fetch_query2_result = kwargs['ti'].xcom_pull(task_ids='fetch_query_for_fiber_task')

624    fetch_query3_result = kwargs['ti'].xcom_pull(task_ids='fetch_query_for_connections_task')

625    return fetch_query_result or fetch_query2_result or fetch_query3_result

626

627

628data_validation_task = ShortCircuitOperator(

629    task_id='data_validation_task',

630    python_callable=check_fetch_tasks,

631    provide_context=True,

632    dag=dag,

633)

634

635fetch_query_for_connections_task = PythonOperator(

636    task_id='fetch_query_for_connections_task',

637    python_callable=fetch_query3,

638    provide_context=True,

639    dag=dag,

640)                     

641

642data_extract_for_connections_tast = PythonOperator(

643    task_id='data_extract_for_connections_tast',

644    python_callable=data_extract_to_csv3,

645    provide_context=True,

646    dag=dag,

647)

648

649############ setting up dependencies for the tasks 

650

651store_reverse_dag_state_task >> fetch_query_for_all_remaining_features >>  fetch_query_for_fiber_task >> fetch_query_for_connections_task >> data_validation_task >> data_extract_for_all_remaining_features_task >> data_extract_for_fiber_task >> data_extract_for_connections_tast >> summary_report >> creating_metadata_file >> zip_and_move_task >> update_query_task >> error_handling_task >> email_task

652