#!/bin/bash

source $1

echo "Services check test: "
echo -e "Logs: \t\t"$LogFile
echo -e "VNF External IP: \t"$EXTERNAL_IP
echo -e "Services to check:\t"$SERVICES
echo -e "User:\t"$USER
echo -e "Password:\t"$PASS


if  [ -z $EXTERNAL_IP ]; then
  echo "Invalid external IP" > $LogFile
  exit 1
else
  opt1="$EXTERNAL_IP"
fi


arr=$(echo $SERVICES | tr " " "\n")


for serv in $arr
do
	ser=$serv
	ip=$EXTERNAL_IP
	echo
	echo $serv

	VAR=$(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no "$USER"@$ip service $serv status )
	echo $VAR
	
	if echo $VAR | grep -q "inactive"; then
		echo "The Service $serv is Inactive" >> $LogFile 
	else
		echo "The Service $serv is Active" >> $LogFile 
	fi

done




