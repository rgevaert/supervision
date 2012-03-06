#!/bin/bash

usage () {
cat << EOF
usage: $0 options

This script allow SIP notification for an host or a service problem

OPTIONS:
	-T	Problem Type: should be either (HOST|SERVICE)
	-H	Host
	-S	If problem type is SERVICE, -S specify what service is conncerned
	-N	Sip number. Should be like sip://01XXXXXXXX@freephonie.net
	-h 	Show this help
EOF
}

while getopts "T:H:S:N:h" OPTION
do
	case $OPTION in
		H)
			HOSTNAME="$OPTARG"
			;;
		T)
			if [ "$OPTARG" == "HOST" -o  "$OPTARG" == "SERVICE" ]
			then
				TYPE="$OPTARG"
			else
				echo "Type $OPTARG not allowed. See help"
				usage
				exit 1
			fi
			;;
		S)	
			if [ "$TYPE" == "SERVICE" ]
			then
				SERVICE="$OPTARG"
			else
				echo "Could not specify service if problem type is not SERVICE"
				usage
				exit 1
			fi
			;;
		N)
			SIP_NUMBER="$OPTARG"
			;;
		h|?)
			usage
			exit 0
			;;
	esac
done

if [ -z "$HOSTNAME" -o -z "$TYPE" -o -z "$SIP_NUMBER" ]
then
	echo "You should define all your variables"
	usage
	exit 1
elif [ "$TYPE" == "SERVICE" -a -z "$SERVICE" ]
then
	echo "If problem type is SERVICE, you should define a service with -S"
	usage
	exit 1
fi

make_env () {
	ESPEAK=/usr/bin/espeak
	LINPHONECSH=/usr/bin/linphonecsh

}

define_message () {
	if [ "$TYPE" == "HOST" ];
	then
		echo "Host problem"
		WAV_MESSAGE="Le serveur $HOSTNAME ne répond plus. Merci d'intervenir au plus vite."
	elif [ "$TYPE" == "SERVICE" ]
	then
		echo "Service Problem"
		WAV_MESSAGE="Le service $SERVICE sur le serveur $HOSTNAME est critique. Merci d'intervenir au plus vite."
	fi
}
	

create_wav_message () {
	FILE=$(mktemp /tmp/tmp.XXXXXXXXX)
	# I repeat the message many times because the file is not started when the call is taken
	$ESPEAK -vfr "$WAV_MESSAGE $WAV_MESSAGE $WAV_MESSAGE $WAV_MESSAGE $WAV_MESSAGE $WAV_MESSAGE" -w $FILE
}

make_call () {
	$LINPHONECSH soundcard "use files"
	$LINPHONECSH generic "play $FILE"
	$LINPHONECSH generic "call $SIP_NUMBER"
}

remove_wav_message() {
	rm -rf $FILE
}

make_env
define_message
create_wav_message
make_call
#remove_wav_message
