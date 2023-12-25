# ----------------------------------------------------------------------------------------------------------------
# `check_synck.sh` is a script to check the synchronization of replicated tables without stopping replication. 
# On the master server, in the database being replicated a service table is created, where 
# the checksums of the tables are written.
# Replication on the slave repeats these commands. After that the master/slave checksums can be compared.
# Also, with a time stamp value, you can roughly estimate the delay of the slave from the master.
#
# Application algorithm:
# Stage #1 Run script in CHECK_SUM_MASTER MODE ~> check_sync.sh -m
#     The script on the master in the replicated database creates a service table with the checksums 
#     of the tables from the database, which is checked.
#
# Stage #2 Compare checksums ~> check_sync.sh   or  `check_sync.sh | grep -b3 'NOT SYNC` for list unsync tables
#     The script gets the checksums from the tables on the master/slave and compares them.
#     Table with checksums is saved on master-server until the next run of the stage#1.
#     
# options:
#         -m CHECK_SUM_MASTER mode 'ON'
#         -d replication database_name
#         -t table_name for check syns. Default value '*' (check all tables in database)
# 
# ----------------------------------------------------------------------------------------------------------------
# ATТENTION! The `checksum table` command do FULL SCAN for checking table, so for the big tables it might to take
# a lot of time with block the talbe with read lock.
# To get promptly table's checksum values for MyISAM engine tables recommended to query 
# INFORMATION_SCHEMA.TABLES table.
# ----------------------------------------------------------------------------------------------------------------

set -e

# -------------------------------------------------------------------------------------------------------------
# Default values section
# -------------------------------------------------------------------------------------------------------------
DB='joints'                                          # Database name
TB='chk'                                             # Name or service table where to store checksums
DB_TB="$DB.$TB" 
SYNC_TB='*'                                          # Table for check synchronization. Default all tables

MASTER_HOST='localhost'
SLAVE_HOST='localhost'

CHK_MM='OFF'                                         # CHECK_SUM_MASTER mode ON/OFF
DROP_SERVICE_TABLE='OFF'
# -------------------------------------------------------------------------------------------------------------



# Without options script works with default options (DEFAULT MODE)
if [ $# -eq 0 ] ; then
      echo 'Options are not found! Script works in "DEFAULT MODE"'
fi


# Get options and params from command line
while getopts "md:t:" opt ;  do
     case $opt in
         m) echo "CHECK_SUM_MASTER MODE=ON"
            CHK_MM='ON' ;;
         d) echo Database to check synchronization:   ${OPTARG}   
            DB=${OPTARG} ;;
         t) echo "Sync table: " ${OPTARG}  
            SYNC_TB=${OPTARG} ;;
         :) echo "Error: option ${OPTARG} requires an argument"  ;;
         ?) echo "Invalid option: ${OPTARG}"
            exit 1 ;;
         *) echo "Additional option: ${OPTARG}";;
     esac
done

echo 'Options list'
echo -------------------------------
echo "       Database : $DB"
echo "Table(s) to sync: $DB.$SYNC_TB"
echo "   service table: $DB.$TB"
echo



# compare_checksums [1]$table_name, [2]$master_checksum, [3]$slave_checksum, [4]$master_timestamp, [5]$slave_timestamp
function compare_checksums {  
  if [[ $3 == $2  ]] ; then
      echo "$1 ~> Cheksum status: OK "
      (( lag=$5-$4 ))
      echo "lag: $lag sec."
    else 
      echo "Sync status:   NOT SYNC!"   
  fi
  echo 'SUMMARY:'
  echo "master checksum: $master_checksum"
  echo " slave checksum: $slave_checksum"
  echo "      master TS: $master_timestamp"
  echo "      slave  TS: $slave_timestamp"
  echo ==================================
  echo
}



# ====================================================
#       CHECKSUM_MASTER MODE Section
# ====================================================
# if [ "$CHK_MM"='ON' ] ; then
# .......  section content .......
# exit 0
# fi


# Create table for store `checksum table` result
mariadb -e "drop table IF EXISTS $DB_TB"
mariadb -e "CREATE TABLE $DB_TB(tbl_name VARCHAR(64), chk_sum BIGINT(21) UNSIGNED, dt DATETIME)"
echo Creating service table \'$DB_TB\' on \'$MASTER_HOST\' - Ok.
echo
                                                            
# Tables list for check sync
if [ "$SYNC_TB" = '*' ] ; then
        tables=(`mariadb -N -e "SHOW tables FROM $DB"`)       
    else
        tables="$SYNC_TB"
fi

# For each table in database $DB do `CHECKSUM TABLE` and INSERT to service table
for tbl in "${tables[@]}"; do
    echo Processing table: $tbl
    echo -------------------------------------------
    
  # Skip service table
    if [[ "$tbl" == "$TB" ]] ; then continue
    fi
  
  # Get CHECKSUM for table
    str_val=`mariadb --host=$MASTER_HOST -N -e "CHECKSUM TABLE $DB.$tbl"`
    checksum_table_result=($str_val)                   # split result string into array of words
    table_name=\'${checksum_table_result[0]}\'         # add "'" to $table_name value
    table_checksum=${checksum_table_result[1]}
    
    echo "Database:  $DB"
    echo "table:     $table_name"
    echo "checksume: $table_checksum"
    echo

  # Insert checksum into service table 
    str_insert="INSERT INTO $DB_TB(tbl_name, chk_sum, dt) VALUES($table_name, $table_checksum, NOW())"    
    mariadb -e "$str_insert"
done

master_timestamp=`mariadb -N -e 'SELECT UNIX_TIMESTAMP(now())'`
echo Creating CHEKSUM table complited with master time_stamp $master_timestamp
echo

# ---------------------------------------------------
#      End of CHECKSUM_MASTER MODE Section
# ---------------------------------------------------

# ====================================================
#       CHECKSUM_SLAVE MODE Section
# ====================================================

# Tables list for check sync
if [ "$SYNC_TB" = '*' ] ; then
        tables=(`mariadb -N -e "SHOW tables FROM $DB"`)       
    else
        tables="$SYNC_TB"
fi


for tbl in "${tables[@]}"; do
    echo Processing table: $tbl
    echo -------------------------------------------
  
  # Skip service table
    if [[ "$tbl" == "$TB" ]] ; then
        echo; continue ;
    fi
    
    tbl_name=\'$DB.$tbl\'    
  # Get checksum from MASTER/SLAVE hosts
    query="SELECT chk_sum FROM $DB_TB WHERE tbl_name=$tbl_name;"
    slave_checksum=`mariadb --host=$SLAVE_HOST -N -e "$query"`
    master_checksum=`mariadb --host=$MASTER_HOST -N -e "$query"`
    
  # Get timestapms SLAVE-MASTER for calc repliacation lag
    query="SELECT UNIX_TIMESTAMP(dt) FROM $DB_TB WHERE tbl_name=$tbl_name;"    
    slave_timestamp=`mariadb --host=$SLAVE_HOST -N -e "$query"`
    slave_timestamp=`expr $slave_timestamp + 10`                        # add manual +10 sec. lag for test 
    master_timestamp=`mariadb --host=$MASTER_HOST -N -e "$query"`
    
  # Compare checksums and timestamps MASTER/SLAVE   
    compare_checksums $tbl $master_checksum $slave_checksum $master_timestamp $slave_timestamp

done

