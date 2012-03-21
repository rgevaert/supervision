#!/usr/bin/perl

#use LWP::Simple;
#use LWP::UserAgent;
#use LWP::Protocol::https;
#
#$user_agent=LWP::UserAgent->new(
#	ssl_opts => {
#		veriry_hostname => 0,
#	},
#);
#$user_agent->credentials("$foreman_url:80",$realm,$user,$password);
#$user_agent->default_header('Content-Type' => 'application/json');
#$user_agent->default_header('Accept' => 'application/json');
#$user_agent->default_header('Authozation' => 'Basic'.encode_base64($username . ':' . $password));
#my $response = $user_agent->get("http://$foreman_url/hosts/puppet.yzserv.com/reports/last");

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
