#!/bin/bash
# Variables initialization
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

echo $jsondetail
