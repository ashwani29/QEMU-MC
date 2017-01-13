# DBT2
- is an OLTP transactional performance test
- it simulates a wholesale parts supplier where several workers access a database, update customer information and check on parts inventories
- DBT-2 is a fair usage implementation of the TCP's TPC-C Benchmark specification
- it is one of the most popular benchmark tool for MySQL

## Perl modules
- Required Perl modules:
  - Statistics::Descriptive
  - Test::Parser
  - Test::Reporter

- Install Perl modules with:
```
sudo cpan Statistics::Descriptive
sudo cpan Test::Parser
sudo cpan Test::Reporter
```

Note: it wont' return any compiling errors if these packages are missing.

## Download and compile
```
./configure --help 

...
  --enable-nonsp          Force to build nonSP version of dbt2 test 
                          (default is no)
...

  --with-mysql[=DIR]      Build C based version of dbt2 test. Set to the path
                          of the MySQL's installation, or leave unset if the
                          path is already in the search path
  --with-mysql-includes   path to MySQL header files
  --with-mysql-libs       path to MySQL libraries
```

## stages
### Generate data
Data for the test is generate by datagen
One has to specify:
```
       -w - number of warehouses (example: -w 3)
       -d - output path for data files (example: -d /tmp/dbt2-w3)
       - mode (example: --mysql)
```
Example:
```
datagen -w 3 -d /tmp/dbt2-w3 --mysql
```

Please note that output directory for data file should exist.

### Load data

Load data using build_db.sh

```
options:
       -d <database name>
       -f <path to dataset files>
       -s <database socket>
       -v <verbose>
```
Example:
```
bash build_db.sh -d dbt2 -f /tmp/dbt2-w3 -s /tmp/mysql.sock
```

Series of gotcha:

Documentation says to use scripts/mysql/mysql_load_db.sh: this script doesn't exist!
Instead, use script/mysql/build_db.sh

### Run the test
Run test using run_workload.sh
```
usage: run_workload.sh -c <number of database connections> -d <duration of test> -w <number of warehouses>
other options:
       -d <database name. (default dbt2)>
       -h <database host name. (default localhost)>
       -l <database port number>

       -h doesn't specify the database hostname, but prints the help! Use -H instead
       -d is not the database name, but the duration of the test in seconds
```
Series of gotcha:

Documentation says to use scripts/run_mysql.sh: this script doesn't exist!
Instead, use scripts/run_workload.sh

It fails to run unless you also run the follow:
```
export USE_PGPOOL=0
```
Example:
```
sh run_workload.sh -c 20 -d 100
```

WARNING: Please ensure that number of warehouses (option -w) is less of equal
(not greater) to the real number of warehouses that exist in your test
database.

## POSTRUNNING ANALYSES

Results can be found in scripts/output/\<number\>

some of the usefull log files:
- scripts/output/<number>/client/error.log - errors from backend C|SP based
- scripts/output/<number>/driver/error.log - errors from terminals(driver)
- scripts/output/<number>/driver/mix.log - info about performed transactions
- scripts/output/<number>/driver/results.out - results of the test
