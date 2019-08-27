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

echo "Old database name:   $db_old_name"
echo "New database name:   $db_new_name"
echo "System encoding:     $LANG"
echo "---------------------------------"

# creating database dump
mysqldump -u $user -h $host_from $db_old_name > $dump_file
result=$?
if [[ $result -ne 0 ]]
  then
    echo "Result:  error in \`mysqldump $db_old_name\` command!"
    echo "Script aborted"
    exit $result
  else
    echo "mysqldump result: Ok"
    echo '--------------------------------------------'
fi


# creating new database from dump
mysqladmin -u $user -h $host_from create $db_new_name
result=$?
if [[ $result -ne 0 ]]
  then
    echo "error in \`mysqladmin create $db_new_name\` command"
    echo
    exit $result
  else
    echo "\`mysqladmin create database\` result: Ok"
    echo '------------------------------------------'
fi

mysql -u $user -h $host_from $db_new_name < $dump_file


echo 'rename database in fields priveleges tables:'
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