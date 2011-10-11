#!/bin/bash


usage()
{
cat << EOF
usage: $0 options

This script run a mtr to a specific host

OPTIONS:
   -H      Host Address to test connectivity
   -N 	   Host name
   -S 	   Host State
   -T 	   Host State Type
   -A      Host Attempts
   -m 	   E-mail adress to send report
   -h 	   Show Help
EOF
}

while getopts “hH:N:S:T:A:m:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
	 H)         
             HOST_ADDRESS=$OPTARG
	     # echo "HOST_ADDRESS = $HOST_ADDRESS" | logger
             ;;
	 N)         
             HOST_NAME=$OPTARG
	     # echo "HOST_NAME = $HOST_NAME" | logger
             ;;
	 S)
             HOST_STATE=$OPTARG
	     ;;
	 T)
             HOST_STATE_TYPE=$OPTARG
	     ;;
	 A)
             HOST_ATTEMPTS=$OPTARG
	     ;;
	 m)
	     MAIL_ADDRESS=$OPTARG
	     # echo "MAIL_ADDRESS = $MAIL_ADDRESS" | logger
	     ;;
         ?)
             usage
             exit
             ;;
     esac
done

# DEBUG echo "mtr -r -n $HOST_ADDRESS | mail -s \"[Nagios report] MTR to $HOST_NAME\" $MAIL_ADDRESS" | logger

if [[ "$HOST_STATE" = DOWN && "$HOST_STATE_TYPE" = SOFT && "$HOST_ATTEMPTS" = 1 ]]
then
	mtr -r -n $HOST_ADDRESS | mail -s "[Nagios report] MTR to $HOST_NAME" $MAIL_ADDRESS
else 
	echo "No match of condition : HOST_STATE = $HOST_STATE ; HOST_STATE_TYPE = $HOST_STATE_TYPE ; HOST_ATTEMPTS = $HOST_ATTEMPTS" | logger
fi
