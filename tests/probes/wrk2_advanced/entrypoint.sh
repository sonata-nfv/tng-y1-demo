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
echo -e "Rate_array: \t\t"$RATES

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
  opt6="50"
else
  opt6="$RATE"
fi

if [ -z $HEADER ]; then
  opt7=""
else
  opt7="--header $HEADER"
fi

for RATE in $RATES; do
  echo "COMMAND: /usr/local/bin/wrk -s result.lua $opt2 $opt3 $opt4 $opt5 --rate $RATE $opt7 --latency $opt1"
  /usr/local/bin/wrk -s /app/result.lua $opt2 $opt3 $opt4 $opt5 --rate $RATE $opt7 --latency $opt1 > $RATE.tmp
  cat $RATE.tmp >>  $LogFile
  /bin/cat $RATE.tmp | tail -90 | jq '{requests, duration_in_microseconds, bytes, requests_per_sec, bytes_transfer_per_sec, latency_distribution}' > rate-$RATE.json
  /bin/cat $RATE.tmp | tail -90 | jq '{ graphs }' > graphs-$RATE.json
  /bin/cat $RATE.tmp | tail -90 | jq "{ requests_per_sec, \"requests\": $RATE }" > overall-$RATE.json
done

# Processing data

# Creating details.json file

let counter=0

# Obtain the json generated list
requests=`ls rate*.json | tr "." "\n" | tr -d "rate-" | grep -v json | xargs`

jsondetail=`echo '{"detail": [] }' | jq .`

for i in $requests
do
  join_json=`cat rate-$i.json`
  let iteration=$counter+1
  jsondetail=`echo $jsondetail | jq ".detail[$counter] +=  $join_json"`
  let counter++
done

echo $jsondetail | jq . > details.json

# Creating graphs object

# Variables initialization
let counter=0

# Obtain the json generated list
requests=`ls graphs*.json | tr "." "\n" | tr -d "graphs-" | grep -v json | xargs`

graphs=`echo '{"graphs": [] }' | jq .`

# Adding data to graphs object
for i in $requests
do
  join_json=`cat graphs-$i.json`
  let iteration=$counter+1
  graphs=`echo $graphs | jq ".graphs[$counter] += join_json"`
  let counter++
done

echo $graphs | jq . > graphs.json


# Variables initialization
let counter=0

# Obtain the json generated list
requests=`ls overall*.json | tr "." "\n" | sed 's/\overall-//g' | grep -v json | xargs`

# Graph template
json=`echo '{"graphs": [ { "title": "Http Benchmark test", "x-axis-title": "Iteration", "x-axis-unit": "#", "y-axis-title": "Requests per second", "y-axis-unit": "rps", "type": "line", "series": { "s1": "requests_sent", "s2": "requests_processed" }, "data": { "s1": [], "s2": [] } }]} '`

# Adding data to graphs object
for i in $requests
do
  join_json=`cat overall-$i.json`
  let iteration=$counter+1
  s1=`echo $join_json | jq '.requests_per_sec'`
  s2=`echo $join_json | jq '.request_sent'`
  json=`echo $json | jq ".graphs[0].data.s1[$counter] += { \"x-axis\": $iteration, \"y-axis\": $s1 }"`
  json=`echo $json | jq ".graphs[0].data.s2[$counter] += { \"x-axis\": $iteration, \"y-axis\": $s2 }"`
  let counter++
done

echo $json | jq . > requests.json

final_graph_object=`echo $json | jq ".graphs[.graphs|length] += $graphs"`

detail_json=`echo $details | jq ". += $final_graph_object.graphs" > details.json
