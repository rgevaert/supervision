#!/bin/bash
NAGIOS='/usr/sbin/nagios3'
NAGIOS_CONFIG='/etc/nagios3/nagios.cfg'

$NAGIOS -v $NAGIOS_CONFIG > /dev/null

result=$?


if [ $result -eq 0 ]
then
        echo "Nagios configuration seems OK"
        exit 0
else
        echo "Problem with nagios configuration"
        exit 2
fi
