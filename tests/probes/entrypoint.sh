#!/bin/bash

source $1

echo "Traffic generator configuration: "
echo -e "Logs: \t\t"$LogFile
echo -e "Schema: \t"$SCHEMA
echo -e "VNF External IP: \t"$EXTERNAL_IP
echo -e "Service Port: \t"$PORT
echo -e "Connections: \t"$CONNECTIONS
echo -e "Duration: \t"$DURATION
echo -e "Threads: \t"$THREADS 
echo -e "Header: \t"$HEADER
echo -e "Timeout: \t"$TIMEOUT
echo -e "Rate: \t\t"$RATE

if [ -z $SCHEMA ] || [ -z $EXTERNAL_IP ] || [ -z $PORT ]; then
  echo "VNF Under Test endpoint was not set" > $LogFile
  exit 1
else
  opt1="$SCHEMA$EXTERNAL_IP:$PORT"
fi

if [ -z $CONNECTIONS ]; then
  opt2="-connections 200"
else
  opt2="--connections $CONNECTIONS"
fi

if [ -z $DURATION ]; then
  opt3="--duration 300s"
else
  opt3="--duration $CONNECTIONS"
fi

if [ -z $THREADS ]; then
  opt4="--threads 5"
else
  opt4="--threads $THREADS"
fi

if [ -z $TIMEOUT ]; then
  opt5="--timeout 30s"
else
  opt5="--timeout $TIMEOUT"
fi

if [ -z $RATE ]; then
  opt6="--rate 50"
else
  opt6="--rate $RATE"
fi

if [ -z $HEADER ]; then
  opt7=""
else
  opt7="--header $HEADER"
fi

echo "COMMAND: /usr/local/bin/wrk $opt2 $opt3 $opt4 $opt5 $opt6 $opt7 --latency $opt1"
/usr/local/bin/wrk $opt2 $opt3 $opt4 $opt5 $opt6 $opt7 --latency $opt1 > $LogFile
