#!usr/bin/perl
package UltraDNSRestApiClient;

# Copyright 2000-2014 NeuStar, Inc. All rights reserved.
# NeuStar, the Neustar logo and related names and logos are registered
# trademarks, service marks or tradenames of NeuStar, Inc. All other
# product names, company names, marks, logos and symbols may be trademarks
# of their respective owners.

use LWP::UserAgent;
use JSON;  
use CGI;

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

sub set_refresh_token {
    my $me = shift;
    my $refresh_token = shift;
    $me->{'refresh_token'} = $refresh_token;
}

sub get_refresh_token {
    my $me = shift;
    return $me->{'refresh_token'};
}

# authorize using username and password
sub authorize {
    my $me = shift;
    my $username = shift;
    my $password = shift;
    my $api_base_url = $me->{'api_base_url'};

    my $query = new CGI;

    my $token_url     = $api_base_url . "/authorization/token";

    # Request for an access_token
    my $uri = URI->new($token_url);
    my %params = ( 'grant_type'     => 'password',
        'username'   => $username,
        'password'   => $password);
    my $req = new HTTP::Request POST => $uri->as_string;
    $uri->query_form(%params);
    $req->content_type('application/x-www-form-urlencoded');
    $req->content($uri->query);

    my $response = $ua->request($req);

    if ($response->is_success) {
        my $content = from_json($response->content);

        # set the access & refresh token as a member of this instance
        $me->{'access_token'} = $content->{'accessToken'};
        $me->{'refresh_token'} = $content->{'refreshToken'};
        return "Refresh Token:" . $me->{'refresh_token'};
    } else {
        my $content = $response->content;
        return "Authorization Failed:" . $content;
    }
}

# Gets a new set of tokens
sub refresh {
    my $me = shift;
    my $api_base_url = $me->{'api_base_url'};

    my $query = new CGI;

    my $token_url = $api_base_url . "/authorization/token";

    # Request for an access_token
    my $uri = URI->new($token_url);
    my %params = ( 'grant_type'     => 'refresh_token',
        'refresh_token'   => $me->{'refresh_token'});
    my $req = new HTTP::Request POST => $uri->as_string;
    $uri->query_form(%params);
    $req->content_type('application/x-www-form-urlencoded');
    $req->content($uri->query);
    my $response = $ua->request($req);

    if ($response->is_success) {
        my $content = from_json($response->content);

        # set the access & refresh token as a member of this instance
        $me->{'refresh_token'} = $content->{'refreshToken'};
        $me->{'access_token'} = $content->{'accessToken'};
        return "Refresh Token:" . $me->{'refresh_token'};
    } else {
        my $content = $response->content;
        return "Authorization Failed:" . $content;
    }
}

# common method to make a request
# returns content of response in case of success
# In case of error, retries after using refresh token to get new set of tokens
sub make_request {
    my $me = shift;
    my $path = shift;
    my $method = shift;
    my $params = shift;
    my $retry = shift;

    my $api_base_url = $me->{'api_base_url'};
    my $url   = $api_base_url . $path;
    my $uri = URI->new($url);

    #prepare the request
    my $req = new HTTP::Request $method => $uri->as_string;
    $req->header('Content-Type' => 'application/json');


        $req->content($params);

    #prepare header for auth
    $ua->default_header('Authorization' => 'Bearer ' . $me->{'access_token'});

    print "REQUEST URI: " . $uri;
    print "\n";

    print "REQUEST Params: " . $params;
    print "\n";

print "REQUEST Method: " . $method;
    print "\n";

    my $response = $ua->request($req);

    if ($response->is_success) {
        my $content = $response->content;
        return $content;
    } else {
        return $me->process_error($response, $path, $method, $params, $retry);
    }
}

# a sub routine to process error conditions.
# if there is a 401 then a retry is attempted after a refresh on the tokens
sub process_error {
    my $me = shift;
    my $response = shift;
    my $path = shift;
    my $method = shift;
    my $params = shift;
    my $retry = shift;

    my $response_json = from_json($response->content);

    # making sure the refresh happens only once
    if(($response->code == 401 || $response->code == 400) && index($response->{'errorMessage'}, "invalid_grant") != -1
        && $retry < 1) {
        print $response->status_line . "-Refreshing Token \n";
        $me->refresh();
        return $me->make_request($path, $method, $params, 1);
    } else {
        return "ERROR on:" . $method . ":" . $path . ":" . $response->status_line . ":" . $response->content ;
    }
}

# subroutine to get version of REST Api.
# In case of success, return value is version string
# In case of error, return value is an error string containing details about the error
sub get_version {
    my $me = shift;
    my $api_base_url = $me->{'api_base_url'};
    my $version_url   = $api_base_url . "/version";

    my $access_token = shift;
    my $version_uri = URI->new($version_url);
    my $req = new HTTP::Request GET => $version_uri->as_string;

    my $response = $ua->request($req);

    if ($response->is_success) {
        my $content = from_json($response->content);
        return $content->{'version'};
    } else {
        return "Error getting Version:" . $response->status_line;
    }

}

# Gets status of API server.
sub get_status {
    my $me = shift;
    my $content = from_json($me->make_request("/status", "GET" ));
    return $content->{'message'};
}

# Gets account details of the authorized user. Return value in case of success is a JSON string with the details
sub get_account_details {
    my $me = shift;
    return $me->make_request("/accounts", "GET" );
}

# creates a primary zone
# The zone to be create should be passed as a parameter as a JSON string
# Refer documentation for JSON format expected
sub create_primary_zone {
    my $me = shift;
    my $zone_json = shift;
    return $me->make_request("/zones", "POST", $zone_json);
}

# Gets zone meta data for the zone name
sub get_zone_metadata {
    my $me = shift;
    my $zone_name = shift;
    return $me->make_request("/zones/" . $zone_name, "GET" );
}

# get zones of account
sub get_zones_of_account {
    my $me = shift;
    my $account_name = shift;
    my $offset = shift;
    my $limit = shift;
    my $sort = shift;
    my $reverse = shift;

    my $uri_string = '/accounts/' . $account_name . '/zones?' . 'offset='.$offset.'&limit='.$limit.'&sort='.$sort.'&reverse='.$reverse;

    return $me->make_request($uri_string, "GET");
}

sub delete_zone {
    my $me = shift;
    my $zone = shift;
    return $me->make_request("/zones/" . $zone, "DELETE", %query_params);
}


sub get_rrsets {
    my $me = shift;
    my $zone_name = shift;
    my $offset = shift;
    my $limit = shift;
    my $sort = shift;
    my $reverse = shift;

    my $uri_string = '/zones/' . $zone_name . '/rrsets?' . 'offset='.$offset.'&limit='.$limit.'&sort='.$sort.'&reverse='.$reverse;

    return $me->make_request($uri_string, "GET");
}

sub get_rrsets_by_type {
    my $me = shift;
    my $zone_name = shift;
    my $type = shift;
    my $offset = shift;
    my $limit = shift;
    my $sort = shift;
    my $reverse = shift;

    my $uri_string = '/zones/' . $zone_name . '/rrsets/'. $type . '?offset='.$offset.'&limit='.$limit.'&sort='.$sort.'&reverse='.$reverse;
    return $me->make_request($uri_string, "GET");
}

sub create_rrset {
    my $me = shift;
    my $zone_name = shift;
    my $owner_name = shift;
    my $record_type = shift;
    my $rrset_json = shift;

    return $me->make_request("/zones/" . $zone_name . "/rrsets/" . $record_type . "/" . $owner_name, "POST", $rrset_json);
}

sub update_rrset {
    my $me = shift;
    my $zone_name = shift;
    my $owner_name = shift;
    my $record_type = shift;
    my $title = shift;
    my $rrset_json = shift;

    return $me->make_request("/zones/" . $zone_name . "/rrsets/" . $record_type . "/" . $owner_name, "PUT", $rrset_json);
}

sub delete_rrset {
    my $me = shift;
    my $zone_name = shift;
    my $record_type = shift;
    my $owner_name = shift;

    return $me->make_request("/zones/" . $zone_name . "/rrsets/" . $record_type . "/" . $owner_name, "DELETE");
}


# need to have this or else you will get compile errors
1;
  



