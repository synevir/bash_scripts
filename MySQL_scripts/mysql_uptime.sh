#!/bin/sh
#################################################
#  Script reports MySQL server uptime, opened   #
#  connections, version and other information   #
#  Usage:                                       #
#  $ ./mysql_uptime.sh                          #
#################################################

echo '____________________________'
echo "Server UpTime now:  "
mysql -N -s -e "SHOW STATUS LIKE 'Uptime'"

echo '____________________________'
echo "Count of current connection:   "
mysql -N -s -e "SHOW STATUS LIKE 'Threads_connected'"
echo

mysql -e "STATUS"

