#!/bin/bash

# Variables initialization
let counter=0

# Obtain the json generated list
requests=`ls *.json | tr "." "\n" | grep -v json | grep -v detail | grep -v request | xargs`

# Graph template
json=`echo '{"graphs": [ { "title": "Http Benchmark test", "x-axis-title": "Iteration", "x-axis-unit": "#", "y-axis-title": "Requests per second", "y-axis-unit": "rps", "type": "line", "series": { "s1": "requests_sent", "s2": "requests_processed" }, "data": { "s1": [], "s2": [] } }]} '`

# Adding data to graphs object
for i in $requests
do
  join_json=`cat $i.json`
  let iteration=$counter+1
  s1=`echo $join_json | jq '.requests_per_sec'`
  s2=`echo $join_json | jq '.request_sent'`
  json=`echo $json | jq ".graphs[0].data.s1[$counter] += { \"x-axis\": $iteration, \"y-axis\": $s1 }"`
  json=`echo $json | jq ".graphs[0].data.s2[$counter] += { \"x-axis\": $iteration, \"y-axis\": $s2 }"`
  let counter++
done

echo $json | jq .
