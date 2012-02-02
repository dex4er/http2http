#!/usr/bin/env perl

# HTTP to HTTP proxy server
#
# Usage:
#   http2http.pl [host:port]


use strict;
use warnings;

use App::http2http;


my $proxy = App::http2http->new;

$proxy->start;
