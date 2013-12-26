#!usr/bin/perl
package Client;

use UltraDNSRestApiClient;
use JSON;  
use CGI;

my $client = new UltraDNSRestApiClient;
$client->set_api_base_url('http://localhost:8080/v1');

print 'Version:'.$client->get_version();
print "\n";

$client->authorize('teamrest1', 'Teamrest1');
print "\n";
print 'Status:'.$client->get_status();
print "\n";

print "\n";
print 'Account Details:'.$client->get_account_details();
print "\n";

print "\n";
print "Zone Creation:" . $client->create_primary_zone(createTestPrimaryZone("example104.com.","teamrest" ));
print "\n";

print "\n";
print 'Zone Meta Data:'.$client->get_zone_metadata("example104.com.");
print "\n";

print "\n";
print 'Zones of Account:' . $client->get_zones_of_account("teamrest");
print "\n";

print "\n";
print 'Create RR Set:' . $client->create_rrset(createTestRRSet("example104.com.","teamrest1", "A", 300 ));
print "\n";

print "\n";
print 'Update RR Set:' . $client->create_rrset(createTestRRSetForUpdate("example104.com.","teamrest1", "A", 300 ));
print "\n";


print "\n";
print 'RR Sets of Zone:' . $client->get_rrsets("example104.com.");
print "\n";

print "\n";
print 'RR Sets of Zone by Type:' . $client->get_rrsets_by_type("example104.com.", "A");
print "\n";

print "\n";
print 'Delete RR Set:' . $client->delete_rrset("example104.com.","A", "teamrest1");
print "\n";

print "\n";
print 'Deleting Zone:' . $client->delete_zone("example104.com.");
print "\n";



# Creates a Zone Json string
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

    return encode_json \%zone;
}

sub createTestRRSet() {
    my $zone_name = shift;
    my $owner_name = shift;
    my $record_type = shift;
    my $ttl = shift;

    my @rdata = ("1.2.3.4", "2.4.6.8", "9.8.7.6");

    my  %rrset = (
        "zoneName" => $zone_name,
        "ownerName"=> $owner_name,
        "title"=> "default",
        "version"=> 1,
        "rrtype"=> $record_type,
        "ttl"=> 300,
        "rdata" => \@rdata,
    );

    return encode_json \%rrset;
}

sub createTestRRSetForUpdate() {
    my $zone_name = shift;
    my $owner_name = shift;
    my $record_type = shift;
    my $ttl = shift;

    my @rdata = ("1.9.3.4", "2.5.6.8", "9.8.7.5");

    my  %rrset = (
        "zoneName" => $zone_name,
        "ownerName"=> $owner_name,
        "title"=> "default",
        "version"=> 1,
        "rrtype"=> $record_type,
        "ttl"=>200,
        "rdata" => \@rdata,
    );

    return encode_json \%rrset;
}



  



