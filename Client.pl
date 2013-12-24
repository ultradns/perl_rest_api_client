#!usr/bin/perl
package Client;

use UltraDNSRestApiClient;
use JSON;  
use CGI;

my $client = new UltraDNSRestApiClient;
$client->set_api_base_url('http://restapi-useast1b01-01.qa.ultradns.net:8080/v1');
$access_token = $client->get_access_token('teamrest1', 'Teamrest1');
$version = $client->get_version();
print $version;


  



