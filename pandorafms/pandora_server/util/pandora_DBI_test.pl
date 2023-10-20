#!/usr/bin/perl
##################################################################################
# DBI Memory Leak Tester
##################################################################################
# Copyright (c) 2007-2023 Pandora FMS.
##################################################################################

use DBI();     # DB interface with MySQL

#$dbh = DBI->connect("DBI:mysql:pandora:localhost:3306","pandora","pandora",{ RaiseError => 1 });

while (1){
	dbd_open_test();
	#dbd_select_test($dbh);
}

sub dbd_select_test {
	my $dbh = shift;
	my $query = "select * from tagente";
	my $result = $dbh->prepare($query);
	$result ->execute;
	$result = "";
	$query = "";
	$dbh = "";
	undef $dbh;
	undef $query;
	undef $result;
}

sub dbd_open_test {
	$dbh = DBI->connect("DBI:mysql:pandora:localhost:3306","pandora","pandora",{ RaiseError => 1 });
	$dbh->disconnect;
}
