#!/usr/bin/perl

#README :
#
#This script use REST::Client which is not packaged in Debian at this time (03/21/2012)
#To install it, use cpan :
#install REST::Client
#

use warnings;
use utf8;
use JSON;
use MIME::Base64;
use Data::Dumper;
use REST::Client;
use Getopt::Std;

my $headers = {Content_Type => 'application/json', Accept => 'application/json' };
my $client = REST::Client->new();
my $username;
my $password;
my $host_fqdn;

sub Usage {
my $help = <<EOF;
$0 -H Host_FQDN -F Foreman_URL -u username -p password

This script will exit as critical specified host has at least
one failure or restart failure in his last run. 
Options :
        -H FQDN of checked host like webserver.example.com
        -F URL of Foreman like http://foreman.example.com
        -u username if authentication required
	-p password if authentication required
EOF
print $help;
}

getopt('HFup');

if ($opt_H ne ""){
	$host_fqdn=$opt_H;
}
else{
	&Usage;
	printf "ERROR: You should define your host FQDN\n";
	exit 3;
}

if ($opt_F ne ""){
        $foreman_url=$opt_F;
	$client->setHost($foreman_url);
}
else{   
        &Usage;
        printf "ERROR: You should define your Foreman URL like http://foreman.example.com\n";
        exit 3;
}
if ($opt_u){
        $username=$opt_u;
}
if ($opt_p){
        $password=$opt_p;
}


 
if($username and $password){
	$headers->{'Authorization'} = 'Basic ' . encode_base64($username . ':' . $password);
}


my $response = $client->GET("/hosts/$host_fqdn/reports/last",$headers);
my $responseCode=$response->responseCode();

if ($responseCode != 200 ){
	printf "Problem with Foreman Server. ReponseCode is $responseCode. Check your server log. Exiting\n";
	exit 3;
}


my $perl_response = decode_json($response->responseContent());
my %hastab = %$perl_response; 

my $failure= $hastab{'report'}->{'status'}->{'failed'};
my $restart_failure=$hastab{'report'}->{'status'}->{'failed_restarts'};

my $output="$host_fqdn FAILURE : $failure and RESTART_FAILURE : $restart_failure\n";

if ( $failure !=0 or $restart_failure != 0)
{
	printf "EROOR : $output";
	exit 2
}
else {
	printf "OK: $output";
	exit 0	

}	
