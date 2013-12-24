#!usr/bin/perl
package UltraDNSRestApiClient;

use LWP::UserAgent;
use JSON;  
use CGI;

my $api_base_url;
my $access_token;
my $ua = new LWP::UserAgent;

sub new {
    my $type = shift;
    bless { }, $type;
}

sub set_api_base_url {
    my $me = shift;
    my $api_base_url = shift;
    $me->{'api_base_url'} = $api_base_url;
}

sub get_access_token {
    my $me = shift;
    my $username = shift;
    my $password = shift;
    my $api_base_url = $me->{'api_base_url'};
    print $api_base_url;
    print $username;
    print $password;

    my $query = new CGI;

    my $token_url     = $api_base_url . "/authorization/token";

    # Request for an access_token
    my $uri = URI->new($token_url);
    my %params = ( 'grant_type'     => 'password',
        'username'   => $username,
        'password'   => $password);
    my $ua = new LWP::UserAgent;
    my $req = new HTTP::Request POST => $uri->as_string;
    $uri->query_form(%params);
    $req->content_type('application/x-www-form-urlencoded');
    $req->content($uri->query);
    my $res = from_json($ua->request($req)->content);
    print $res;
    $me->{'access_token'} = $res->{'access_token'};
}

sub get_version {
    my $me = shift;
    my $api_base_url = $me->{'api_base_url'};
    my $version_url   = $api_base_url . "/version";

    my $access_token = shift;
    my $version_uri = URI->new($version_url);
    my $version_req = new HTTP::Request GET => $version_uri->as_string;

    $ua->default_header('Authorization' => 'Bearer ' . $me->{'access_token'});

    my $content = from_json($ua->request($version_req)->content);
    print "Version:" . $content->{'version'};
    return $version->{'version'};
}

1;
  



