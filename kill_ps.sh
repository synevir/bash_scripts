#!/bin/bash

#########################################################################
# $ ./kill_ps.sh [number]
# Program kill all proceses of 'tty pts/{number}' user
# Needs `root` priveleges level
#
# Usage:
# At first do 'who' or 'w' command
# in result list select 'pts/{number}' of tty for kill it's processes
# ./kill_ps.sh {number}
#
##########################################################################

number_pts='pts/'$1
echo 'delete pids of '"$number_pts"

for pid_number in `ps -A | grep "$number_pts" | awk '{print $1}'` ; do
  echo 'delete PID ' $pid_number

  kill  -KILL $pid_number
done

