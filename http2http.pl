#!/usr/bin/env perl

# HTTP to HTTP proxy server
#
# Usage:
#   http2http.pl [host:port]


use strict;
use warnings;

use App::http2http;


my $proxy = App::http2http->new(
    host => '127.0.0.1',
    port => 8080,
    via => undef,
    x_forwarded_for => undef,
);

$proxy->start;
