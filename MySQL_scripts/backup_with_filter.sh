#!/bin/bash
#########################################################################
#             Filtered Backup of tables script                          #
#                                                                       #
# Dump database tables usign pattern                                    #
# Usage ./backup_with_filter.sh [options]                               #
#                                                                       #
# Options:                                                              #
#       -d <database name> to dump                                      #
#       -p <pattern> tables to dump, default pattern `LIKE '%'`         #
#                                    (dump all tables in database)      #
#       -7z use 7z for dump compress                                    #
#           Warning: 7z pipeline mode don't save file access mode, so   #
#                    after uncompress dump use `chmod =440` command     #
#                                                                       #
#########################################################################

# For example:
#   backup_with_filter.sh -d some_base -p em
# will create dump "some_base" database with pattern LIKE'*em*':
#   mysqldump `some_base` [`em_table` `table_em2` .....] | gzip > dump.sql.gz
# You can change pattern format in "Read option section"


# Original commands has gotten from site highload.today
#
# DBNAME=**database**
# PATTERN=**%pho%**
#
# mysql -N information_schema -e "select table_name from tables where 
# table_schema = '`echo $DBNAME`' AND table_name like '`echo $PATTERN`'" > tables.txt
# mysqldump `echo $DBNAME` `cat tables.txt` | gzip > dump.sql.gz






# Default options for dump:
db_name='test'
pattern="%"
all_tables='n'
ERROR_LOG='error.log'
compressor='gzip'
echo '--------------------------------------------------------'

# Check server availability
mysql -e "SELECT current_user()\G" > /dev/null
result=$?
[[ $result -ne 0 ]] && { echo -e ".....script aborted!\n"; exit 0; }


# Read options section
while [ -n "$1" ]; do
  case "$1" in
    -d) db_name="$2"
          #echo "Found the -d option named $db_name"
          shift;;
    -p) pattern="%$2%"
          #echo "Found the -p option, with pattern string: $pattern"
          shift;;
    -7z) compressor="7z"
          #echo "Found the -7z option, use 7z format in stream mode"
          shift;;
    --) shift; break ;;
     *) echo "$1 is not an option";;
  esac

  shift
done

echo
echo "  database: $db_name"
echo "   pattern: $pattern"
echo "compressor: $compressor"


if [ "$pattern" == "%" ]
then
    read -t 10 -p "Empty pattern. Dump all tables? y/n [n]: " all_tables
    if [[ "$all_tables" == "n" || "$all_tables" == "N" || "$all_tables" == "" ]]
    then
        echo "....dump canseled"
        exit 0
    fi
fi

echo "---------------"


# Create a list of tables
echo -n "Create list of tables to dump..."
mysql -N information_schema -e "SELECT table_name FROM tables WHERE 
table_schema = '`echo $db_name`' AND table_name LIKE '`echo $pattern`'" > tables.txt 2> $ERROR_LOG
echo "Ok!"
echo "Tables list to dump:"
cat tables.txt


# Create tables dump
case "$compressor" in
    gzip) mysqldump `echo $db_name` `cat tables.txt` 2>> $ERROR_LOG | gzip > dump.sql.gz ;;
      7z) mysqldump `echo $db_name` `cat tables.txt` 2>> $ERROR_LOG | 7z a -si -mx5 dump.sql.7z ;;
      # `7z -si` option works equal `>>` (add), 
      #  so if you already have `dump.sql.7z` you must delete it before create new dump! 
esac

rm tables.txt
echo
echo "Dump complited:"
ls -o dump.sql*
echo
exit 0
