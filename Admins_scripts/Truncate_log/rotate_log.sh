#!/bin/bash

######################################################################
#
# Script calculates the number of lines in the text log files ($LOGS)
# and deletes a specified percentage (constant "TRUNC_PERSENTAGE") 
# of lines from the files beginning (the oldest records).
#
# Usage:  `./rotate_log.sh`      truncates files from $LOGS variable
#         `./rotate_log.sh 'log_file_1 log_file_2....'`    trancates
# files from $LOGS and "log_file_1 log_file_2...." files.
#
######################################################################

LOGS="$HOME/.bash_history 
      $HOME/.mysql_history"
TRUNC_PERSENTAGE=30


# Checking for additional file to truncate
[[ -s $1 ]] && LOGS="$LOGS $1"

echo "------   Trancate Ratio = $TRUNC_PERSENTAGE%    ------" #| tee -a $LOG

for FILE in $LOGS
do
    echo
    echo -n "FILE: \"$FILE\""

    # If file exists and has one or more lines
    if [[ -s $FILE ]]
    then
        echo
        echo "---------------------------"
        total_lines=`grep -c $ "$FILE"`
        echo "Contains $total_lines lines."

        # Calculate number lines to delete
        let number_of_lines_to_delete=$total_lines*$TRUNC_PERSENTAGE/100
        echo "Number lines to delete - $number_of_lines_to_delete"
        echo 'Delete lines.......'

        if [[ $number_of_lines_to_delete -ge 1 ]]
        then
            sed -i '1,'"$number_of_lines_to_delete"'d' $FILE
            [[ $? -eq 0 ]] && echo "$number_of_lines_to_delete lines were deleted" || echo "sed Error!"
        else
            sed -i '1,1d' $FILE
            [[ $? -eq 0 ]] && echo "1 line was deleted." || echo "sed Error!"
        fi
    else
        echo " is not exist or has no lines."
    fi
done

echo
exit 0



# total_lines=`grep -c $ $FILE`
# total_lines=`cat $FILE | wc -l`
# total_lines=`sed -n \$= $FILE`
