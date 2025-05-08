spark=sparkSession.builder() \
.appName("test") \
.getOrCreate()

csv_file=spark.read.format("csv").option("inferSchema","true").option("header","true").csv("")
csv_file.show()


json_file=spark.read.format("json").load("")
json_file.show()

from pyspark.sql.types import StructField,StructType,LongType,StringType
schema=StructType(StructFiled("col_name",LongType()),False)

selecting=csv_file.select("".alias("")).show(2)

whereing=csv_file.where(col("")==5).show(2)
whereing=csv_file.where(col("item_weight")<10 & col("item_type")="soft drinks").show(2)
whereing=csv_file.where(col("outer_location")=='tier1' & col("outer_location")=='tier2') & \
                        .where(col("outlet size") is NULL).show(2)

whereing=csv_file.where(col("outer_location").isin('tier1','tier2'))
.where(col("outlet_size").isNull()).show(2)


withcolumnrename = csv_file.withColumnrenamed(col(""),"value").show(2)
withcolumn = csv_file.withColumn("new_val","value").show(2)


new_col=csv_file.withColumn(col(""),regexp_replace(col(""),"Low Fat","LF") )
                .withColumn(col(""),regexp_replace(col(""),"regualr Fat","reg"));

casting=csv_file.select(col("").cast(stringType()))

sorting=csv_file.sort(col("")).asc()

sorting=csv_file.sort(col(""),col("")).asc()
sorting=csv_file.sort(col("").asc(),col("").desc())
sorting=csv_file.sort(["",""],ascending = [0,0])
sorting=csv_file.sort(["",""],ascending = [1,0])

droping = csv_file.drop(col(""),col(""))

drop_duplicate= csv_file.dropDuplicates()
drop_duplicate_col= csv_file.dropDuplicates(subset=[""])
distinct = csv_file.distinct()

df=[("sush",1),("dolly",2)]
schema=StructType([StructField("name",StringType(),False),
                  StructField("id",LongType(),False)
                  ])
new_df=spark.createDataFrame(df,schema)
df2=[("sush",1),("dolly",2)]
schema2=StructType([StructField("name",StringType(),False),
                  StructField("id",LongType(),False)
                  ])
new_df2=spark.createDataFrame(df2,schema2)
new_df.union(new_df2)
new_df.unionByName(new_df2)

new_df.select(initcap(col("")))
new_df.select(upper(col("")))

new_df.withColumn("current_date",current_date())
new_df.withColumn("date_add",date_add(current_date(),5))

new_df.withColumn("new",datadiff("current_date","date_add"))
new_df.withColumn("current_date",Date_Format("current_date","dd-MM-yyyy"))

new_df.dropna("any")   -> drops records all nulls in any columns
new_df.dropna("all")   -> drops records all nulls in the same columns
new_df.dropna(subset=["col"]) -> drop records if that column has null values

new_df.fillna("not available") -> replace null with values records all nulls in any columns
new_df.fillna("not available",subset=["col"]) -> replace null with values records if that column has null values

new_df.withColumn("new",split(col("")," "))
new_df.withColumn("new",split(col("")," ")[1]) --> takes first value

new_df.withColumn("new",explode("new")) --> the splited will be duplicated into new rows

new_df.withColumn("new",array_contains("new","type1"))

new_df.groupBy("col").agg(sum("n_col"))
new_df.groupBy("col1","col2").agg(sum("n_col")).alias("newcol")
new_df.groupBy("col1","col2").agg(sum("n_col"),avg("n_col"))

df=[("user1","book1"),("user2","book2"),("user3","book3"),
    ("user1","book4"),("user2","book5"),("user3","book6")]
schema=StructType([StructField("name",StringType(),False),
                    StructField("book_name",StringType(),False)])

new_df=spark.createDataFrame(df,schema)
new_df.groupBy("name").agg(collect_list("book_name"))
user1  book1,book4
user2  book2,book5
user3  book3,book6

new_df.groupBy("col").pivot("col2").agg(avg("book_name"))

new_df.withColumn("col",when(col("type")=='meat',"non veg").otherwise("veg"))

new_df.withColumn("col",when((col("type")=='veg') & (col("mrp")>100,"veg expensive")).
                when((col("type")=='veg') & (col("mrp")>100,"veg expensive"))).otherwise("")


df1.join(df2,df1["dept_id"]==df2["dept_id"],"inner") --> inner join
df1.join(df2,df1["dept_id"]==df2["dept_id"],"left") --> left join
df1.join(df2,df1["dept_id"]==df2["dept_id"],"right") --> right join
df1.join(df2,df1["dept_id"]==df2["dept_id"],"anti") --> anti join

from pyspark.sql.window import Window
df.withColumn("row",row_number().over(Window.orderBy("col")))

df.withColumn("rank",rank().over(Window.orderBy("col")))
df.withColumn("rank",rank().over(Window.orderBy(col("col").desc())))
df.withColumn("dense_rank",dense_rank().over(Window.orderBy("col")))
df.withColumn("sum_rank",sum("mrp").over(Window.orderBy("type")))
df.withColumn("sum_rank",sum("mrp").over(Window.orderBy("type").
        rowsBetween(Window.unboundedPreceeding,Window.currectRow)))
df.withColumn("sum_rank",sum("mrp").over(Window.orderBy("").rowsBetween(Window.unboundedPreceding,
Window.unboundedFollwing)))

def double_val(x):
    return x*x
py_udf=udf(double_val)
df.withColumn("new_col",py_udf("mrp"))


df.write.format("csv").save("/location/data.csv")
append -> adds new data without loosing old data
overwrite -> adds new data by removing all the old data
error -> it will throw error when we try to insert new file to the folder, that alredy old files are there
ignore -> it will not throw error,not write anything....just ignores

df.write.formta("csv").mode("append").save("/location/data.csv")
df.write.format("csv").mode("append").option("path","/location/data.csv").save()

df.write.format("csv").mode("overwrite").save("/location/data.csv")

df.write.format("csv").mode("error").save("/location/data.csv")
df.write.format("csv").mode("ignore").save("/location/data.csv")

df.write.format("parquet").mode("overwrite").save("/location/data.csv")
df.write.format("parquet").mode("overwrite").saveAsTable("my_table") -->creates table 


df.createOrReplaceTempView("table_name")
spark.sql("select * from table_name")
============================================================================================================
read modes:
FAILFAST Mode:
Description: When Spark encounters a malformed or corrupted record, 
it immediately throws an error and stops processing. 
This mode is useful when data integrity is critical, and you don’t want to process 
any data if there’s even a single issue.
df=spark.read.option("mode",failfast).json("path")

DROPMALFORMED Mode:
Description: In this mode, Spark will ignore malformed records and continue 
processing the rest of the data. Malformed records will simply be skipped.
Use Case: Useful when you expect some bad records, but you still want to process the rest of the dataset. 
This is typically used when dealing with large, unclean data that may have some noise, 
but it’s okay to ignore.
df = spark.read.option("mode", "DROPMALFORMED").json("path_to_data")

PERMISSIVE Mode:
Description: In this mode, Spark will attempt to parse and read malformed records, 
but it will replace them with null values for the fields that couldn’t be parsed correctly. 
This allows Spark to continue processing the data but with some missing or corrupt information in the output.
Use Case: Useful when you want to allow some bad data but don’t want to completely ignore the entire record. 
This mode gives you a way to handle errors while keeping as much data as possible.
df = spark.read.option("mode", "PERMISSIVE").json("path_to_data")
-----------------------------------------------------------------------------------------------------------------------
catalyst_optimizer:
spark sql            catalyst_optimizer     rdd        java byte code
dataframe code    --> spark sql enginer  --> 1,2,3...  physical plan
dataset 
4 phases
1)analysis
2)logical planning optimization
3)physical planning
4)code generation
                  analysis        logical                                   cost 
                                optimization                physical plan2  model
code -> unresolved ----> resolved ----------->optimized----> physical plan1 ------>best physical-->final code
        logical plan     logical plan        logical plan    physical plan3,4      plan            rdds
                    catlog
CATLOG: contains metadata(when we write code as .csv("path") then 
                        it checks(files,columns etc) whether it is there or not
                        ifnot present it throws error: analysis exception)
we write code and send
it will be called as unresolved logical plan
then it will check in our code whether it has in catlog
if yes then then it will be resolved logical plan, else throws error
then our code will optimized in logical plan(combines 2-3 same operations as 1)
then it becomes optimised logical plan
after that optimised logical plan will split into multiple physical plans(1,2,3,4)(broadcast join etc)
checks each physical plans takes how much cost(cpu,memory)
then select the best physical plan also called as RDDs(set of rdds that run on cluster)
-----------------------------------------------------------------------------------------------------------------------
repartition and coalesce:
for joining tables based on product_id for example then the data will split into multiple partitions
so if one of the product sales are then those records will be more 
so that respective id partition will run slow(happens data skew)

10mb executor1
20mb executor2
30mb executor3
40mb executor4
100mb executor5(skew)
due to this we do repartition and coalesce
repartition                                     coalesce
40mb                                            30mb
40mb                                            70mb
40mb                                            100mb
40mb                        

shuffling(hash based)                           no shuffling
expensive                                       not expensive
pros:                                           pros:
evenly distributes                              not expensive
cons:                                           cons:
more I/O                                        uneven data distribution
can inc,dec no of.partition                     only decrease no of partition
-----------------------------------------------------------------------------------------------------------------------
Strategies in spark:
1)sort-merge join
df1         df2
1           4
3           1
2           2
            3

sorting:
df1         df2
1           1
2           2
3           3
            4
we manually do the sort of 2 dfs independently and join
O(nlogn)
2)shuffle hash join
df1         df2
1           4
3           1
2           2
            3
            hash(stores all unique keys in memory)
now checks each key in df1 with hash if present it will join
O(1)
3)broadcast hash join
check file size:
from pyspark.sql import SparkSession
import sys
spark = SparkSession.builder.appName("EstimateDFSize").getOrCreate()
df = spark.read.csv("your_file.csv", header=True, inferSchema=True)
def get_dataframe_size(df):
    return df.rdd.map(lambda row: sys.getsizeof(row)).reduce(lambda x, y: x + y)

size_in_bytes = get_dataframe_size(df)
size_in_mb = size_in_bytes / (1024 * 1024)
print(f"Estimated DataFrame size: {size_in_mb:.2f} MB")

spark.conf.get(spark.sql.autoBroadcastjoinThreshold)
spark.conf.set(spark.sql.autoBroadcastjoinThreshold,20 * 1024 * 1024)
4)cartesian join
5)broadcast nested loop join(joins the id< condition)
df1         df2
1           4
2           1
3           2
            3
O(n^2)
(3,3)(3,2)(3,1)
-----------------------------------------------------------------------------------------------------------------------
execuotr memerory:(10gb)
1)reserved memory - 300mb
spark internals objects used by spark engine
2)user memory - 40%
udf,rdds
3)spark memory - 60%
a)storage memroy usage:
storing intermediate state of tasks
memeory eviction is done in list recently use fashion
cache
b)executor memory usgae:
its cleared once we used it  -> short lived
storing objects of tasks
stored hash table for aggregations
spilling to disk
-----------------------------------------------------------------------------------------------------------------------
1)what is spark-submit?
spark submit is command line tool,using this we run spark application
it will makes our files in to a package and sends and runs on spark cluster
2)how do you run your job on spark?
using spark-submit
3)where is your spark cluster?
standalone cluster,local mode,kubernetes,yarn
4)what is deploy mode in spark-submit?

5)how do you provide memory configuration and why do you use this much memory?
6)how to update configurations like braoadcast threshold,timeout,dynamic
-----------------------------------------------------------------------------------------------------------------------
AQE:
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.join.enabled", "true")
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", "true")
spark.conf.set("spark.sql.adaptive.coalescePartitions.enabled", "true")

dynamicPartitionPruning
SET spark.sql.optimizer.dynamicPartitionPruning.enabled = true;

partitioning:
df.write.format("csv").option("header","true").mode("overwrite").partitionBy("address").save("path")
dbutils.fs.ls("path")
each file created ->india,usa,japan,china 

if we do for id column...how many ids are there that many partitions it will create, so this is the reason 
partition will fail hear 
df.write.format("csv").option("header","true").mode("overwrite").partitionBy("id").save("path")
dbutils.fs.ls("path")
each file created ->1,2,3,4....
we use bucketing:

df.write.format("csv").option("header","true").mode("overwrite").bucketBy(3,"id").saveAsTable("tablename")
dbutils.fs.ls("path")
it creates 3 buckets

if 200 tasks -> each task use 5 buckets
then 200*5=1000 buckets
so how many repartitions and how many bukets we should use?


