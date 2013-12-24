#!usr/bin/perl
package Client;

use UltraDNSRestApiClient;
use JSON;  
use CGI;

my $client = new UltraDNSRestApiClient;
$client->set_api_base_url('http://restapi-useast1b01-01.qa.ultradns.net:8080/v1');
$client->authorize('teamrest1', 'Teamrest1');
print 'Version:'.$client->get_version();
print "\n";
print 'Status:'.$client->get_status();
print "\n";
print 'Account Details:'.$client->get_account_details();



  



