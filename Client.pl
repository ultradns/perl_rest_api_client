#!usr/bin/perl

use strict;  
use LWP::UserAgent;  
use JSON;  
use CGI;  
  
my $oauth_base    = "http://localhost:8080/v1";
my $version_url   = $oauth_base . "/version";
my $token_url     = $oauth_base . "/authorization/token";
  
my $query = new CGI;  

# Request for an access_token 
my $uri = URI->new($token_url); 
my %params = ( 'grant_type'     => 'password', 
    'username'   => 'teamrest', 
    'password'   => 'Teamrest1'); 
my $ua = new LWP::UserAgent; 
my $req = new HTTP::Request POST => $uri->as_string; 
$uri->query_form(%params); 
$req->content_type('application/x-www-form-urlencoded'); 
$req->content($uri->query); 
my $res = from_json($ua->request($req)->content); 


my $version_uri = URI->new($version_url); 
my $version_req = new HTTP::Request GET => $version_uri->as_string; 
$ua->default_header('Authorization' => 'Bearer ' . $res->{'access_token'});
my $version = $ua->request($version_req)->content;
print "Version:" . $version;
