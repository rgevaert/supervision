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

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0;

my $headers = {Content_Type => 'application/json', Accept => 'application/json' };
my $client = REST::Client->new();
my $username;
my $password;
my $host_fqdn;
my $run_number;
my $warning=1;
my $critical=2;
my $failure=0;
my $restart_failure=0;
my $error_counter=0;
my $output;


sub Usage {
my $help = <<EOF;
$0 -H Host_FQDN -F Foreman_URL -w warning -c critical -u username -p password

This script will exit as critical specified host has at least
one failure or restart failure in his last run. 
Options :
        -H FQDN of checked host like webserver.example.com
        -F URL of Foreman like http://foreman.example.com
	-w Number of faillure to be a warning (default is 1)
	-c Number of faillure to be critical (default is 2)
        -u username if authentication required
	-p password if authentication required
EOF
print $help;
}

getopts('H:F:w:c:u:p:');

if (defined $opt_H and $opt_H ne ""){
	$host_fqdn=$opt_H;
}
else{
	&Usage;
	printf "ERROR: You should define your host FQDN\n";
	exit 3;
}

if (defined $opt_F and $opt_F ne ""){
        $foreman_url=$opt_F;
	$client->setHost($foreman_url);
}
else{   
        &Usage;
        printf "ERROR: You should define your Foreman URL like http://foreman.example.com\n";
        exit 3;
}
if (defined $opt_w){
	if($opt_w>0){
		$warning=$opt_w;
	}else {
		&Usage;
		printf "ERROR: warning number should be positive\n";
		exit 3;
	}
}
if ($opt_c){
	if($opt_c>=$warning){
		$critical=$opt_c;
	}else{
		&Usage;
		printf "ERROR: critical number should be greater than warning\n";
		exit 3;
	}
}


#The maximum reports to check is equal to critical limit
$run_number=$critical;

if ($opt_u){
        $username=$opt_u;
}
if ($opt_p){
        $password=$opt_p;
}

#We set authentication header if specified
if($username and $password){
	$headers->{'Authorization'} = 'Basic ' . encode_base64($username . ':' . $password);
}


#We get all the reports
my $response = $client->GET("api/hosts/$host_fqdn/reports",$headers);
my $responseCode=$response->responseCode();
if ($responseCode != 200 ){
	printf "Problem with Foreman Server. ReponseCode is $responseCode. Check your server log. Exiting\n";
	exit 3;
}


#We decode REST response and transform it in an array
my $perl_response = decode_json($response->responseContent());
@tab = @$perl_response;

#We check that we have enough report to inspect
$size_tab = @tab;
if ($size_tab < $critical){
	$output = $output."(only $size_tab reports available) ";
	$run_number=$size_tab;
}

$i=0;
do {
	if ($tab[$i]{'report'}->{'status'}->{'failed'} != 0 or $tab[$i]{'report'}->{'status'}->{'failed_restarts'} !=0) {
		printf "report = $i and failed = $tab[$i]{'report'}->{'status'}->{'failed'} and restart = $tab[$i]{'report'}->{'status'}->{'failed_restarts'}\n";
		$error_counter++;
	}
	$i++;
			
} while (($tab[$i-1]{'report'}->{'status'}->{'failed'} != 0 or $tab[$i-1]{'report'}->{'status'}->{'failed_restarts'} !=0) and $i <= $run_number);


if ($error_counter==0){
	$output=$output." $host_fqdn last puppet run OK\n";
}
else{
	$output=$output."$host_fqdn last $error_counter puppet run failed\n";
}

if ( $error_counter >= $critical)
{
       printf "CRITICAL: $output";
       exit 2
}
elsif ($error_counter >= $warning) {
       printf "WARNING: $output";
       exit 1 
}      
else {
	printf "OK: $output";
	exit 0
}
