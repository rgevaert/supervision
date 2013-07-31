#!/usr/bin/env python

import socket
import cgitb
import cgi
import sys
import inspect
import time
cgitb.enable()


servers = ['nagios1','nagios2','nagios3']
port = 6557

class LiveStatus:
   
   #Create the socket, send message and close socket
   #We do not use KeepAlive feature
   def query(self,server,port,message):
      sock = LSSocket(server,port)
      sock.connect()
      sock.send(message)
      try:
         #rstrip remove \n at the end of the string
         answer = sock.recv(4096).rstrip()
      except socket.timeout:
         answer=''
      sock.close()
      return answer

   #Not really used now
   def get_status(self,server,port):
      message = 'GET status\n\n'
      return self.query(server,port,message)

   def get_host(self,host,server,port):
      message = 'GET hosts\n'
      message += 'Filter: host_name = '+host+'\n'
      message += 'Columns: host_name\n'
      message += '\n'
      # I query the host then remove remaining \n
      return self.query(server,port,message)

   def get_service(self,host,service,server,port):
      message  = 'GET services\n'
      message += 'Columns:  host_name description\n'
      message += 'Filter: host_name = %s\n' % (host)
      message += 'Filter: description = %s\n\n' % (service)
      return self.query(server,port,message)

   def get_servicegroup(self,servicegroup,server,port):
      message  = 'GET servicegroups\n'
      message += 'Columns: name'
      message += 'Filter: name = %s\n\n' % (servicegroup)
      return self.query(server,port,message)

   #The output format is [[id1],[id2]]
   def get_downtimes_ids(self,host,service,server,port):
      message  = 'GET downtimes\n'
      message += 'Filter: host_name = %s\n' % (host)
      message += 'Filter: service_description = %s\n' % (service)
      message += 'Columns: id\n'
      message += 'OutputFormat: json\n\n'
      return self.query(server,port,message)

   #We append 2 \n to specify that the command is finished
   #with no more arguments
   def send_command(self,command,server,port):
      return self.query(server,port,command+'\n\n\n')

	

		
class LSSocket:
        #Only support TCP socket now (unix socket not handled)
	def __init__(self,host,port):
		self.host = host
		self.port = port
		self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                self.socket.settimeout(2)

	def connect(self):
		self.socket.connect((self.host,self.port))

	def close(self):
		self.socket.shutdown(socket.SHUT_WR)
		self.socket.close()

	def send(self,message):
		self.socket.send(message)
	
	def recv(self,length):
		return self.socket.recv(length)


#Exit with error code if form is not valid
#Otherwise return None
def parse_form():
   form = cgi.FieldStorage()
   values['action']=form.getvalue('ACTION')
   values['hostname']=form.getvalue('HOSTNAME')
   values['servicedesc']=form.getvalue('SERVICEDESC')
   values['duration']=form.getvalue('DURATION')
   values['author']=form.getvalue('AUTHOR')
   values['comment']=form.getvalue('COMMENT')
   values['servicegroup']=form.getvalue('SERVICEGROUP')

   if not values['action'] in ['schedule-svc-downtime','remove-svc-downtime','schedule-servicegroup-downtime']:
      exit_with_error_code(400,'Bad Request','You should specify a valid action (schedule-svc-downtime,remove-svc-downtime,schedule-servicegroup-downtime)')
   else:
        check_mandatory_arguments(values['action'])

#Exit with error code if all mandatory arguments are not present
#Return None otherwise
def check_mandatory_arguments(action):
   mandatory_arguments = []
   if action == 'schedule-svc-downtime':
      mandatory_arguments = ['hostname','servicedesc','duration','author','comment']
   elif action == 'remove-svc-downtime':
      mandatory_arguments = ['hostname','servicedesc']
   elif action == 'schedule-servicegroup-downtime':
      mandatory_arguments = ['servicegroup','duration','author','comment']
   else:
      exit_with_error_code(400,'Bad Request','You should specify a valid action (schedule-svc-downtime,remove-svc-downtime,schedule-servicegroup-downtime)')
  
   for key in mandatory_arguments:
       if values[key] == None:
          exit_with_error_code(400,'Bad Request','You should specify a value for '+key)


#Exit with error code if host is not monitored
#Otherwise return None
def find_monitoring_host(host):
    message = ""
    for server in servers:
        lshost = ls.get_host(host,server,port)
        message += "For %s host is %s" % (server,lshost)
        if lshost:
            # we found the monitoring server where the host is monitored
            return server
    # If we reach the end of the servers loop, we didn't find the monitoring host
    exit_with_error_code(404,'Not Found','The specified host could not be found'+message)

#Exit with error code if there is no corresponding service associated with this host
#Otherwise return None
def check_service_for_host(host,service):
   lsservice = ls.get_service(host,service,server,port)
   if not lsservice:
        exit_with_error_code(404,'Not Found','The specified service could not be found for this host')

#Exit with error code if there is no corresponding servicegroup
#Otherwise return None
def check_servicegroup(servicegroup,server):
   lsservicegroup = ls.get_servicegroup(servicegroup,server,port)
   if not lsservicegroup:
      exit_with_error_code(404,'Not Found','The %s servicegroup could not be found on %s' % (servicegroup,server))

#Set status code and exit with error code
def exit_with_error_code(error_code,error_type,error_message):
   print('Status: %d %s' % (error_code,error_type))
   print('')
   print(error_message)
   sys.exit(1)

def format_command(action):
   if action == 'schedule-svc-downtime':
        return format_schedule_svc_downtime()
   elif action == 'remove-svc-downtime':
        return format_remove_svc_downtime()
   elif action == 'schedule-servicegroup-downtime':
        return format_schedule_servicegroup_downtime()
   else:
      exit_with_error_code(400,'Bad Request','You should specify a valid action (schedule-svc-downtime,remove-svc-downtime,schedule-servicegroup-downtime)')

def format_schedule_svc_downtime():
   check_service_for_host(values['hostname'],values['servicedesc'])
   start_time=int(time.time())
   end_time=start_time+int(values['duration'])
   return ["COMMAND [%d] SCHEDULE_SVC_DOWNTIME;%s;%s;%d;%d;1;0;%s;%s;%s" % (start_time,values['hostname'],values['servicedesc'],start_time,end_time,values['duration'],values['author'],values['comment'])]

def format_schedule_servicegroup_downtime():
   # we assume that all servicegroups are defined on all 
   # nagios servers thanks to puppet, so we check only
   # on the first server the presence of the servicegroup
   check_servicegroup(values['servicegroup'],servers[1])
   start_time=int(time.time())
   end_time=start_time+int(values['duration'])
   return ["COMMAND [%d] SCHEDULE_SERVICEGROUP_SVC_DOWNTIME;%s;%d;%d;1;0;%s;%s;%s" % (start_time,values['servicegroup'],start_time,end_time,values['duration'],values['author'],values['comment'])]

def format_remove_svc_downtime():
    check_service_for_host(values['hostname'],values['servicedesc'])
    
    import json
    #ids is an array of array and not just an array (LS return format)
    ids = []
    #we cast the string representing the array into array
    for downtime in json.loads(ls.get_downtimes_ids(values['hostname'],values['servicedesc'],server,port)):
        ids.append(downtime[0])
    if not len(ids) > 0:
        exit_with_error_code(404,'Not Found','There is no downtime associated to this host / service')
    else:
        start_time=int(time.time())
        commands = []
        for id in ids:
            commands.append('COMMAND [%d] DEL_SVC_DOWNTIME;%s' % (start_time,id))
        return commands



values = {}
parse_form()
ls = LiveStatus()

#If the action is on a specific host, we need to find
#wich server is monitoring this host
if values['hostname']:
   server = find_monitoring_host(values['hostname'])
commands = format_command(values['action'])
print("Content-Type: text/html")     # HTML is following
print('')                            # blank line, end of headers
for command in commands:
   ls.send_command(command,server,port)
sys.exit(0)
