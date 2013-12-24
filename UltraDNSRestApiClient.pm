#!usr/bin/perl
package UltraDNSRestApiClient;

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
    my $req = new HTTP::Request $method => $uri->as_string;

    $ua->default_header('Authorization' => 'Bearer ' . $me->{'access_token'});

    my $response = $ua->request($req);

    if ($response->is_success) {
        my $content = $response->content;
        return $content;
    } else {
        $me->process_error($response, $path, $method, $params, $retry);
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
    my $content = $me->make_request("/accounts", "GET" );
    return $content;
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

    # making sure the refresh happens only once
    if($response->code == 401 && $retry < 1) {
        print $response->status_line . "-Refreshing Token \n";
        $me->refresh();
        return $me->make_request($path, $method, $params, 1);
    } else {
        return "Error on:" . $method . ":" . $path . ":" . $response->status_line;
    }
}


1;
  



