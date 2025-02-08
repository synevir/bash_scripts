#################################################################
#  Script for monitoring S.M.A.R.T. attributes of HDD devices.  #
#                                                               #
#  Script read `smartctl` command output for HDD devices list,  #
#  creates `result_file` for each disk and then compare with    #
#  previous date files (oldest and last). Analyze the attribute #
#  changes is saved to "report_<current_date>" file.            #
#                                                               #
#################################################################


source "color_echo.sh"

# Result and Report files storage dir:
STORAGE_DIR='~/Bash/Admins_scripts/SMART_HDD'

# SMART attributes list for monitoring:
MONITORING_LIST=' Raw_Read_Error_Rate    Reallocated_Sector
                  Seek_Error_Rate        G-Sense_Error
                  Calibration_Retry      ECC_Recovered
                  UDMA_CRC_Error         Celsius
                  Spin_Retry_Count       Multi_Zone_Error
'


# Function checks if `RAW_VALUE` has been changed
function CheckDiff {    # string_value_was  string_value_now
  [[ $1 = $2 ]] && return 0

  str_value_was=$1
  str_value_now=$2                                        # RAW_VALUE
#  ------------------------------------------------------------------
#  1 Raw_Read_Error_Rate  0x002f 100 100 051  Pre-fail Always  -  18
#  1 Raw_Read_Error_Rate  0x002f 100 100 051  Pre-fail Always  -  69
#  ------------------------------------------------------------------

  # take a raw_value from string (last word in the string)
  # беремо останне слово у рядку (розділювач - пробіл)
  raw_value_was=$(echo ${str_value_was##* })
  raw_value_now=$(echo ${str_value_now##* })

  # was `RAW_VALUE` changed?
  if [[ $raw_value_was != $raw_value_now ]]
  then
      let changed_attributes_count++ ;
      echo ;       echo      >> $report_file
      echo "$1";   echo "$1" >> $report_file
      echo "$2";   echo "$2" >> $report_file
      let delta=$raw_value_now-$raw_value_was
      EchoRed "                 delta: $delta"
      echo    "                 delta: $delta" >> $report_file
  fi
}



#==============================
#        START MAIN CODE
#==============================
clear

# Device list
# smartctl --scan
sda='sda'
sdb='sdb'

# Are you root?
[[ $(whoami) != 'root' ]] && { echo "You are not root! Use sudo."; exit 0; }
cd $STORAGE_DIR

#-----------------
# Create reports
#-----------------

create_date=$(date +%Y%m%d)
report_file="report_$(date +%Y_%m_%d)"
current_timestamp=$(date +%s)

# затираємо вже існуючий report файл, або створюємо новий
echo "Результат аналізу S.M.A.R.T."
echo "Host name: '`hostname -s`'"
echo "Результат аналізу S.M.A.R.T." > $report_file
echo "Host name: '`hostname -s`'"  >> $report_file


for disk in $sda $sdb
do
    device='/dev/'$disk
    result_file=$disk'_'$create_date'.txt'
    echo $result_file
    echo $result_file >> $report_file
    sudo smartctl -A $device > $result_file            # without `sudo` command in crontab doesn't work correctly
#   smartctl -a $device | grep Model >> $result_file   # назва та модель диска
#   sudo smartctl -a $device |
#                      sed '/SMART\ Error\ Log\ Version:/,$d'  |
#                      sed '/LU WWN Device Id:/,  /SCT\ Data\ Table\ supported/ d' > $result_file
    echo "Disk: $disk" >> $result_file
    echo "Timestamp: $(date +%s)" >> $result_file


# -------------------------
# Do we have old reports?
# `atime` - POSIX
# `ctime` works only on Ext4, ZFS, XFS

     oldest_file=$result_file
     oldest_file_date=$create_date
     last_file=$result_file
     last_file_date=$create_date

     files_list=$disk*

# ------- Find out <LAST> report and OLDEST report files
     for file in $files_list
     do
          # extract date from file name
          file_date=${file: -12}              # беремо останні 12 символів
          file_date=${file_date%.*}           # беремо усі символи до першої крапки

          # check if the report file is olderst in folder
          if [[ $file_date < $oldest_file_date ]]
          then
               oldest_file=$file
               oldest_file_date=$file_date
               if [[ $file_date < $create_date ]]
               then
                   last_file=$file
                   last_file_date=$file_date
               fi
          fi
     # check if the report file is last report file
          if [[ $file_date > $last_file_date ]] && [[ $file_date != $create_date ]]
          then
               last_file=$file
               last_file_date=$file_date
          fi
     done


     echo "=========================="
     echo "==========================" >> $report_file
     echo "Report for disk '$disk':"
     echo "Report for disk '$disk':"   >> $report_file
     echo "=========================="
     echo "==========================" >> $report_file

# -------  Diff with <LAST> smartctl report

     # обчислюємо кількість днів між перевірками
     file_timestamp=$(stat -c %Y $last_file)
     let file_age=($current_timestamp-$file_timestamp)/86400 #--> 1day = 60sec*60min*24h
     last_file_date=${last_file_date:0:2}-${last_file_date:0:2}-${last_file_date:4:2}

     echo -n "Diff with  < LAST >  check for disk \`$disk\` on $last_file_date   ($file_age days ago): "
     echo -n "Diff with  < LAST >  check for disk \`$disk\` on $last_file_date   ($file_age days ago):" >> $report_file

     changed_attributes_count=0
     for attribute in $MONITORING_LIST
     do
         string_last_value=$(grep $attribute $last_file)
         string_res_value=$(grep $attribute $result_file)
         CheckDiff "$string_last_value" "$string_res_value"
     done
     [[ $changed_attributes_count = 0 ]] && (EchoGreen "no changes, Ok!"; echo " Ok!">> $report_file )


# -------  Diff with OLDEST smartctl report

     # обчислюємо кількість днів між перевірками
     file_timestamp=$(stat -c %Y $oldest_file)
     let file_age=($current_timestamp-$file_timestamp)/86400 #--> 1day = 60sec*60min*24h

     echo -n "Diff with   OLDEST   check for disk \`$disk\` on $oldest_file_date   ($file_age days ago):"
     echo -n "Diff with   OLDEST   check for disk \`$disk\` on $oldest_file_date   ($file_age days ago):" >> $report_file

     changed_attributes_count=0
     for attribute in $MONITORING_LIST
     do
          string_old_value=$(grep $attribute $oldest_file)
          string_value_now=$(grep $attribute $result_file)
          CheckDiff "$string_old_value" "$string_value_now"
     done
     [[ $changed_attributes_count -eq 0 ]] && (EchoGreen "no changes, Ok!"; echo >> $report_file )

     echo
     echo >> $report_file

done
echo
exit 0

# Some echo tricks:
# --------------------------
# T='first second third fourth'; echo ${T##* }
# DATE=2022-09-09; echo ${DATE//-/_}
# d=09122024; echo ${d:0:2}-${d:2:2}-20${d:4:2}    #-->  09-12-2024
# touch "crontab_$(date +\%Y-\%m-\%d)"
