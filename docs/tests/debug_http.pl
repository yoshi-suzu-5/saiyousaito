#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;

my $port = $ARGV[0] // 3001;
my $ua = LWP::UserAgent->new(timeout => 10);
my $res = $ua->get("http://localhost:$port/");
print "Status : " . $res->status_line . "\n";
print "Is success: " . ($res->is_success ? 'YES' : 'NO') . "\n";
print "Content (300 chars):\n";
print substr($res->decoded_content // '', 0, 300) . "\n";
