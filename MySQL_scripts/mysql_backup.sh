#!/bin/bash
#########################################################################
#             Buckup MySQL databases script                             #
#                    (using mysqldump)                                  #
#                                                                       #
# Dump file of a database called "<database_name>_<current_date>"       #
# All dump files stored in directory "<dir_dest>/current_date/"         #
#                                                                       #
# If `root` user have a password, change value <mysql_pass>,            #
# uncomment commented rows marked '# need a password ...'               #
# and comment next row.                                                 #
# The same is true with respect to the <mysql_host> unlike "localhost"  #
# Recomend to create speсial user for dump:                             #
#   GRANT SELECT, LOCK TABLES ON .* TO <user-dumper>@localhost          #
#         IDENTIFIED BY '<dumper-password>';FLUSH PRIVILEGES;           #
#                                                                       #
# To improve safety you can set access on <dir_dest> only for root.     #
# For this uncomment section '# Only root can access it!'               #
#                                                                       #
# Usage ./mysql_backup.sh [options] <value>                             #
#                                                                       #
# Options:                                                              #
#       -z compress `*.sql` files by `gzip -<value>`                    #
#           <value> compress ratio from 1 to 9 (default ratio value 5)  #
#       -d add to mydsqldump --add-drop-database options                #
#                                                                       #
#########################################################################

mysql_user="root"                       # username with Grand priveleges for dump
mysql_pass=""                           # password for user
mysql_host="localhost"                  # hostname or IP of MySQL server

compress_ratio=5                        # default comperss ratio for gzip

# If compression is used determine compress ratio 
if [[ -n $2 ]] && [[ $2 -ge 1 ]] && [[ $2 -le 9 ]]
then
    comperss_ratio=$2
fi


# Ignore databases list. Use space between bases.
ignore_bases="test information_schema performance_schema"

echo '*******************************************************************'
echo 'Start backup databses'

# Get data in yyyy_mm_dd format
current_date="$(date +"%Y_%m_%d")"

# Backup destination directory
dir_dest="$HOME/temp/tmp"
echo "dir_dest: $dir_dest"

# BackUp directory where backup will be stored
dir_backups="$dir_dest/$current_date"
echo "dir_backups:  $dir_backups"

# log file with explanations
read_mee="$dir_backups"/dumping_databases_list.txt

if [ ! -d $dir_backups ]
then
    echo "dir $dir_backups is absent, .......... create dir"
    mkdir -p $dir_backups
fi


#----------------------------
# Only root can access it!
# ---------------------------
#chown root:root -R $dir_dest
#chmod 0600 $dir_dest

# Create databases list
#------------------------
# need a password line:
# databases="$(mysql -u $mysql_user -h $mysql_host -p$mysql_pass -Bse 'show databases')"
databases="$(mysql -u $mysql_user -Bse 'show databases')"


# filling some information to the log file
echo "List of dumping databases in $read_mee"
echo "Dump create $current_date" > "$read_mee"
echo "-------------------------" >> "$read_mee"
echo "Warning: if you made dump with out compression the *.sql files include commands:" >> "$read_mee"
echo "\"DROP DATABASE IF EXIST...\"    \"CREATE DATABASE...\"    \"USE...\"" >> "$read_mee"
echo >> "$read_mee"
echo "Dumped databases list:" >> "$read_mee"
echo "-------------------------" >> "$read_mee"
echo "$databases" >> "$read_mee"


for db in $databases
do
    skipdb=-1
    if [ "$ignore_bases" != "" ]
    then
        for i in $ignore_bases
        do  [ "$db" == "$i" ] && skipdb=1 || :
        done
    fi

    if [ "$skipdb" == "-1" ]
    then
       FILE="$dir_backups"/"$db"_"$current_date".sql

       # Create dump file and gzip after that
       if [[ $1 == "-z" ]]
       then
           # `need a password` line:
           #  mysqldump -u "$mysql_user" -h "$mysql_host" -p"$mysql_pass" "$db" | gzip -9 > "$FILE".gz
           echo -en "Dumping database $db..."
           mysqldump -u "$mysql_user" "$db" | gzip -$compress_ratio > "$FILE".gz
           result=$?
           if [ $result -ne 0 ]
           then
               echo "error in \"mysqldump -u $mysql_user -h $mysql_host $db\""
               echo "error $result in \"mysqldump ...\"" >> error.log
           else
               echo " - Ok"
           fi
       else
           # If you need uncompressed dump
           mysqldump --add-drop-database -u $mysql_user -B $db > "$FILE"
       fi
    fi
done
echo 'creating backup complite!'
echo

exit 0
