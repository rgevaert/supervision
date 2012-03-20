#!/usr/bin/perl

use strict;
use Getopt::Std;

$ENV{PATH} = "/sbin:/bin:/usr/sbin:/usr/bin";
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
our($opt_i,$opt_f,$opt_o,$expected_input,$expected_forward,$expected_output);

my $IPTABLES="/sbin/iptables";
my %policies=();
my $return_code=0;
my $output="";
my $count=0;

getopt('ifo');

# On passe root ...
 $< = $>;
 $( = $);

&GetCurrentPolicies;
&CheckPoliciesCompliance;
&PrintAndExit;

sub Usage {
my $help = <<EOF;
$0 -i input_policy -o output_policy -f forward_policy

This script will exit as critical if one of defined policy is not set as expected.
Options :
	-i (ACCEPT|DROP|QUEUE|RETURN)
	-o (ACCEPT|DROP|QUEUE|RETURN)
	-f (ACCEPT|DROP|QUEUE|RETURN)
EOF
print $help;
}

sub CheckPoliciesCompliance {
	if ( $opt_i ne "") {
		$count++;
		$output .= "INPUT = $policies{'INPUT'}, ";
		if ($opt_i ne $policies{'INPUT'} ) {
			$return_code=2;
		}
	}
	if ( $opt_f ne ""){
		$count++;
		$output .= "FORWARD = $policies{'FORWARD'}, ";
		if ($opt_f ne $policies{'FORWARD'}) {
			$return_code=2;
		}
	}
	if ( $opt_o ne ""){
		$count++;
		$output .= "OUTPUT = $policies{'OUTPUT'}";
		if ($opt_o ne $policies{'OUTPUT'} ) {
			$return_code=2;
		}
	}

	if ($count == 0){
		&Usage;
		printf "ERROR : You should define at least one policy\n";
		exit 1;
	}
}


sub GetCurrentPolicies {
 open(R,"$IPTABLES -L -v -n |");
 while (<R>) {
	 my $line = $_;
	 	if ($line =~  /Chain ([A-Z]+) \(policy ([A-Z]+) /)
		{
			$policies{"$1"}="$2";

		}
 }
}

sub PrintAndExit {
 if ($return_code == 0){
	$output="OK : $output";
 }
 else{
 	  $output="ERROR : $output";
 }
 printf "$output \n";
 exit $return_code
}
