#!/bin/bash

# Script makes backup copy of the file to specified directory 
#    and adds timestamp to file_name
# Usage: backup_file <file_name>
# To specify backup directory change `backup_dir` variable

backup_dir=~/Temp
backup_name=$backup_dir/$1.`date +%Y%m%d_%H%M.bak`

cp -p $1 $backup_dir
mv "$backup_dir/$1" $backup_name

echo "$1 ---> was backed up to \`$backup_name\`"
exit 0




