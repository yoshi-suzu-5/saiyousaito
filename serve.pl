#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Daemon;
use HTTP::Status;
use File::Basename;

use POSIX qw(SIGTERM);

my $port = $ARGV[0] || 3000;
my $root = $ARGV[1] || '.';

my $d = HTTP::Daemon->new(
    LocalAddr => '127.0.0.1',
    LocalPort => $port,
    ReuseAddr => 1,
) or die "Cannot start server: $!";

print "Serving at: http://localhost:$port/\n";
$| = 1;

my %mime = (
    html => 'text/html; charset=utf-8',
    css  => 'text/css',
    js   => 'application/javascript',
    png  => 'image/png',
    jpg  => 'image/jpeg',
    svg  => 'image/svg+xml',
    ico  => 'image/x-icon',
    woff2 => 'font/woff2',
);

while (my $c = $d->accept) {
    while (my $r = $c->get_request) {
        my $path = $r->url->path;
        $path =~ s|\.\.||g;
        $path = '/' if $path eq '';
        $path .= 'index.html' if $path =~ m|/$|;

        my $file = $root . $path;
        $file =~ s|/|\\|g if $^O eq 'MSWin32';

        if (-f $file) {
            open my $fh, '<', $file or do {
                $c->send_error(RC_INTERNAL_SERVER_ERROR);
                next;
            };
            binmode $fh;
            local $/;
            my $content = <$fh>;
            close $fh;

            my ($ext) = $file =~ /\.(\w+)$/;
            my $ct = $mime{lc($ext // '')} || 'application/octet-stream';

            my $resp = HTTP::Response->new(RC_OK);
            $resp->content_type($ct);
            $resp->content($content);
            $c->send_response($resp);
        } else {
            $c->send_error(RC_NOT_FOUND, "Not found: $path");
        }
    }
    $c->close;
}
