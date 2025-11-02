--get the list of databases
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.07 sec)

--create a database as gregs_list
mysql> create database gregs_list;
Query OK, 1 row affected (0.01 sec)

--get the list of databases
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| gregs_list         |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.00 sec)

--use the database gregs_list
mysql> use gregs_list;
Database changed

--create table doughnut_list contains 2 columns(doughnut_name string_length->40,doughnut_type string_length->20)
mysql> create table doughnut_list
    -> (
    -> doughnut_name varchar(40),
    -> doughnut_type varchar(20)
    -> );
Query OK, 0 rows affected (0.04 sec)

--get the list of tables in gregs_list database
mysql> show tables;
+----------------------+
| Tables_in_gregs_list |
+----------------------+
| doughnut_list        |
+----------------------+
1 row in set (0.01 sec)

--create table my_contacts contains columns(last_name string:30,first_name string:20,email string:50,gender string:1,
--birthday '2022-10-16',profession string:50,location string:50,status string:20,interests string:100,seeking string:100)
mysql> create table my_contacts
(
    last_name varchar(30),
    first_name varchar(20),
    email varchar(50),
    gender char(1),
    birthday date,
    profession varchar(50),
    location varchar(50),
    status varchar(20),
    interests varchar(100),
    seeking varchar(100)
);

--check the table my_contacts schema
mysql> desc my_contacts;
+------------+--------------+------+-----+---------+-------+
| Field      | Type         | Null | Key | Default | Extra |
+------------+--------------+------+-----+---------+-------+
| last_name  | varchar(30)  | YES  |     | NULL    |       |
| first_name | varchar(20)  | YES  |     | NULL    |       |
| email      | varchar(50)  | YES  |     | NULL    |       |
| birthday   | date         | YES  |     | NULL    |       |
| profession | varchar(50)  | YES  |     | NULL    |       |
| location   | varchar(50)  | YES  |     | NULL    |       |
| status     | varchar(20)  | YES  |     | NULL    |       |
| interests  | varchar(100) | YES  |     | NULL    |       |
| seeking    | varchar(100) | YES  |     | NULL    |       |
+------------+--------------+------+-----+---------+-------+

--delete the table my_contacts
mysql> drop table my_contacts;
Query OK, 0 rows affected (0.02 sec)

--create table my_contacts contains columns(last_name string:30,first_name string:20,email string:50,gender string:1,
--birthday '2022-10-16',profession string:50,location string:50,status string:20,interests string:100,seeking string:100)
mysql> create table my_contacts
    -> (
    ->     last_name varchar(30),
    ->     first_name varchar(20),
    ->     email varchar(50),
    ->     gender char(1),
    ->     birthday date,
    ->     profession varchar(50),
    ->     location varchar(50),
    ->     status varchar(20),
    ->     interests varchar(100),
    ->     seeking varchar(100)
    -> );
Query OK, 0 rows affected (0.02 sec)

--check the table my_contacts schema
mysql> desc my_contacts;
+------------+--------------+------+-----+---------+-------+
| Field      | Type         | Null | Key | Default | Extra |
+------------+--------------+------+-----+---------+-------+
| last_name  | varchar(30)  | YES  |     | NULL    |       |
| first_name | varchar(20)  | YES  |     | NULL    |       |
| email      | varchar(50)  | YES  |     | NULL    |       |
| gender     | char(1)      | YES  |     | NULL    |       |
| birthday   | date         | YES  |     | NULL    |       |
| profession | varchar(50)  | YES  |     | NULL    |       |
| location   | varchar(50)  | YES  |     | NULL    |       |
| status     | varchar(20)  | YES  |     | NULL    |       |
| interests  | varchar(100) | YES  |     | NULL    |       |
| seeking    | varchar(100) | YES  |     | NULL    |       |
+------------+--------------+------+-----+---------+-------+
10 rows in set (0.01 sec)

--insert the values into table my_contacts(first_name,email,profession,location)-->('Pat','patpost@breakneckpizza.net','Postal Worker','Princeton, NJ')
insert into my_contacts(first_name,email,profession,location)
values('Pat','patpost@breakneckpizza.net','Postal Worker','Princeton, NJ');

--with select show the data of table my_contacts
mysql> select * from my_contacts;
+-----------+------------+----------------------------------+--------+------------+------------------+---------------+--------+--------------------+-----------------------+
| last_name | first_name | email                            | gender | birthday   | profession       | location      | status | interests          | seeking               |
+-----------+------------+----------------------------------+--------+------------+------------------+---------------+--------+--------------------+-----------------------+
| Anderson  | Jillian    | jill_anderson@breakneckpizza.net | F      | 1980-09-05 | Technical Writer | Palo Alto,CA  | Single | Kayaking. Reptiles | Relationship, Friends |
| NULL      | Pat        | patpost@breakneckpizza.net       | NULL   | NULL       | Postal Worker    | Princeton, NJ | NULL   | NULL               | NULL                  |
+-----------+------------+----------------------------------+--------+------------+------------------+---------------+--------+--------------------+-----------------------+

--delete the table doughnut_list
mysql> drop table doughnut_list;
Query OK, 0 rows affected (0.03 sec)

--show list of tables in database
mysql> show tables;
+----------------------+
| Tables_in_gregs_list |
+----------------------+
| my_contacts          |
+----------------------+
1 row in set (0.01 sec)

--create table doughnut_list contains 3 columns are not null(doughnut_name string_length->10,doughnut_type string_length->6,doughnut_cost decimal->3,2 default 1.00)
mysql> create table doughnut_list
(
    doughnut_name varchar(10) not null,
    doughnut_type varchar(6) not null,
    doughnut_cost dec(3,2) not null default 1.00
);

--in doughnut_list table change the datatype of doughnut_type from string_length 6 to 30
mysql> alter table doughnut_list
modify column doughnut_type varchar(30) not null;

--insert the values into doughnut_list table(doughnut_name,doughnut_type,doughnut_cost) -->('Blooberry','filled',2.00),('Appleblush','filled',1.40)
--(doughnut_name,doughnut_type) -->('Cinnamondo','ring'),('Rockstar','cruller'),('Carameller','cruller');
mysql> insert into doughnut_list(doughnut_name,doughnut_type,doughnut_cost)
values('Blooberry','filled',2.00);


mysql> insert into doughnut_list(doughnut_name,doughnut_type)
values('Cinnamondo','ring'),
('Rockstar','cruller'),
('Carameller','cruller');

mysql> insert into doughnut_list(doughnut_name,doughnut_type,doughnut_cost)
values('Appleblush','filled',1.40);

--with select show the data of table doughnut_list
mysql> select * from doughnut_list;
+---------------+---------------+---------------+
| doughnut_name | doughnut_type | doughnut_cost |
+---------------+---------------+---------------+
| Blooberry     | filled        |          2.00 |
| Cinnamondo    | ring          |          1.00 |
| Rockstar      | cruller       |          1.00 |
| Carameller    | cruller       |          1.00 |
| Appleblush    | filled        |          1.40 |
+---------------+---------------+---------------+
5 rows in set (0.00 sec)

--insert the values into my_contacts table
mysql> INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`,`profession`,`location`,`status`,`interests`,`seeking`) VALUES ('Anderson','Jillian','jill_anderson@breakneckpizza.com','F','1980-09-05','Technical Writer','Palo Alto, CA','single','kayaking, reptiles','relationship, friends');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`,`profession`,`location`,`status`,`interests`,`seeking`) VALUES ('Kenton','Leo','lkenton@starbuzzcoffee.com','M','1974-01-10','Manager','San Francisco, CA','divorced','women','women to date');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`,`profession`,`location`,`status`,`interests`,`seeking`) VALUES ('McGavin','Darrin',' captainlove@headfirsttheater.com','M','1966-01-23','Cruise Ship Captain','San Diego, CA','single','sailing, fishing, yachting','women for casual relationships');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`,`profession`,`location`,`status`,`interests`,`seeking`) VALUES ('Franklin','Joe','joe_franklin@leapinlimos.com','M','1977-04-28','Software Sales','Dallas, TX','married','fishing, drinking','new job');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`,`profession`,`location`,`status`,`interests`,`seeking`) VALUES ('Hamilton','Jamie','dontbother@starbuzzcoffee.com','F','1964-09-10','System Administrator','Princeton, NJ','married','RPG','nothing');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`,`profession`,`location`,`status`,`interests`,`seeking`) VALUES ('Chevrolet','Maurice','bookman4u@objectville.net','M','1962-07-01','Bookshop Owner','Mountain View, CA','married','collecting books, scuba diving','friends');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`,`profession`,`location`,`status`,`interests`,`seeking`) VALUES ('Kroger','Renee','poorrenee@mightygumball.net','F','1976-12-03','Unemployed','San Francisco, CA','divorced','cooking','employment');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`,`profession`,`location`,`status`,`interests`,`seeking`) VALUES ('Mendoza','Angelina','angelina@starbuzzcoffee.com','F','1979-08-19','UNIX Sysadmin','San Francisco, CA','married','acting, dancing','new job');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`,`profession`,`location`,`status`,`interests`,`seeking`) VALUES ('Murphy','Donald','padraic@tikibeanlounge.com','M','1967-01-23','Computer Programmer','New York City, NY','committed relationsh','RPG, anime','friends');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`,`profession`,`location`,`status`,`interests`,`seeking`) VALUES ('Spatner','John','jpoet@objectville.net','M','1963-04-18','Salesman','Woodstock, NY','married','poetry, screenwriting','nothing');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`, `profession`,`location`) VALUES ('Toth','Anne','Anne_Toth@leapinlimos.com','F','1969-11-18', 'Artist','San Fran, CA');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`, `profession`,`location`) VALUES ('Manson','Anne','am86@objectville.net','F','1977-08-09', 'Baker','Seattle, WA');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`, `profession`,`location`) VALUES ('Hardy','Anne','anneh@b0tt0msup.com','F','1963-04-18', 'Teacher','San Fran, CA');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`, `profession`,`location`) VALUES ('Parker','Anne','annep@starbuzzcoffee.com','F','1983-01-10', 'Student','San Fran, CA');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`, `profession`,`location`) VALUES ('Blunt','Anne','anneblunt@breakneckpizza.com','F','1959-10-09', 'Web Designer','San Fran, CA');
INSERT INTO `my_contacts` (`last_name`,`first_name`,`email`,`gender`,`birthday`, `profession`,`location`) VALUES ('Jacobs','Anne','anne99@objectville.net','F','1968-02-05', 'Computer Programmer','San Jose, CA');

--with select show the data of table my_contacts of all columns
mysql> select * from my_contacts;
+-----------+------------+-----------------------------------+--------+------------+----------------------+-------------------+----------------------+--------------------------------+--------------------------------+
| last_name | first_name | email                             | gender | birthday   | profession           | location          | status               | interests                      | seeking                        |
+-----------+------------+-----------------------------------+--------+------------+----------------------+-------------------+----------------------+--------------------------------+--------------------------------+
| Anderson  | Jillian    | jill_anderson@breakneckpizza.net  | F      | 1980-09-05 | Technical Writer     | Palo Alto,CA      | Single               | Kayaking. Reptiles             | Relationship, Friends          |
| NULL      | Pat        | patpost@breakneckpizza.net        | NULL   | NULL       | Postal Worker        | Princeton, NJ     | NULL                 | NULL                           | NULL                           |
| Anderson  | Jillian    | jill_anderson@breakneckpizza.com  | F      | 1980-09-05 | Technical Writer     | Palo Alto, CA     | single               | kayaking, reptiles             | relationship, friends          |
| Kenton    | Leo        | lkenton@starbuzzcoffee.com        | M      | 1974-01-10 | Manager              | San Francisco, CA | divorced             | women                          | women to date                  |
| McGavin   | Darrin     |  captainlove@headfirsttheater.com | M      | 1966-01-23 | Cruise Ship Captain  | San Diego, CA     | single               | sailing, fishing, yachting     | women for casual relationships |
| Franklin  | Joe        | joe_franklin@leapinlimos.com      | M      | 1977-04-28 | Software Sales       | Dallas, TX        | married              | fishing, drinking              | new job                        |
| Hamilton  | Jamie      | dontbother@starbuzzcoffee.com     | F      | 1964-09-10 | System Administrator | Princeton, NJ     | married              | RPG                            | nothing                        |
| Chevrolet | Maurice    | bookman4u@objectville.net         | M      | 1962-07-01 | Bookshop Owner       | Mountain View, CA | married              | collecting books, scuba diving | friends                        |
| Kroger    | Renee      | poorrenee@mightygumball.net       | F      | 1976-12-03 | Unemployed           | San Francisco, CA | divorced             | cooking                        | employment                     |
| Mendoza   | Angelina   | angelina@starbuzzcoffee.com       | F      | 1979-08-19 | UNIX Sysadmin        | San Francisco, CA | married              | acting, dancing                | new job                        |
| Murphy    | Donald     | padraic@tikibeanlounge.com        | M      | 1967-01-23 | Computer Programmer  | New York City, NY | committed relationsh | RPG, anime                     | friends                        |
| Spatner   | John       | jpoet@objectville.net             | M      | 1963-04-18 | Salesman             | Woodstock, NY     | married              | poetry, screenwriting          | nothing                        |
| Toth      | Anne       | Anne_Toth@leapinlimos.com         | F      | 1969-11-18 | Artist               | San Fran, CA      | NULL                 | NULL                           | NULL                           |
| Manson    | Anne       | am86@objectville.net              | F      | 1977-08-09 | Baker                | Seattle, WA       | NULL                 | NULL                           | NULL                           |
| Hardy     | Anne       | anneh@b0tt0msup.com               | F      | 1963-04-18 | Teacher              | San Fran, CA      | NULL                 | NULL                           | NULL                           |
| Parker    | Anne       | annep@starbuzzcoffee.com          | F      | 1983-01-10 | Student              | San Fran, CA      | NULL                 | NULL                           | NULL                           |
| Blunt     | Anne       | anneblunt@breakneckpizza.com      | F      | 1959-10-09 | Web Designer         | San Fran, CA      | NULL                 | NULL                           | NULL                           |
| Jacobs    | Anne       | anne99@objectville.net            | F      | 1968-02-05 | Computer Programmer  | San Jose, CA      | NULL                 | NULL                           | NULL                           |
+-----------+------------+-----------------------------------+--------+------------+----------------------+-------------------+----------------------+--------------------------------+--------------------------------+
18 rows in set (0.00 sec)

--with select show the data of table my_contacts of all columns and first_name = 'Anne'
mysql> select * from my_contacts where first_name = 'Anne';
+-----------+------------+------------------------------+--------+------------+---------------------+--------------+--------+-----------+---------+
| last_name | first_name | email                        | gender | birthday   | profession          | location     | status | interests | seeking |
+-----------+------------+------------------------------+--------+------------+---------------------+--------------+--------+-----------+---------+
| Toth      | Anne       | Anne_Toth@leapinlimos.com    | F      | 1969-11-18 | Artist              | San Fran, CA | NULL   | NULL      | NULL    |
| Manson    | Anne       | am86@objectville.net         | F      | 1977-08-09 | Baker               | Seattle, WA  | NULL   | NULL      | NULL    |
| Hardy     | Anne       | anneh@b0tt0msup.com          | F      | 1963-04-18 | Teacher             | San Fran, CA | NULL   | NULL      | NULL    |
| Parker    | Anne       | annep@starbuzzcoffee.com     | F      | 1983-01-10 | Student             | San Fran, CA | NULL   | NULL      | NULL    |
| Blunt     | Anne       | anneblunt@breakneckpizza.com | F      | 1959-10-09 | Web Designer        | San Fran, CA | NULL   | NULL      | NULL    |
| Jacobs    | Anne       | anne99@objectville.net       | F      | 1968-02-05 | Computer Programmer | San Jose, CA | NULL   | NULL      | NULL    |
+-----------+------------+------------------------------+--------+------------+---------------------+--------------+--------+-----------+---------+
6 rows in set (0.00 sec)

--create a database drinks
create database drinks;
--use the database drinks
use database drinks;
--create the table easy_drinks contains columns(drink_name -> string 40,main -> string 40,amount1 -> decimal (3,2),
--second -> string 50,amount2 -> decimal (4,2),directions -> string 250)
create table easy_drinks
(
    drink_name varchar(40),
    main varchar(40),
    amount1 dec(3,2),
    second varchar(50),
    amount2 dec(4,2),
    directions varchar(250)
)

--insert the data into easy_drinks table
insert into easy_drinks
values('Blackthorn','tonic water',1.5,'pineapple juice',1,'stir with ice,straininto cocktail glass with lemon twist'),
('Blue Moon','soda',1.5,'blueberry juice',.75,'stir with ice,straininto cocktail glass with lemon twist');
INSERT INTO `easy_drinks` (`drink_name`,`main`,`amount1`,`second`,`amount2`,`directions`) VALUES ('Kiss on the Lips','cherry juice',2.0,'apricot nectar',7.00,'serve over ice with straw');
INSERT INTO `easy_drinks` (`drink_name`,`main`,`amount1`,`second`,`amount2`,`directions`) VALUES ('Hot Gold','peach nectar',3.0,'orange juice',6.00,'pour hot orange juice in mug and add peach nectar');
INSERT INTO `easy_drinks` (`drink_name`,`main`,`amount1`,`second`,`amount2`,`directions`) VALUES ('Lone Tree','soda',1.5,'cherry juice',0.75,'stir with ice, strain into cocktail glass');
INSERT INTO `easy_drinks` (`drink_name`,`main`,`amount1`,`second`,`amount2`,`directions`) VALUES ('Greyhound','soda',1.5,'grapefruit juice',5.00,'serve over ice, stir well');
INSERT INTO `easy_drinks` (`drink_name`,`main`,`amount1`,`second`,`amount2`,`directions`) VALUES ('Indian Summer','apple juice',2.0,'hot tea',6.00,'add juice to mug and top off with hot tea');
INSERT INTO `easy_drinks` (`drink_name`,`main`,`amount1`,`second`,`amount2`,`directions`) VALUES ('Bull Frog','iced tea',1.5,'lemonade',5.00,'serve over ice with lime slice');
INSERT INTO `easy_drinks` (`drink_name`,`main`,`amount1`,`second`,`amount2`,`directions`) VALUES ('Soda and It','soda',2.0,'grape juice',1.00,'shake in cocktail glass, no ice');
INSERT INTO `easy_drinks` (`drink_name`,`main`,`amount1`,`second`,`amount2`,`directions`) VALUES ('Oh My Gosh','peach nectar',1.0,'pineapple juice',1.00,'stir with ice, strain into shot glass');
INSERT INTO `easy_drinks` (`drink_name`,`main`,`amount1`,`second`,`amount2`,`directions`) VALUES ('Lime Fizz','Sprite',1.5,'lime juice',0.75,'stir with ice, strain into cocktail glass');

--with select show the data of table easy_drinks of all columns
mysql> select * from easy_drinks;
+------------------+--------------+---------+------------------+---------+----------------------------------------------------------+
| drink_name       | main         | amount1 | second           | amount2 | directions                                               |
+------------------+--------------+---------+------------------+---------+----------------------------------------------------------+
| Blackthorn       | tonic water  |    1.50 | pineapple juice  |    1.00 | stir with ice,straininto cocktail glass with lemon twist |
| Blue Moon        | soda         |    1.50 | blueberry juice  |    0.75 | stir with ice,straininto cocktail glass with lemon twist |
| Kiss on the Lips | cherry juice |    2.00 | apricot nectar   |    7.00 | serve over ice with straw                                |
| Hot Gold         | peach nectar |    3.00 | orange juice     |    6.00 | pour hot orange juice in mug and add peach nectar        |
| Lone Tree        | soda         |    1.50 | cherry juice     |    0.75 | stir with ice, strain into cocktail glass                |
| Greyhound        | soda         |    1.50 | grapefruit juice |    5.00 | serve over ice, stir well                                |
| Indian Summer    | apple juice  |    2.00 | hot tea          |    6.00 | add juice to mug and top off with hot tea                |
| Bull Frog        | iced tea     |    1.50 | lemonade         |    5.00 | serve over ice with lime slice                           |
| Soda and It      | soda         |    2.00 | grape juice      |    1.00 | shake in cocktail glass, no ice                          |
| Oh My Gosh       | peach nectar |    1.00 | pineapple juice  |    1.00 | stir with ice, strain into shot glass                    |
| Lime Fizz        | Sprite       |    1.50 | lime juice       |    0.75 | stir with ice, strain into cocktail glass                |
+------------------+--------------+---------+------------------+---------+----------------------------------------------------------+
11 rows in set (0.00 sec)

--create table drink_info contains columns(drink_name -> string 40,cost-> decimal (4,2),carbs->decimal (4,3),color-> string 20,ice -> string 1,calories -> integer)
create table drink_info
(
    drink_name varchar(40),
    cost dec(4,2),
    carbs dec(4,3),
    color varchar(20),
    ice char(1),
    calories int
)

--change the column carbs from (4,3) to (5,3)
mysql> alter table drink_info
    -> modify column carbs dec(5,3);
Query OK, 4 rows affected (0.07 sec)
Records: 4  Duplicates: 0  Warnings: 0

--insert the data into drink_info table
INSERT INTO drink_info VALUES ('Blackthorn', 3, 8.4, 'yellow', 'Y', 33); 
INSERT INTO drink_info VALUES ('Blue Moon', 2.5, 3.2, 'blue', 'Y', 12); 
INSERT INTO drink_info VALUES ('Oh My Gosh', 3.5, 8.6, 'orange', 'Y', 35); 
INSERT INTO drink_info VALUES ('Lime Fizz', 2.5, 5.4, 'green', 'Y', 24); 
INSERT INTO drink_info VALUES ('Kiss on the Lips', 5.5, 42.5, 'purple', 'Y', 171); 
INSERT INTO drink_info VALUES ('Hot Gold', 3.2, 32.1, 'orange', 'N', 135); 
INSERT INTO drink_info VALUES ('Lone Tree', 3.6, 4.2, 'red', 'Y', 17); 
INSERT INTO drink_info VALUES ('Greyhound', 4, 14, 'yellow', 'Y', 50); 
INSERT INTO drink_info VALUES ('Indian Summer', 2.8, 7.2, 'brown', 'N', 30); 
INSERT INTO drink_info VALUES ('Bull Frog', 2.6, 21.5, 'tan', 'Y', 80); 
INSERT INTO drink_info VALUES ('Soda and It', 3.8, 4.7, 'red', 'N', 19); 

--with select show the data of table drink_info of all columns
mysql> select * from drink_info;
+------------------+------+--------+--------+------+----------+
| drink_name       | cost | carbs  | color  | ice  | calories |
+------------------+------+--------+--------+------+----------+
| Blackthorn       | 3.00 |  8.400 | yellow | Y    |       33 |
| Blue Moon        | 2.50 |  3.200 | blue   | Y    |       12 |
| Oh My Gosh       | 3.50 |  8.600 | orange | Y    |       35 |
| Lime Fizz        | 2.50 |  5.400 | green  | Y    |       24 |
| Kiss on the Lips | 5.50 | 42.500 | purple | Y    |      171 |
| Hot Gold         | 3.20 | 32.100 | orange | N    |      135 |
| Lone Tree        | 3.60 |  4.200 | red    | Y    |       17 |
| Greyhound        | 4.00 | 14.000 | yellow | Y    |       50 |
| Indian Summer    | 2.80 |  7.200 | brown  | N    |       30 |
| Bull Frog        | 2.60 | 21.500 | tan    | Y    |       80 |
| Soda and It      | 3.80 |  4.700 | red    | N    |       19 |
+------------------+------+--------+--------+------+----------+
11 rows in set (0.00 sec)

--select the column drink_name from table drink_info that contains cost is greater than equal to 3.50 and calories is less than 50
mysql> select drink_name from drink_info where cost>=3.50 and calories<50;
+-------------+
| drink_name  |
+-------------+
| Oh My Gosh  |
| Lone Tree   |
| Soda and It |
+-------------+
3 rows in set (0.00 sec)

--select the column drink_name from table drink_info that contains drink_name between L and M
mysql> select drink_name from drink_info where drink_name>='L' and drink_name<'M';
+------------+
| drink_name |
+------------+
| Lime Fizz  |
| Lone Tree  |
+------------+
2 rows in set (0.00 sec)
+------------------+--------------+---------+------------------+---------+----------------------------------------------------------+
| drink_name       | main         | amount1 | second           | amount2 | directions                                               |
+------------------+--------------+---------+------------------+---------+----------------------------------------------------------+
| Blackthorn       | tonic water  |    1.50 | pineapple juice  |    1.00 | stir with ice,straininto cocktail glass with lemon twist |
| Blue Moon        | soda         |    1.50 | blueberry juice  |    0.75 | stir with ice,straininto cocktail glass with lemon twist |
| Kiss on the Lips | cherry juice |    2.00 | apricot nectar   |    7.00 | serve over ice with straw                                |
| Hot Gold         | peach nectar |    3.00 | orange juice     |    6.00 | pour hot orange juice in mug and add peach nectar        |
| Lone Tree        | soda         |    1.50 | cherry juice     |    0.75 | stir with ice, strain into cocktail glass                |
| Greyhound        | soda         |    1.50 | grapefruit juice |    5.00 | serve over ice, stir well                                |
| Indian Summer    | apple juice  |    2.00 | hot tea          |    6.00 | add juice to mug and top off with hot tea                |
| Bull Frog        | iced tea     |    1.50 | lemonade         |    5.00 | serve over ice with lime slice                           |
| Soda and It      | soda         |    2.00 | grape juice      |    1.00 | shake in cocktail glass, no ice                          |
| Oh My Gosh       | peach nectar |    1.00 | pineapple juice  |    1.00 | stir with ice, strain into shot glass                    |
| Lime Fizz        | Sprite       |    1.50 | lime juice       |    0.75 | stir with ice, strain into cocktail glass                |
+------------------+--------------+---------+------------------+---------+----------------------------------------------------------+

--select drink_name from table easy_drinks that contains main is either cherry juice or secpnd is cherry juice
mysql> select drink_name from easy_drinks where main='cherry juice' or second='cherry juice';
+------------------+
| drink_name       |
+------------------+
| Kiss on the Lips |
| Lone Tree        |
+------------------+
2 rows in set (0.00 sec)

--create table doughnut_ratings contains columns(location-> string 40,time-> string 10,date-> string 10,type-> string 40,rating-> integer,comments-> string 40)
create table doughnut_ratings
(
    location varchar(40),
    time varchar(10),
    date varchar(10),
    type varchar(40),
    rating int,
    comments varchar(40)
);
--insert data into table doughnut_ratings
INSERT INTO `doughnut_ratings` (`location`,`time`,`date`,`type`,`rating`,`comments`) VALUES ('Krispy King','08:50 am','9/27','plain glazed',10,'almost perfect');
INSERT INTO `doughnut_ratings` (`location`,`time`,`date`,`type`,`rating`,`comments`) VALUES ('Duncan\'s Donuts','08:59 am','8/25',NULL,6,'greasy');
INSERT INTO `doughnut_ratings` (`location`,`time`,`date`,`type`,`rating`,`comments`) VALUES ('Starbuzz Coffee','07:35 pm','5/24','cinnamon cake',5,'stale, but tasty');
INSERT INTO `doughnut_ratings` (`location`,`time`,`date`,`type`,`rating`,`comments`) VALUES ('Duncan\'s Donuts','07:03 pm','4/26','jelly',7,'not enough jelly');

--show data of table doughnut_ratings of all columns
mysql> select * from doughnut_ratings;
+-----------------+----------+------+---------------+--------+------------------+
| location        | time     | date | type          | rating | comments         |
+-----------------+----------+------+---------------+--------+------------------+
| Krispy King     | 08:50 am | 9/27 | plain glazed  |     10 | almost perfect   |
| Duncan's Donuts | 08:59 am | 8/25 | NULL          |      6 | greasy           |
| Starbuzz Coffee | 07:35 pm | 5/24 | cinnamon cake |      5 | stale, but tasty |
| Duncan's Donuts | 07:03 pm | 4/26 | jelly         |      7 | not enough jelly |
+-----------------+----------+------+---------------+--------+------------------+

--insert data into table drink_info
insert into drink_info(drink_name,cost,carbs,color,ice,calories)

insert into drink_info(drink_name,carbs,ice,calories)
values('Holiday',14,'Y',50);
insert into drink_info(drink_name,cost,carbs,color,ice)
VALUES('Dragon Breath',2.9,7.2,'brown','N');

--show data of table drink_info of all columns
mysql> select * from drink_info;
+------------------+------+--------+--------+------+----------+
| drink_name       | cost | carbs  | color  | ice  | calories |
+------------------+------+--------+--------+------+----------+
| Blackthorn       | 3.00 |  8.400 | yellow | Y    |       33 |
| Blue Moon        | 2.50 |  3.200 | blue   | Y    |       12 |
| Oh My Gosh       | 3.50 |  8.600 | orange | Y    |       35 |
| Lime Fizz        | 2.50 |  5.400 | green  | Y    |       24 |
| Kiss on the Lips | 5.50 | 42.500 | purple | Y    |      171 |
| Hot Gold         | 3.20 | 32.100 | orange | N    |      135 |
| Lone Tree        | 3.60 |  4.200 | red    | Y    |       17 |
| Greyhound        | 4.00 | 14.000 | yellow | Y    |       50 |
| Indian Summer    | 2.80 |  7.200 | brown  | N    |       30 |
| Bull Frog        | 2.60 | 21.500 | tan    | Y    |       80 |
| Soda and It      | 3.80 |  4.700 | red    | N    |       19 |
| Holiday          | NULL | 14.000 | NULL   | Y    |       50 |
| Dragon Breath    | 2.90 |  7.200 | brown  | N    |     NULL |
+------------------+------+--------+--------+------+----------+
13 rows in set (0.00 sec)

--select the column drink_name from drink_info table contains calories is =Null,'Null', is Null
mysql> select drink_name from drink_info where calories=Null;
Empty set (0.00 sec)

mysql> select drink_name from drink_info where calories='Null';
Empty set, 1 warning (0.00 sec)

mysql> select drink_name from drink_info where calories is NULL;
+---------------+
| drink_name    |
+---------------+
| Dragon Breath |
+---------------+
1 row in set (0.00 sec)

--show all the columns data of table my_contacts contains locations ends with 'CA'
mysql> select * from my_contacts where location like '%CA';
+-----------+------------+-----------------------------------+--------+------------+---------------------+-------------------+----------+--------------------------------+--------------------------------+
| last_name | first_name | email                             | gender | birthday   | profession          | location          | status   | interests                      | seeking                        |
+-----------+------------+-----------------------------------+--------+------------+---------------------+-------------------+----------+--------------------------------+--------------------------------+
| Anderson  | Jillian    | jill_anderson@breakneckpizza.net  | F      | 1980-09-05 | Technical Writer    | Palo Alto,CA      | Single   | Kayaking. Reptiles             | Relationship, Friends          |
| Anderson  | Jillian    | jill_anderson@breakneckpizza.com  | F      | 1980-09-05 | Technical Writer    | Palo Alto, CA     | single   | kayaking, reptiles             | relationship, friends          |
| Kenton    | Leo        | lkenton@starbuzzcoffee.com        | M      | 1974-01-10 | Manager             | San Francisco, CA | divorced | women                          | women to date                  |
| McGavin   | Darrin     |  captainlove@headfirsttheater.com | M      | 1966-01-23 | Cruise Ship Captain | San Diego, CA     | single   | sailing, fishing, yachting     | women for casual relationships |
| Chevrolet | Maurice    | bookman4u@objectville.net         | M      | 1962-07-01 | Bookshop Owner      | Mountain View, CA | married  | collecting books, scuba diving | friends                        |
| Kroger    | Renee      | poorrenee@mightygumball.net       | F      | 1976-12-03 | Unemployed          | San Francisco, CA | divorced | cooking                        | employment                     |
| Mendoza   | Angelina   | angelina@starbuzzcoffee.com       | F      | 1979-08-19 | UNIX Sysadmin       | San Francisco, CA | married  | acting, dancing                | new job                        |
| Toth      | Anne       | Anne_Toth@leapinlimos.com         | F      | 1969-11-18 | Artist              | San Fran, CA      | NULL     | NULL                           | NULL                           |
| Hardy     | Anne       | anneh@b0tt0msup.com               | F      | 1963-04-18 | Teacher             | San Fran, CA      | NULL     | NULL                           | NULL                           |
| Parker    | Anne       | annep@starbuzzcoffee.com          | F      | 1983-01-10 | Student             | San Fran, CA      | NULL     | NULL                           | NULL                           |
| Blunt     | Anne       | anneblunt@breakneckpizza.com      | F      | 1959-10-09 | Web Designer        | San Fran, CA      | NULL     | NULL                           | NULL                           |
| Jacobs    | Anne       | anne99@objectville.net            | F      | 1968-02-05 | Computer Programmer | San Jose, CA      | NULL     | NULL                           | NULL                           |
+-----------+------------+-----------------------------------+--------+------------+---------------------+-------------------+----------+--------------------------------+--------------------------------+
12 rows in set (0.00 sec)


--show all the columns data of table my_contacts contains first_name anne but dont know what is 3rd letter
mysql> select * from my_contacts where first_name like 'An_e';
+-----------+------------+------------------------------+--------+------------+---------------------+--------------+--------+-----------+---------+
| last_name | first_name | email                        | gender | birthday   | profession          | location     | status | interests | seeking |
+-----------+------------+------------------------------+--------+------------+---------------------+--------------+--------+-----------+---------+
| Toth      | Anne       | Anne_Toth@leapinlimos.com    | F      | 1969-11-18 | Artist              | San Fran, CA | NULL   | NULL      | NULL    |
| Manson    | Anne       | am86@objectville.net         | F      | 1977-08-09 | Baker               | Seattle, WA  | NULL   | NULL      | NULL    |
| Hardy     | Anne       | anneh@b0tt0msup.com          | F      | 1963-04-18 | Teacher             | San Fran, CA | NULL   | NULL      | NULL    |
| Parker    | Anne       | annep@starbuzzcoffee.com     | F      | 1983-01-10 | Student             | San Fran, CA | NULL   | NULL      | NULL    |
| Blunt     | Anne       | anneblunt@breakneckpizza.com | F      | 1959-10-09 | Web Designer        | San Fran, CA | NULL   | NULL      | NULL    |
| Jacobs    | Anne       | anne99@objectville.net       | F      | 1968-02-05 | Computer Programmer | San Jose, CA | NULL   | NULL      | NULL    |
+-----------+------------+------------------------------+--------+------------+---------------------+--------------+--------+-----------+---------+
6 rows in set (0.00 sec)

--select the columns drink_name,calories from drink_info contains calories is between 30 and 60 with less than/greater than symbols
mysql> select drink_name,calories from drink_info where calories>=30 and calories<=60;
+---------------+----------+
| drink_name    | calories |
+---------------+----------+
| Blackthorn    |       33 |
| Oh My Gosh    |       35 |
| Greyhound     |       50 |
| Indian Summer |       30 |
| Holiday       |       50 |
+---------------+----------+
5 rows in set (0.00 sec)

--select the columns drink_name,calories from drink_info contains calories is between 30 and 60 with between statement
mysql> select drink_name,calories from drink_info where calories between 30 and 60;
+---------------+----------+
| drink_name    | calories |
+---------------+----------+
| Blackthorn    |       33 |
| Oh My Gosh    |       35 |
| Greyhound     |       50 |
| Indian Summer |       30 |
| Holiday       |       50 |
+---------------+----------+
5 rows in set (0.01 sec)

--select the columns drink_name from drink_info contains drink_name is between alphabets of G and O
mysql> select drink_name from drink_info where drink_name between 'G' and 'O';
+------------------+
| drink_name       |
+------------------+
| Lime Fizz        |
| Kiss on the Lips |
| Hot Gold         |
| Lone Tree        |
| Greyhound        |
| Indian Summer    |
| Holiday          |
+------------------+
7 rows in set (0.00 sec)

--create the table black_book contains columns(date_name ->string 30,rating ->string 40)
create table black_book
(
    date_name varchar(30),
    rating  varchar(40)
);

--insert the values into black_book table
insert into black_book
values('Alex','innovative'),
('James','boring'),
('Ian','fabulous'),
('Boris','ho hum'),
('Melvin','plebian'),
('Eric','pathetic'),
('Anthony','delightful'),
('Sammy','pretty good'),
('Ivan','dismal'),
('Vic','ridiculous');

--show all the columns data in black_book table
mysql> select * from black_book;
+-----------+-------------+
| date_name | rating      |
+-----------+-------------+
| Alex      | innovative  |
| James     | boring      |
| Ian       | fabulous    |
| Boris     | ho hum      |
| Melvin    | plebian     |
| Eric      | pathetic    |
| Anthony   | delightful  |
| Sammy     | pretty good |
| Ivan      | dismal      |
| Vic       | ridiculous  |
+-----------+-------------+
10 rows in set (0.00 sec)


--show all the columns data in black_book table contains rating is 'innovative','fabulous','delightful','pretty good'
mysql> select * from black_book where rating in ('innovative','fabulous','delightful','pretty good');
+-----------+-------------+
| date_name | rating      |
+-----------+-------------+
| Alex      | innovative  |
| Ian       | fabulous    |
| Anthony   | delightful  |
| Sammy     | pretty good |
+-----------+-------------+
4 rows in set (0.00 sec)

--show all the columns data in black_book table contains rating is not 'innovative','fabulous','delightful','pretty good'
mysql> select * from black_book where rating not in ('innovative','fabulous','delightful','pretty good');
+-----------+------------+
| date_name | rating     |
+-----------+------------+
| James     | boring     |
| Boris     | ho hum     |
| Melvin    | plebian    |
| Eric      | pathetic   |
| Ivan      | dismal     |
| Vic       | ridiculous |
+-----------+------------+
6 rows in set (0.00 sec)


--show all the columns data in drink_info table
mysql> select * from drink_info;
+------------------+------+--------+--------+------+----------+
| drink_name       | cost | carbs  | color  | ice  | calories |
+------------------+------+--------+--------+------+----------+
| Blackthorn       | 3.00 |  8.400 | yellow | Y    |       33 |
| Blue Moon        | 2.50 |  3.200 | blue   | Y    |       12 |
| Oh My Gosh       | 3.50 |  8.600 | orange | Y    |       35 |
| Lime Fizz        | 2.50 |  5.400 | green  | Y    |       24 |
| Kiss on the Lips | 5.50 | 42.500 | purple | Y    |      171 |
| Hot Gold         | 3.20 | 32.100 | orange | N    |      135 |
| Lone Tree        | 3.60 |  4.200 | red    | Y    |       17 |
| Greyhound        | 4.00 | 14.000 | yellow | Y    |       50 |
| Indian Summer    | 2.80 |  7.200 | brown  | N    |       30 |
| Bull Frog        | 2.60 | 21.500 | tan    | Y    |       80 |
| Soda and It      | 3.80 |  4.700 | red    | N    |       19 |
+------------------+------+--------+--------+------+----------+
11 rows in set (0.00 sec)

--select the column drink_name from drink_info table contains cost is not between 3 and 5
mysql> select drink_name from drink_info where not cost between 3 and 5;
+------------------+
| drink_name       |
+------------------+
| Blue Moon        |
| Lime Fizz        |
| Kiss on the Lips |
| Indian Summer    |
| Bull Frog        |
| Dragon Breath    |
+------------------+
6 rows in set (0.00 sec)

--select  the column drink_name from drink_info contains drink_name not euql to string that ends with 'moon'
mysql> select drink_name from drink_info where not drink_name like '%Moon';
+------------------+
| drink_name       |
+------------------+
| Blackthorn       |
| Oh My Gosh       |
| Lime Fizz        |
| Kiss on the Lips |
| Hot Gold         |
| Lone Tree        |
| Greyhound        |
| Indian Summer    |
| Bull Frog        |
| Soda and It      |
| Holiday          |
| Dragon Breath    |
+------------------+
12 rows in set (0.00 sec)


AND, OR, NOT, BETWEEN, LIKE, IN, IS NULL
1)
select drink_name from easy_drinks where amount1 > 1.50;
2)select drink_name from drink_info where not ice in ('Y');
3)select drink_name from drink_info where calories > 20;
4)select drink_name from easy_drinks where main like '%nectar' or main like '%da';
5)select drink_name from drink_info where calories>0;
6)where carbs<3 or carbs>5;
6)select date_name from black_book where not date_name like 'a%' and not date_name like 'b%'

