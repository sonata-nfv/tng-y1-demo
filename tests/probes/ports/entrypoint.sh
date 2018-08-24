#!/bin/bash

source $1

echo "Telnet configuration: "
echo -e "Logs: \t\t"$LogFile
echo -e "Schema: \t"$SCHEMA
echo -e "VNF External IP: \t"$EXTERNAL_IP
echo -e "Service Port: \t"$PORT

if  [ -z $EXTERNAL_IP ]; then
  echo "Invalid external IP" > $LogFile
  exit 1
else
  opt1="$EXTERNAL_IP"
fi

telnet $EXTERNAL_IP $PORT >> $LogFile ;
echo $? >> $LogFile

