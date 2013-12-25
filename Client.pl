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
print "\n";

createTestPrimaryZone("example102.com.","teamrest" );

# Zone Creation
sub createTestPrimaryZone()
{
    my $zone_name = shift;
    my $account_name = shift;
    my  %properties = (
        "name" => $zone_name,
        "accountName" => $account_name,
        "type" => "PRIMARY",
    );

    my  %primaryCreateInfo = (
        "createType" => "NEW",
        "forceImport" => "true",
    );

    my %zone = (
        "properties" => \%properties,
        "primaryCreateInfo" => \%primaryCreateInfo,
    );

    my $json = encode_json \%zone;
    print "Zone Creation:" . $client->create_primary_zone($json);
}



  



