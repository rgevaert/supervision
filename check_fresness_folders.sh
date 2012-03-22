#!/bin/bash
i=1
RES=0

usage () {
cat << EOF
usage: $0 options

This script allow to check multiple folder to look for files older thant a defined age

OPTIONS:
	-t 	Time in minutes. If files older than that time are found, this script return CRITICAL
	-F	List of folders that should be separated with coma 
EOF
}

while getopts "t:F:" OPTION
do
	case $OPTION in
		t) 
			OLD_FILES_DELAY_IN_MIN="$OPTARG"
			;;
		F)
			FOLDERS="$OPTARG"
			;;
		h)
			usage
			exit 0
			;;
		?)
			usage
			exit 3
			;;
	esac
done

if [ -z "$OLD_FILES_DELAY_IN_MIN" -o -z "$FOLDERS" ]
then
	usage
	echo "ERROR: You should define all your variables"
	exit 3
fi

directory=$(echo $FOLDERS | awk -F "," "{print \$$i}")
while [ "$directory" != "" ]
do
	RES=$(($RES + $(find $directory -mtime +$OLD_FILES_DELAY_IN_MIN -type f 2>/dev/null| wc -l)))
	i=$(($i+1))
	directory=$(echo $FOLDERS | awk -F "," "{print \$$i}")
done

if [ $RES -ne 0 ]
then
	echo "ERROR : $RES files older than $OLD_FILES_DELAY_IN_MIN minutes found in $FOLDERS"
	exit 2;
else
	echo "OK : No file found in $FOLDERS"
	exit 0;
fi

