#!/bin/bash
#########################################################################
#             Chrome's bookmarks backUp script                          #
#  Usage: ./chrome_backup.sh                                            #
#  Script for automatic backUp chrome's bookmarks to archive `gzip`     #
#  with logining result to `log` file                                   #
#  out_put file: `chrome_bookmarks[current date]`                       #
#                                                                       #
#  Attention: Chrome might stored bookmarks in file                     #
#    "$HOME/.config/google-chrome/$profile/Bookmarks                    #
#  so if your Chrome have more that one profile change 'Default' to     #
#    `Profile #`                                                        #
#                                                                       #
#########################################################################

# profile - chrome's profile folder with bookmarks
# profile="Profile 5"
profile="Default"

# file to backup
FILE="Bookmarks"
bookmarks_file="$HOME/.config/google-chrome/$profile/$FILE"


# backUp folder & error log file
dir_backups="$HOME/temp"
log_file="$dir_backups/error_chrome_backup.log"

# archive file name
archive_file_name="chrome_bookmarks"

# diffrend date formats for backUp file_name and date in log file:
current_date="$(date +"%Y_%m_%d")"                        # 2016_03_27
time_stamp_log="$(date +%Y-%m-%d\ \<%H:%M:%S\>)"          # 2016-03-27 <14:20:35>


echo '*******************************************************************'
echo "Start backup bookmarks at $time_stamp_log"
echo

# -------------- variant with simple copy ---------------------
#
#cp "$bookmarks_file" "$dir_backups" 2> >( while read line; do echo "$time_stamp_log ${line}"; `
#                                                          `done >> "$dir_backups/error_message.txt")
#result=$?
#if [ $result -ne 0 ] ;then
#  echo "Error in \"cp <source_file> <destiny>\" command! Check the path"
#  echo "see more in \"$dir_backups/error_message.txt\""
#  exit 1
#fi


# ------------ case with backup to archive ---------------
#
archive_file_name="$dir_backups"/${archive_file_name}"$current_date".gz

# compress Bookmarks file with gzip, `2>` redirect STDERR to $log_file
gzip -c9 "$bookmarks_file" > "$archive_file_name" 2> >(while read line; do echo "$time_stamp_log ${line}"; done >> "$log_file")

# safe mode branch
result=$?
if [ $result -ne 0 ] ;then
  echo "Error in \"gzip\" command! See more in $log_file"
  echo "$time_stamp_log Error code in \"gzip\" command: status $result" >> "$log_file"
# Delete empty gzip archive 
# test -f "$archive_file_name" && rm "$archive_file_name"
  echo "The backUp interrupted."
  echo '-----------------------'
  exit 1
else
  echo -e "$time_stamp_log $archive_file_name  create status: Ok\n" >> "$log_file"
  echo 'BackUp complite!'
  echo "File saved in $archive_file_name"
  echo '*******************************************************************'
fi


exit 0
