#!usr/bin/perl
package Client;

# Usage
#  perl Client.pl --apiurl http://<host:port>/v1 --username <username> --password <password>
# OR
#  perl Client.pl --apiurl http://<host:port>/v1 --refreshtoken <refresh token>

use UltraDNSRestApiClient;
use JSON;  
use CGI;
use Getopt::Long;

my $api_url;
my $refresh_token;
my $username;
my $password;

GetOptions ('apiurl=s' => \$api_url,'refreshtoken=s' => \$refresh_token,
    'username=s' => \$username, 'password=s' => \$password);
if(not defined $api_url) {
    print "apiurl is required";
    exit;
}

my $client = new UltraDNSRestApiClient;
$client->set_api_base_url($api_url);

print 'Version:'.$client->get_version();
print "\n";

perform_auth();

print "\n";
print 'Status:'.$client->get_status();
print "\n";

print "\n";
print 'Account Details:'.$client->get_account_details();
print "\n";

print "\n";
print "Zone Creation:" . $client->create_primary_zone(createTestPrimaryZone("example1001.com.","teamrest1" ));
print "Zone Creation:" . $client->create_primary_zone(createTestPrimaryZone("example1002.com.","teamrest1" ));
print "\n";

print "\n";
print 'Zone Meta Data:'.$client->get_zone_metadata("example1001.com.");
print "\n";

print "\n";
print 'Zones of Account:' . $client->get_zones_of_account("teamrest1");
print "\n";

print "\n";
print 'Create RD Pool:' . $client->create_rrset("example1001.com.","teamrest1", "A", createTestRDPool());
print "\n";

print "\n";
print 'Update RD Pool:' . $client->update_rrset("example1001.com.","teamrest1", "A", "default", createTestRDPoolForUpdate());
print "\n";


print "\n";
print 'Create RR Set:' . $client->create_rrset("example1002.com.","teamrest1", "A", createTestRRSet());
print "\n";

print "\n";
print 'Update RR Set:' . $client->update_rrset("example1002.com.","teamrest1", "A", "default", createTestRRSetForUpdate());
print "\n";


print "\n";
print 'RR Sets of Zone:' . $client->get_rrsets("example1001.com.");
print "\n";

print "\n";
print 'RR Sets of Zone by Type:' . $client->get_rrsets_by_type("example1001.com.", "2");
print "\n";

print "\n";
print 'Delete RR Set:' . $client->delete_rrset("example1001.com.","A", "teamrest1");
print "\n";

print "\n";
print 'Deleting Zone:' . $client->delete_zone("example1001.com.");
print 'Deleting Zone:' . $client->delete_zone("example1002.com.");
print "\n";


sub perform_auth {
    if(not defined $refresh_token) {
        if((not defined $username) || (not defined $password)) {
            print 'please provide username and password OR refresh token';
            exit;
        } else {
            my $response = $client->authorize($username, $password);
            eval_auth_response($response);
        }
    } else {
        $client->set_refresh_token($refresh_token);
        my $response = $client->refresh();
        eval_auth_response($response);
    }
}

sub eval_auth_response {
    my $response = shift;
    if(index($response, "Refresh Token") != -1) {
        print $response;
    } else {
        print $response;
        exit;
    }
}

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

sub createTestRDPool() {

    my @rdata = ("1.2.3.4", "2.4.6.8", "9.8.7.6");
    my %profile = (
        "\@context" => "http:\/\/schemas.ultradns.com\/RDPool.jsonschema",
        "order" => "RANDOM",
        "description" => "This is a great RD Pool",
    );

    my  %rrset = (
        "ttl"=> 300,
        "rdata" => \@rdata,
        "profile" => \%profile,
    );

    return encode_json \%rrset;
}

sub createTestRDPoolForUpdate() {
    my @rdata = ("1.9.3.4", "2.5.6.8", "9.8.7.5");

    my %profile = (
            "\@context" => "http:\/\/schemas.ultradns.com\/RDPool.jsonschema",
            "order" => "RANDOM",
            "description" => "This is a great RD Pool",
        );

    my  %rrset = (
        "ttl"=> 200,
        "rdata" => \@rdata,
        "profile" => \%profile,
    );

    return encode_json \%rrset;
}


sub createTestRRSet() {

    my @rdata = ("1.2.3.4");

    my  %rrset = (
        "ttl"=> 300,
        "rdata" => \@rdata,
    );

    return encode_json \%rrset;
}

sub createTestRRSetForUpdate() {
    my @rdata = ("1.9.3.4");

    my  %rrset = (
        "ttl"=> 200,
        "rdata" => \@rdata,
    );

    return encode_json \%rrset;
}



  



