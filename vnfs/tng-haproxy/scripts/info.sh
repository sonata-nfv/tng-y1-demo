#!/usr/bin/env bash
metric=$1


while read line
do
  if [[ $line == $metric* ]] ;
    then
      echo $line | cut -d ":" -f 2
    fi
  #echo "New line $line"
done < <(echo 'show info' | socat /var/run/haproxy.sock stdio)