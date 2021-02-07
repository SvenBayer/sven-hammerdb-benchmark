#!/bin/bash

DB_PASSWORD_CONFIG=config/dbpassword.config

if [ ! -f $DB_PASSWORD_CONFIG ]; then
   >&2 echo "Error: ${DB_PASSWORD_CONFIG} does not exist with parameter PG_SUPER_PASSWORD=..."
   exit 1
fi

source $DB_PASSWORD_CONFIG
source config/benchmark.config

HOST=$(echo $PG_HOST | awk -F"." '{print $1}')

BENCHMARK_PATH=$(pwd)
EXTRACT_TP=$BENCHMARK_PATH/extracttp.tcl

LOG_PATH=$BENCHMARK_PATH/log
BUILD_SCHEMA_LOG=$LOG_PATH/$(date +"%FT%T")_build_schema.output
RUN_BENCHMARK_LOG=$LOG_PATH/$(date +"%FT%T")_run_benchmark.output
BENCHMARK_TABLE_LOG=$LOG_PATH/$(date +"%FT%T")_benchmark_table.output

RESULTS_PATH=$BENCHMARK_PATH/results
BENCHMARK_TABLE=$RESULTS_PATH/$(date +"%FT%T")_benchmark_table.txt
AGGREGATED_RESULT=$RESULTS_PATH/$(date +"%FT%T")_aggregated_result.txt
CUMULTOT_AGGREGATED_RESULT=$RESULTS_PATH/cumultot_aggregated_result.txt
RESULTS_LOG=$RESULTS_PATH/results.log

mkdir -p $LOG_PATH
mkdir -p $RESULTS_PATH

if [ ! -f $RESULTS_LOG ]; then
    echo "pg_host,pg_count_ware,pg_num_vu,run_with_num_users,NOPM" >> $RESULTS_LOG
fi

cleanup() {
    echo "Cleanup..."
    export PGPASSWORD=$PG_SUPER_PASSWORD
    dropdb -h $PG_HOST -p $PG_PORT -U $PG_SUPER_USER tpcc
    psql -h $PG_HOST -p $PG_PORT -d postgres -U $PG_SUPER_USER -c "drop role tpcc;"
}

if $CLEAN_UP_BEFORE; then
    cleanup
fi

echo "BASH SCRIPT BEFORE BUILD.."

# Prepare virtual users and warehouses data
cd $HAMMERDB_PATH
./hammerdbcli <<! | tr -d "\r" | ts '[%Y-%m-%d %H:%M:%S]' >> $BUILD_SCHEMA_LOG 2>&1
set argc 6
set argv [list $PG_HOST $PG_PORT $PG_SUPER_USER $PG_SUPER_PASSWORD $NUMBER_WAREHOUSES $NUMBER_VIRTUAL_USERS ]
source $BENCHMARK_PATH/build_schema.tcl
!
echo "BASH SCRIPT AFTER BUILD.."

echo "BASH SCRIPT BEFORE RUN.."

# Execute HammberDB Benchmark
cd $HAMMERDB_PATH
./hammerdbcli <<! | tr -d "\r" | ts '[%Y-%m-%d %H:%M:%S]' >> $RUN_BENCHMARK_LOG 2>&1
set argc 7
set argv [list $PG_HOST $PG_PORT $PG_SUPER_USER $PG_SUPER_PASSWORD $RAMP_UP_TIME_MINUTES $DURATION_MINUTES "${VIRTUAL_USERS[@]}" ]
source $BENCHMARK_PATH/run_benchmark.tcl
!
cd $BENCHMARK_PATH
echo "BASH SCRIPT AFTER RUN.."

echo "BASH SCRIPT BEFORE WRITE RESULTS.."

# Write NOPM into result.log file
ROW=$(cat $RUN_BENCHMARK_LOG | grep -e 'pg_count_ware\|pg_num_vu\|pg_host =' | awk -F"pg_host|||pg_count_ware|||pg_num_vu" '{print $2}' | tr -d "[:blank:]|=" | tr '\n' ',' | sed 's/.$//')
NOPM_AND_USERS=$(cat $RUN_BENCHMARK_LOG | sed -n '/run_with_num_users/,/NOPM/p' | grep -e 'NOPM\|run_with_num_users =' | awk -F"run_with_num_users||| achieved |,| NOPM" '{print $2}' | tr -s "[:blank:]|=" ';' | tr '\n' ',' | sed 's/.$//')
for i in $(echo $NOPM_AND_USERS | sed "s/;/ /g")
do
    # call your procedure/other scripts here below
    echo "$ROW,$i" | sed 's/\,$//' >> $RESULTS_LOG
done

# Extract time-profile and write it into benchmark_table.log
cat $RUN_BENCHMARK_LOG | grep -e ':|\|:+' | awk -F"Vuser [0-9]{1}:+" '{print $2}' > $BENCHMARK_TABLE_LOG

# Convert Pretty Table into CSV table
$EXTRACT_TP $BENCHMARK_TABLE_LOG > $BENCHMARK_TABLE

# Extract aggregated results of time-profile table
cat $BENCHMARK_TABLE_LOG | sed -n '/PROCNAME/,/PERCENTILES/p' | sed 's/^|\(.*\)|$/\1/' | tr -d "[:blank:]" | tr -d '+' | tr -d '-' | tr '|' ',' | sed '/^[[:space:]]*$/d' | sed '/^,/d' > $AGGREGATED_RESULT

# Write table of Cumultative Total Aggregated results
## Write headers of Cumultative Total Aggregated results
if [ ! -f $CUMULTOT_AGGREGATED_RESULT ]; then
    headers="Host,ProcName"
    for virt_users in ${VIRTUAL_USERS[@]}; do
        headers="$headers,CumulTotWithUsers_$virt_users"
    done
    
    echo $headers > $CUMULTOT_AGGREGATED_RESULT
fi

## Write lines of Cumultative Total Aggregated results
PROC_NAMES=("neword" "payment" "delivery" "slev" "ostat" "gettimestamp")
for proc in ${PROC_NAMES[@]}; do
   values=$(cat $AGGREGATED_RESULT | grep -e $proc | awk -F"," '{print $6}' | tr '\n' ',' | sed 's/.$//')
   echo "$HOST,$proc,$values" >> $CUMULTOT_AGGREGATED_RESULT
done

echo "BASH SCRIPT AFTER WRITE RESULTS.."

if $CLEAN_UP_AFTER; then
    cleanup
fi
