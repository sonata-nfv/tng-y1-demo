#!/usr/bin/env bash
prname=$1
metric=$2

srvs=()
while read line
do
   #echo "New line: $line"
   srvs+=("$line") 
done < <(echo 'show stat' | socat /var/run/haproxy.sock stdio)

#echo ${#srvs[@]}

if [[ "${srvs[0]}" == "#"* ]];
  then
    MT=${srvs[0]:2}
    set -- "$MT"
    IFS=","; declare -a Array=($*)
    index=-1
    for (( i=0; i <= ${#Array[@]}-1; i++ ))
    do
      if [[ "${Array[$i]}" == $metric ]];
      then
        index=$i
      fi
    done
  fi

if [[ $index -eq -1 ]];
  then
  echo '-255'
  exit 1
fi


for (( i=1; i <= ${#srvs[@]}-1; i++ ))
do
    rec=${srvs[$i]}
    set -- "$rec"
    IFS=","; declare -a Array=($*)
    if [[ "${Array[1]}" == $prname ]];
      then
      val="${Array[$index]}"
      if [ ${#val} -eq 0 ];
      then
        echo 0
      fi
      echo $val
      exit 1
    fi
done

echo '-255'
exit 1