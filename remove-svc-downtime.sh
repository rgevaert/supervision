#!/bin/sh 
echo MIME-Version: 1.0 
echo Content-type: text/html 
echo 
QUERY=`echo $QUERY_STRING | sed -e "s/=/='/g" -e "s/&/';/g" -e "s/+/ /g" -e "s/%0d%0a/<BR>/g" -e "s/$/'/" ` 
eval $QUERY
ECHO_COMMAND="/bin/echo"
GREP_COMMAND="/bin/grep"
NAGIOS_HOSTS_FILE="/etc/nagios3/conf.puppet.d/puppet_hosts.cfg"

#We check if host is present in Nagios conf file; if not we exit
$GREP_COMMAND $HOSTNAME $NAGIOS_HOSTS_FILE
if [ $? -ne 0 ]
then
	echo "Host not supervised by Nagios"
	exit 1
fi


#If HOSTNAME is in conf file, we ask for downtime
SERVICEDESC=$(/bin/echo "$SERVICEDESC" | sed -e "s/%20/ /g")
STATUS_FILE="/var/cache/nagios3/status.dat"
COMMAND_FILE="/var/lib/nagios3/rw/nagios.cmd"
START_TIME=`date +%s`

#Retrive Dowtime_ID from status.dat
for i in `seq 1 20`
do
	DOWNTIME_ID=$(grep -A 3 "servicedowntime" $STATUS_FILE | grep -A 2 "$HOSTNAME" |grep -A 1 "$SERVICEDESC" | grep "downtime_id" | cut -f2 -d=)
	if [ "$DOWNTIME_ID" ]; then
		COMMAND_LINE="[$datetime] DEL_SVC_DOWNTIME;$DOWNTIME_ID"
		#Write command to nagios.cm
		$ECHO_COMMAND $COMMAND_LINE >> $COMMAND_FILE
		exit 0
	fi
	sleep 1
done
