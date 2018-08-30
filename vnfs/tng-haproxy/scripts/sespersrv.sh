#!/usr/bin/env bash

sessions=$(./stat.sh BACKEND scur)
servers=$(./stat.sh BACKEND act)

if [[ $servers == 0  ]];
  then
      	echo '-255'
        exit 1
  fi

ses_ratio=$(( sessions / servers ))

echo $ses_ratio
