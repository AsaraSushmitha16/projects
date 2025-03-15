my project is migration of GIS data its a telecom application(GIS)
there are 3 ways we have done it
1)forward that is gcomms to iqgeo that means changing longitude and latitude to binary data and other filtrations generally forward in the sense old data migration
2)cdc(change data capture) this is also gcoms() to iqgeo() but todays new data gcoms to iqgeo
3)reverse that is iqgeo to gcoms

for that we have created 3 dags for each
we have done the transformation,filters in plsql and few in python, so everyday cdc dag will trigger in that we call plsql procedures
then after all the transformation airflow dags will store the migrated data into csv file
and that csv file will share to some other team and that team will place that file in gcs bucket
and we created cloud functions to trigger whenevr the new file is placed in gcs, then that function will read the csv file data 
and store that data in bq tables then to check the success rate , failure records, time taken,no of records we have used looker studio

in dags we have also included email operator that contains summary no of records, time taken,csvv for the failure migrated data,
there is another procedure in plsql that calls at last,will check the count , if not matches it will include those not migrated code and again the dag triggers and then it migrates
we have many types of categories, for that each we have created diff diff dags for parallel runs

10lak(increase the csv file size)

