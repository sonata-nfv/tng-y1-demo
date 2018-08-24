#!/bin/bash

source $1

echo "Traffic generator configuration: "
echo -e "Logs: \t\t"$LogFile
echo -e "Schema: \t"$SCHEMA
echo -e "VNF External IP: \t"$EXTERNAL_IP
# echo -e "Service Port: \t"$PORT
# echo -e "Connections: \t"$CONNECTIONS
# echo -e "Duration: \t"$DURATION
# echo -e "Threads: \t"$THREADS
# echo -e "Header: \t"$HEADER
# echo -e "Timeout: \t"$TIMEOUT
# echo -e "Rate_array: \t\t"$RATES

if  [ -z $EXTERNAL_IP ]; then
  echo "Invalid external IP" > $LogFile
  exit 1
else
  opt1="$EXTERNAL_IP"
fi


ping -c5 $EXTERNAL_IP >> $LogFile ; 
echo $? >> $LogFile 

#ping -c5 $EXTERNAL_IP &> /dev/null ; echo $? >> $LogFile

#ping -q -w1 -c5 $EXTERNAL_IP &>/dev/null && echo online || echo offline


#  echo "COMMAND: /usr/local/bin/wrk -s result.lua $opt1"
# /usr/local/bin/wrk -s /app/result.lua  $opt1 





