#!/bin/bash
#################################################
#    ./rename_db.sh                             #
#    script for rename database in MySQL        #
#    using mysqladmin                           #
#################################################
user="root"
host_from="localhost"
db_old_name="bash"
db_new_name="bash_4"
dump_file=$db_old_name.sql
# temporary dir
# temp_dir=$HOME

echo $db_old_name
echo $db_new_name
echo $LANG
mysqldump -u $user -h $host_from $db_old_name > $dump_file
mysqladmin -u $user -h $host_from create $db_new_name
result=$?

if [[ $result -ne 0 ]]
  then
    echo "error \"mysqladmin create $db_new_name\""
    exit $result
  else
    echo "result \"mysqladmin create database\": Ok"
fi

mysql -u $user -h $host_from $db_new_name < $dump_file

# визуальная проверка наполнения таблицы в новой базе
# mysql -u $user -h $host -e "select id from s limit 10" $db_new_name

# rename database in fields priveleges tables
tables_privileges="db tables_priv columns_priv host"
for tbl_name in ${tables_privileges}
  do
      query="UPDATE $tbl_name SET Db = '$db_new_name' WHERE Db='$db_old_name'"
      echo $query
      mysql -u $user -h $host_from -e "$query" mysql
      if [[ $? -ne 0 ]];  then  echo "error in query: \"$query\""
      fi
  done


exit 0