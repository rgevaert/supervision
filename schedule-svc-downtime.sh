#!/bin/bash 
echo MIME-Version: 1.0 
echo Content-type: text/html 
echo
QUERY=`echo $QUERY_STRING | sed -e "s/=/='/g" -e "s/&/';/g" -e "s/+/ /g" -e "s/%0d%0a/<BR>/g" -e "s/$/'/" ` 
eval $QUERY
COMMAND_FILE="/var/lib/nagios3/rw/nagios.cmd"
NAGIOS_HOSTS_FILE="/etc/nagios3/conf.puppet.d/puppet_hosts.cfg"
ECHO_COMMAND="/bin/echo"
GREP_COMMAND="/bin/grep"

#We check if host is present in Nagios conf file; if not we exit
$GREP_COMMAND $HOSTNAME $NAGIOS_HOSTS_FILE
if [ $? -ne 0 ]
then
	echo "Host not supervised by Nagios"
	exit 1
fi

#If HOSTNAME is in conf file, we ask for downtime
SERVICEDESC=$(/bin/echo "$SERVICEDESC" | sed -e "s/%20/ /g")
COMMENT=$(/bin/echo "$COMMENT" | sed -e "s/%20/ /g")
START_TIME=`date +%s`
END_TIME=$(/bin/echo "$START_TIME + $DURATION" | /usr/bin/bc)
$ECHO_COMMAND $SERVICEDESC
COMMAND_LINE="[$datetime] SCHEDULE_SVC_DOWNTIME;$HOSTNAME;$SERVICEDESC;$START_TIME;$END_TIME;1;0;$DURATION;$AUTHOR;$COMMENT"
$ECHO_COMMAND $COMMAND_LINE >> $COMMAND_FILE
exit 0
