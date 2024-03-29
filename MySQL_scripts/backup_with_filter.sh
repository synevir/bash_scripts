#!/bin/bash
#########################################################################
#             Filtered Backup of tables script                          #
#                                                                       #
# Dump database tables usign pattern                                    #
# Usage ./backup_with_filter.sh [options]                               #
#                                                                       #                                                                       
# Options:                                                              #
#       -p pattern                                                      #
#       default pattern `LIKE '%'` (dump all tables of database)        #
#                                                                       #                                                                       
#########################################################################

# Original commands has gotten from site hightload.today
#
# DBNAME=**database**
# PATTERN=**%pho%**
#
# mysql -N information_schema -e "select table_name from tables where 
# table_schema = '`echo $DBNAME`' AND table_name like '`echo $PATTERN`'" > tables.txt
# mysqldump `echo $DBNAME` `cat tables.txt` | gzip > dump.sql.gz






# Default database and pattern for dump
db_name='test'
pattern="%"
all_tables='n'

#echo "database: $db_name"
#echo "pattern:  $pattern"
#echo "*********************"


while [ -n "$1" ]; do
  case "$1" in
    -d) db_name="$2"
          #echo "Found the -d option named $db_name"
          shift;;
    -p) pattern="%$2%"
          #echo "Found the -p option, with pattern string: $pattern"
          shift;;
    --) shift; break ;;
     *) echo "$1 is not an option";;
  esac

  shift
done


echo "database: $db_name"
echo " pattern: $pattern"


if [ "$pattern" == "%" ]
  then
    read -t 10 -p "Empty pattern. Dump all tables? [n] " all_tables
    if [[ "$all_tables" == "n" || "$all_tables" == "" ]]
      then 
        echo "....dump canseled"
        exit 0
    fi

fi

echo "--------------"

# Create a list of tables
mysql -N information_schema -e "SELECT table_name FROM tables WHERE 
table_schema = '`echo $db_name`' AND table_name LIKE '`echo $pattern`'" > tables.txt

# Create tables dump
mysqldump `echo $db_name` `cat tables.txt` | gzip > dump.sql.gz


echo "Tables list to dump:"
cat tables.txt
rm tables.txt
echo
echo "Dump complited."
echo
exit 0
