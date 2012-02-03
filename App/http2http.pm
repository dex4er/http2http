#!/usr/bin/env perl -c

package App::http2http;

=head1 NAME

App::http2http - generic HTTP proxy server with logging

=cut


use strict;
use warnings;

our $VERSION = '0.01';


use Log::Log4perl;

use Getopt::Long::Descriptive;

use App::http2http::Proxy;

use HTTP::Proxy ':log';
use HTTP::Proxy::HeaderFilter::simple;
use HTTP::Proxy::BodyFilter::simple;
use HTTP::Proxy::BodyFilter::complete;

use constant::boolean;

use File::Spec;
use Net::Server::Daemonize 'daemonize';


sub new {
    my ($class, %args) = @_;

    my $name = "http2http";

    my ($opt, $usage) = describe_options(
        "$0 %o",
        [ 'host|s=s',     "local host bind address", { default => '127.0.0.1' } ],
        [ 'port|p=i',     "local port bind address", { default => 8080 } ],
        [ 'anonymize|a',  "no Via and X-Forwarded-For headers", ],
        [ 'eval|e=s',     "filter as Perl eval code", ],
        [ 'daemonize|D',  "run as daemon", ],
        [ 'uid|U',        "daemon user",             { default => $> } ],
        [ 'gid|G',        "daemon group",            { default => $) } ],
        [ 'pidfile|P=s',  "pid file",                { default => File::Spec->rel2abs("$name.pid") } ],
        [ 'log4perl|L=s', "log4perl configuration file", ],
        [ 'help',         "print usage message and exit" ],
    );

    print($usage->text), exit if $opt->help;

    $args{argv} = \@ARGV;

    my $logger = $opt->daemonize ? 'Logfile' : 'Screen';

    my $logconf = {
        'log4perl.logger'                     => "DEBUG, $logger",
        'log4perl.appender.Logfile'           => 'Log::Dispatch::File::Stamped',
        'log4perl.appender.Logfile.stamp_fmt' => '%Y-%m-%d',
        'log4perl.appender.Logfile.filename'  => File::Spec->rel2abs("$name.log"),
        'log4perl.appender.Logfile.layout'    => 'PatternLayout',
        'log4perl.appender.Logfile.layout.ConversionPattern' => '%d{ISO8601}: %c: %m{chomp}%n',
        'log4perl.appender.Screen'            => 'Log::Log4perl::Appender::Screen',
        'log4perl.appender.Screen.stderr'     => 0,
        'log4perl.appender.Screen.layout'     => 'PatternLayout',
        'log4perl.appender.Screen.layout.ConversionPattern' => '%d{ISO8601}: %c: %m{chomp}%n',
    };

    Log::Log4perl->init( $opt->log4perl || $logconf );

    @args{qw(via x_forwarder_for)} = (undef, undef) if $opt->anonymize;
    $args{filter} = eval $opt->eval if $opt->eval;

    my $self = bless {
        filter => sub { },
        %$opt,
        %args,
    } => $class;

    return $self;
};


sub start {
    my ($self) = @_;

    my $proxy = App::http2http::Proxy->new(
        host => '127.0.0.1',
        port => 8080,
        logmask => PROCESS | SOCKET | STATUS | DATA,
        %$self,
    );

    $proxy->push_filter(
        mime => '*/*',
        request => HTTP::Proxy::HeaderFilter::simple->new(
            sub {
                my ($self, $headers, $request) = @_;
                my $content = $request->content;
                $content =~ s/\n/ /sg;
                my $uri = $request->uri;
                $proxy->log(DATA, 'REQUEST', sprintf '%s:%s|%s %s|%s|%s',
                    $proxy->client_socket->peerhost, $proxy->client_socket->peerport,
                    $request->method, $uri->as_string, $request->headers->as_string('|'), $content);
            }
        ),
        response => HTTP::Proxy::BodyFilter::complete->new,
        response => HTTP::Proxy::BodyFilter::simple->new(
            sub {
                my ($self, $dataref, $response, $protocol, $buffer) = @_;
                return if defined $buffer;
                my $content = $$dataref;
                $content =~ s/\n/ /sg;
                $proxy->log(DATA, 'RESPONSE', sprintf '%s:%s|%s|%s|%s',
                    $proxy->client_socket->peerhost, $proxy->client_socket->peerport,
                    $response->status_line, $response->headers->as_string('|'), $content);
            }
        ),
    );

    $proxy->push_filter(
        mime => '*/*',
        request => HTTP::Proxy::HeaderFilter::simple->new(
            $self->{filter}
        ),
    );

    $proxy->log(PROCESS, "PROCESS", "Staring server at " . $self->{host} . ":" . $self->{port});

    if ($self->{daemonize}) {
        $proxy->log(PROCESS, "PROCESS", "Daemonizing");
        daemonize($self->{uid}, $self->{gid}, $self->{pidfile});
    };

    $proxy->start;
};


=head1 SEE ALSO

L<HTTP::Proxy>.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-http2http>

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2012 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
