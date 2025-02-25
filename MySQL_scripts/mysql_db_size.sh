################################################################
# Script outputs database size. 
# 
#   The size calculated as summa "data_length" + "index_length" 
#   columns from "information_schema.TABLES" table.
# 
# Usage: `mysql_db_size.sh <database name>`, where <database> 
#   is pattern for database name in "HAVING" clause.
#   By default calculates size for all databases on the server 
#   and ordered by database size DESC
# 
################################################################



# Default pattern for <database name>
DB_NAME='%'

if [ $# -lt 1 ]; then
  echo "Usage: mysql_size <database name>"
  echo "Default database name '%'"
  else DB_NAME="$1"
fi


query="SELECT table_schema As 'db_name', 
              count(*) As 'tables in db',
              TRUNCATE( SUM(data_length + index_length) / POWER(1024,2) , 3) As 'DB size, Mb'
       FROM information_schema.TABLES
       Group BY table_schema
       Having table_schema Like'$DB_NAME'
       Order By 3 DESC;"
 
mysql -e "$query"

#echo $query
echo
echo

