#!/usr/bin/perl
# (c) Dario Rodriguez 2011 <dario.rodriguez@artica.es>
# Intel DCM Discovery

use POSIX qw(setsid strftime strftime ceil);

use strict;
use warnings;

use IO::Socket::INET;
use NetAddr::IP;

# Default lib dir for RPM and DEB packages

BEGIN { push @INC, '/usr/lib/perl5'; }

use PandoraFMS::Tools;
use PandoraFMS::DB;
use PandoraFMS::Core;
use PandoraFMS::Config;
##########################################################################
# Global variables so set behaviour here:

my $pkg_count = 2; #Number of ping pkgs
my $pkg_timeout = 1; #Pkg ping timeout wait

##########################################################################
# Code begins here, do not touch
##########################################################################
my $OSNAME = $^O;
my $pandora_conf;

if ($OSNAME eq "freebsd") {
	$pandora_conf = "/usr/local/etc/pandora/pandora_server.conf";
} else {
	$pandora_conf = "/etc/pandora/pandora_server.conf";
}

my $task_id = $ARGV[0]; # Passed automatically by the server
my $target_group = $ARGV[1]; # Defined by user

# Used Custom Fields in this script
my $target_network = $ARGV[2]; # Filed1 defined by user
my $username = $ARGV[3]; # Field2 defined by user
my $password = $ARGV[4]; # Field3 defined by user
my $extraopts = $ARGV[5]; # Field4 defined by user

# Map Sensor type to module type and thresholds
# 0 = numeric, record has thresholds
# 1 = simple flag, 0 normal, > 0 critical
# 2 = complex flags, for now ignore alert settings
# 3 = string or unknown
my %sensor_types = (
	'Temperature' => 0,
	'Voltage' => 0,
	'Current' => 0,
	'Fan' => 0,
	'Physical Security' => 1,
	'Platform Security Violation Attempt' => 1,
	'Processor' => 2,
	'Power Supply' => 2,
	'Power Unit' => 2,
	'Cooling Device' => 0,
	'Other Units Based Sensor' => 0,
	'Memory' => 2,
	'Drive Slot' => 3,
	'POST Memory Resize' => 3,
	'System Firmware Progress' => 1,
	'Event Logging Disabled' => 2,
	'Watchdog 1' => 2,
	'System Event' => 2,
	'Critical Interrupt' => 1,
	'Button Switch' => 2,
	'Module Board' => 3,
	'Microcontroller Coprocessor' => 3,
	'Add In Card' => 3,
	'Chassis' => 3,
	'Chip Set' => 3,
	'Other Fru' => 3,
	'Cable Interconnect' => 3,
	'Terminator' => 3,
	'System Boot Initiated' => 2,
	'Boot Error' => 1,
	'OS Boot' => 2,
	'OS Critical Stop' => 1,
	'Slot Connector' => 2,
	'System ACPI Power State' => 2,
	'Watchdog 2' => 2,
	'Platform Alert' => 2,
	'Entity Presence' => 2,
	'Monitor ASIC IC' => 3,
	'LAN' => 2,
	'Management Subsystem Health' => 1,
	'Battery' => 2,
	'Session Audit' => 3,
	'Version Change' => 3,
	'FRU State' => 3,
	'OEM Reserved' => 3
);

##########################################################################
# Update recon task status.
##########################################################################
sub update_recon_task ($$$) {
	my ($dbh, $id_task, $status) = @_;

	db_do ($dbh, 'UPDATE trecon_task SET utimestamp = ?, status = ? WHERE id_rt = ?', time (), $status, $id_task);
}

##########################################################################
# Show help
##########################################################################
sub show_help {
	print "\nSpecific Pandora FMS Intel DCM Discovery\n";
	print "(c) Pandora FMS 2011-2023 <info\@pandorafms.com>\n\n";
	print "Usage:\n\n";
	print "   $0 <task_id> <group_id> <custom_field1> <custom_field2> <custom_field3> <custom_field4>\n\n";
	print " * custom_field1 = network. i.e.: 192.168.100.0/24\n";
	print " * custom_field2 = username \n";
	print " * custom_field3 = password \n";
	print " * custom_field4 = additional ipmi-sensors options \n";
	exit;
}

##########################################################################
# Get SNMP response.
##########################################################################
sub ipmi_ping ($$$) {
	my $addr = shift;
	my $pkg_count = shift;
	my $pkg_timeout = shift;
	
	my $cmd = "ipmiping $addr -c $pkg_count -t $pkg_timeout";
	
	my $res = `$cmd`;	

	if ($res =~ / (\d+\.\d+)% packet loss/) {
		if ($1 ne '100.0') {
			return 1;
		}
	}

	return 0;
}

sub create_ipmi_modules($$$$$$$) {
	my ($conf, $dbh, $addr, $user, $pass, $extraopts, $id_agent) = @_;

	my $cmd = "ipmi-sensors -h $addr -u $user -p $pass $extraopts --ignore-not-available-sensors --no-header-output --comma-separated-output --non-abbreviated-units --output-sensor-thresholds --output-event-bitmask";

	my $res = `$cmd`;

	my @lines = split(/\n/, $res);
	
	my $ipmi_plugin_id = get_db_value($dbh, "SELECT id FROM tplugin WHERE name = '".safe_input("IPMI Plugin")."'");
	
	for (my $i=0; $i <= $#lines; $i++) {
		
		my $line = $lines[$i];
		
		my ($sensor, $name, $type, $value, $units, $lowerNR, $lowerC, $lowerNC, $upperNC, $upperC, $upperNR, $eventmask) = split(/,/, $line);
		
		my $module_name = $type.': '.$name;

		my $module_type;
		my $module_warn_min;
		my $module_warn_max;
		my $module_warn_invert;
		my $module_critical_min;
		my $module_critical_max;
		my $module_critical_invert;

		if ($sensor_types{$type} == 0) {
			$module_type = "generic_data";	
			if ($lowerC ne 'N/A' and $upperC ne 'N/A') {
				$module_critical_min = $lowerC;
				$module_critical_max = $upperC;
				$module_critical_invert = 1;
			}
			if ($lowerNC ne 'N/A' and $upperNC ne 'N/A') {
				$module_warn_min = $lowerNC;
				$module_warn_max = $upperNC;
				$module_warn_invert = 1;
			}
		} elsif  ($sensor_types{$type} == 1) {
			$module_type = "generic_data";
			$module_critical_min = "1";
			$module_critical_max = "0";
		} elsif  ($sensor_types{$type} == 2) {
			$module_type = "generic_data";
		} elsif  ($sensor_types{$type} == 3) {
			$module_type = "generic_data_string";
		} else {
			$module_type = "generic_data_string";
		}
		
		my $id_module_type = get_module_id($dbh, $module_type);

		my $macros = '{'.
			'"1":{"macro":"_field1_","desc":"'.safe_input("Target IP").'","help":"","value":"'.$addr.'","hide":""},'.
			'"2":{"macro":"_field2_","desc":"Username","help":"","value":"'.$user.'","hide":""},'.
			'"3":{"macro":"_field3_","desc":"Password","help":"","value":"'.$pass.'","hide":"1"},'.
			'"4":{"macro":"_field4_","desc":"Sensor","help":"","value":"'.$sensor.'","hide":""},'.
			'"5":{"macro":"_field5_","desc":"'.safe_input("Additional Options").'","help":"","value":"'.$extraopts.'","hide":""}'.
			'}';

		my %parameters;

		$parameters{"nombre"} = safe_input($module_name);
		$parameters{"id_tipo_modulo"} = $id_module_type;		
		$parameters{"id_agente"} = $id_agent;
		$parameters{"id_plugin"} = $ipmi_plugin_id;
		$parameters{"id_modulo"} = 4;
		$parameters{"unit"} = $units if $units ne 'N/A';
		$parameters{"min_warning"} = $module_warn_min if defined $module_warn_min;
		$parameters{"max_warning"} = $module_warn_max if defined $module_warn_max;
		$parameters{"warning_inverse"} = $module_warn_invert if defined $module_warn_invert;
		$parameters{"min_critical"} = $module_critical_min if defined $module_critical_min;
		$parameters{"max_critical"} = $module_critical_max if defined $module_critical_max;
		$parameters{"critical_inverse"} = $module_critical_invert if defined $module_critical_invert;
		$parameters{"macros"} = $macros;

		pandora_create_module_from_hash ($conf, \%parameters, $dbh);	
		
	} 
}

##########################################################################
##########################################################################
# M A I N   C O D E
##########################################################################
##########################################################################


if ($#ARGV == -1){
	show_help();
}

# Pandora server configuration
my %conf;
$conf{"quiet"} = 0;
$conf{"verbosity"} = 1;	# Verbose 1 by default
$conf{"daemon"}=0;	# Daemon 0 by default
$conf{'PID'}="";	# PID file not exist by default
$conf{'pandora_path'} = $pandora_conf;

# Read config file
pandora_load_config (\%conf);

# Connect to the DB
my $dbh = db_connect ($conf{'dbengine'}, $conf{'dbname'}, $conf{'dbhost'}, '3306', $conf{'dbuser'}, $conf{'dbpass'});


# Start the network sweep
# Get a NetAddr::IP object for the target network
my $net_addr = new NetAddr::IP ($target_network);
if (! defined ($net_addr)) {
	logger (\%conf, "Invalid network " . $target_network . " for Intel DCM Discovery task", 1);
	update_recon_task ($dbh, $task_id, -1);
	return -1;
}

# Scan the network for host
my ($total_hosts, $hosts_found, $addr_found) = ($net_addr->num, 0, '');

for (my $i = 1; $i<= $total_hosts && $net_addr <= $net_addr->broadcast; $i++, $net_addr++) {
	if ($net_addr =~ /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.(\d{1,3})\b/) {
		if($1 eq '0' || $1 eq '255') {
			next;
		}
	}
	
	my $addr = (split(/\//, $net_addr))[0];
	$hosts_found ++;
	
	# Update the recon task 
	update_recon_task ($dbh, $task_id, ceil ($i / ($total_hosts / 100)));
       
	my $alive = 0;
	if (ipmi_ping ($addr, $pkg_count, $pkg_timeout) == 1) {
		$alive = 1;
	}
	
	next unless ($alive > 0);

	# Resolve the address
	my $host_name = gethostbyaddr(inet_aton($addr), AF_INET);
	$host_name = $addr unless defined ($host_name);
	
	logger(\%conf, "Intel DCM Device found host $host_name.", 10);

	# Check if the agent exists
	my $agent_id = get_agent_id($dbh, $host_name);
	
	# If the agent doesnt exist we create it
	if($agent_id == -1) {
		# Create a new agent
		$agent_id = pandora_create_agent (\%conf, $conf{'servername'}, $host_name, $addr, $target_group, 0, 11, '', 300, $dbh);

		create_ipmi_modules(\%conf, $dbh, $addr, $username, $password, $extraopts, $agent_id);
	}

	# Generate an event
	pandora_event (\%conf, "[RECON] New Intel DCM host [$host_name] detected on network [" . $target_network . ']', $target_group, $agent_id, 2, 0, 0, 'recon_host_detected', 0, $dbh);
}	
	
# Mark recon task as done
update_recon_task ($dbh, $task_id, -1);

# End of code
