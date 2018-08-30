#!/bin/bash

source $1

echo "Traffic generator configuration: "
echo -e "Logs: \t\t"$LogFile
echo -e "Schema: \t"$SCHEMA
echo -e "VNF External IP: \t"$EXTERNAL_IP
echo -e "Service Port: \t"$PORT
echo -e "Path: \t"$URL_PATH
echo -e "Connections: \t"$CONNECTIONS
echo -e "Duration: \t"$DURATION
echo -e "Threads: \t"$THREADS
echo -e "Header: \t"$HEADER
echo -e "Timeout: \t"$TIMEOUT
echo -e "Rate: \t\t"$RATE
echo -e "Proxy: \t\t"$PROXY

if [ -z $SCHEMA ] || [ -z $EXTERNAL_IP ] || [ -z $PORT ]; then
  echo "VNF Under Test endpoint was not set" > $LogFile
  exit 1
else
  opt1="$SCHEMA$EXTERNAL_IP:$PORT"
fi

if [ -z $URL_PATH ]; then
  opt1="$opt1/$URL_PATH"
fi

if [ -z $CONNECTIONS ]; then
  opt2="-connections 200"
else
  opt2="--connections $CONNECTIONS"
fi

if [ -z $DURATION ]; then
  opt3="--duration 300s"
else
  opt3="--duration $DURATION"
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

if [ "$PROXY" = "yes" ]; then
  config="/app/result_proxy.lua"
else
  config="/app/result.lua"
fi


echo "COMMAND: /usr/local/bin/wrk -s $config $opt2 $opt3 $opt4 $opt5 --rate $RATE $opt7 --latency $opt1"
/usr/local/bin/wrk -s $config $opt2 $opt3 $opt4 $opt5 --rate $RATE $opt7 --latency $opt1 > $RATE.tmp
cat $RATE.tmp >>  $LogFile
/bin/cat $RATE.tmp | tail -58 | jq '{ requests, duration_in_microseconds, bytes, requests_per_sec, bytes_transfer_per_sec, latency_distribution }' > rate-$RATE.json
/bin/cat $RATE.tmp | tail -58 | jq '{ graphs }' > graphs-$RATE.json
/bin/cat $RATE.tmp | tail -58 | jq "{ requests_per_sec, \"requests\": $RATE }" > overall-$RATE.json

# Processing data

# Creating details.json file

# Obtain the json generated list
jsondetail=`echo '{"details": [] }' | jq .`
join_json=`cat rate-$RATE.json`
jsondetail=`echo $jsondetail | jq ".details[0] +=  $join_json"`
jsondetail=`echo $jsondetail | jq [.]`
echo $jsondetail | jq . > details.json

# Creating graphs object
graphs=`echo '{"graphs": [] }' | jq .`

# Adding data to graphs object
join_json=`cat graphs-$RATE.json | jq .graphs`
graphs=`echo $graphs | jq ".graphs += $join_json"`

echo $graphs | jq .graphs > graphs.json
graphs=`echo $graphs | jq .graphs`

# Variables initialization
# Graph template
json=`echo '{"graphs": [ { "title": "Http Benchmark test", "x-axis-title": "Iteration", "x-axis-unit": "#", "y-axis-title": "Requests per second", "y-axis-unit": "rps", "type": "line", "series": { "s1": "requests_sent", "s2": "requests_processed" }, "data": { "s1x": [], "s1y": [], "s2x": [], "s2y": [] } }]} '`

# Adding data to graphs object
join_json=`cat overall-$RATE.json`
#echo "join_json $join_json"

s1=`echo $join_json | jq '.requests_per_sec'`
s2=`echo $join_json | jq '.requests'`
json=`echo $json | jq ".graphs[0].data.s1x += [1]"`
json=`echo $json | jq ".graphs[0].data.s1y += [$s1]"`
json=`echo $json | jq ".graphs[0].data.s2x += [1]"`
json=`echo $json | jq ".graphs[0].data.s2y += [$s2]"`

echo $json | jq . > requests.json
#echo $graphs

final_graph_object=`echo $json | jq ".graphs += $graphs"`
the_graphs=`echo $final_graph_object | jq '.graphs'`
#echo "the_graphs" $the_graphs

detail_json=`echo $jsondetail | jq ". += [$final_graph_object]"`
the_json=`echo $jsondetail | jq '.[].details'`
detail_sin=`echo $detail_json | jq "{ details: $the_json, graphs: $the_graphs}"`
echo  $detail_sin | jq . > $DataFile
#echo "detail_sin" $detail_sin
