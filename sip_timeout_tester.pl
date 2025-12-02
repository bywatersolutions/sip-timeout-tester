#!/usr/bin/perl

use Modern::Perl;

use IO::Socket::INET;
use Socket      qw(:crlf);
use Time::HiRes qw(time);
use Getopt::Long;

use Getopt::Long::Descriptive;

my ( $opt, $usage ) = describe_options(
    "%c %o",
    [ "host|h=s",        "Host IP address",    { default  => '127.0.0.1' } ],
    [ "port|P=i",        "Port number",        { default  => 3000 } ],
    [ "sip_user|su|u=s", "SIP login user ID",  { required => 1 } ],
    [ "sip_pass|sp|p=s", "SIP login password", { required => 1 } ],
    [ "location|location_code|l=s", "SIP location code", { required => 1 } ],
    [
        "terminator|t=s",
        "Terminator character, CR or CRLF",
        { default => "CR" }
    ],
    [],
    [ "help", "Show this message", { shortcircuit => 1 } ],
);

print( $usage->text ), exit if $opt->help;

my $host           = $opt->host;
my $port           = $opt->port;
my $login_user_id  = $opt->sip_user;
my $login_password = $opt->sip_pass;
my $location_code  = $opt->location;
my $terminator     = $opt->terminator;

die "Port must be > 0\n" unless $port > 0;

$terminator = $terminator eq 'CR' ? $CR : $CRLF;

# Set perl to expect the same record terminator it is sending
$/ = $terminator;

print "Connecting to $host:$port...\n";
my $socket   = get_socket( { host => $host, port => $port } );
my $duration = wait_for_timeout($socket);
printf "Connection without login lasted %.3f seconds.\n", $duration;

print "Reconnecting to $host:$port...\n";
$socket = get_socket( { host => $host, port => $port } );
my $login_msg = build_login_command_message(
    {
        login_user_id  => $login_user_id,
        login_password => $login_password,
        location_code  => $location_code
    }
);
print $socket $login_msg . $terminator;
say "Message: $login_msg";
my $data = <$socket>;
say "Response: " . ( defined $data ? $data : 'undef' );
$duration = wait_for_timeout($socket);
printf "Connection with login lasted %.3f seconds.\n", $duration;

sub get_socket {
    my ($params) = @_;

    my $host = $params->{host};
    my $port = $params->{port};

    my $socket = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 10,
    );

    die "Could not connect: $!\n" unless $socket;

    return $socket;
}

sub wait_for_timeout {
    my ($socket) = @_;
    print "Connected. Waiting for disconnect...\n";

    my $start = time();
    my $buf;

    while (1) {
        my $bytes = $socket->recv( $buf, 1024 );

        if ( !defined $bytes ) {
            warn "Socket error: $!\n";
            last;
        }
        if ( $bytes eq '' ) {
            last;
        }

        # ignore data, just monitoring connection
    }

    my $duration = time() - $start;
    $socket->close();

    return $duration;
}

use constant {
    FID_LOGIN_UID     => 'CN',
    FID_LOGIN_PWD     => 'CO',
    FID_LOCATION_CODE => 'CP',
    LOGIN             => '93',
};

sub build_login_command_message {
    my ($params) = @_;

    my $login_user_id  = $params->{login_user_id};
    my $login_password = $params->{login_password};
    my $location_code  = $params->{location_code};

    return
        LOGIN . "00"
      . FID_LOGIN_UID
      . $login_user_id . "|"
      . FID_LOGIN_PWD
      . $login_password . "|"
      . FID_LOCATION_CODE
      . $location_code . "|";
}
