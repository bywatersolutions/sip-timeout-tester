#!/usr/bin/perl

use Getopt::Long::Descriptive;
use IO::Select;
use IO::Socket::INET;
use Modern::Perl;
use Socket      qw(:crlf);
use Time::HiRes qw(time);
use POSIX       qw(strftime);

$| = 1; # Enable autoflush


my ( $opt, $usage ) = describe_options(
    "%c %o",
    [ "host|h=s",        "Host IP address",    { default  => $ENV{SIP_HOST} // '127.0.0.1' } ],
    [ "port|P=i",        "Port number",        { default  => $ENV{SIP_PORT} // 3000 } ],
    [ "sip_user|su|u=s", "SIP login user ID",  { default => $ENV{SIP_USER} } ],
    [ "sip_pass|sp|p=s", "SIP login password", { default => $ENV{SIP_PASS} } ],
    [ "location|location_code|l=s", "SIP location code", { default => $ENV{SIP_LOCATION} } ],
    [ "interval|i=i",    "Seconds between SIP 99 status messages", { default => $ENV{SIP_INTERVAL} // 60 } ],
    [
        "terminator|t=s",
        "Terminator character, CR or CRLF",
        { default => $ENV{SIP_TERMINATOR} // "CR" }
    ],
    [],
    [ "verbose|v", "Enable verbose output", { default => $ENV{SIP_VERBOSE} } ],
    [ "log-file|f=s", "Log output to file", { default => $ENV{SIP_LOG_FILE} } ],
    [ "help", "Show this message", { shortcircuit => 1 } ],
);

print($usage->text), exit if $opt->help;

if ( !defined $opt->sip_user || !defined $opt->sip_pass || !defined $opt->location ) {
    say "Missing required options: sip_user, sip_pass, location";
    print($usage->text);
    exit 1;
}

my $terminator = $opt->terminator eq 'CR' ? $CR : $CRLF;

my $last_disconnect_time = time();

my $logged_in = 0;
while (1) {

    my $sock = connect_socket();

    if (!$sock) {
        log_msg("Failed to connect to $opt->{host}:$opt->{port}, retrying in 5s...");
        sleep 5;
        next;
    }

    my $connected_at = time();
    log_msg("Connected.");

    # Send login
    my $login = sip_login($opt->sip_user, $opt->sip_pass, $opt->location);
    send_msg($sock, $login);

    my $next_status = time() + 1;    # send after 1 second initially

    my $select = IO::Select->new($sock);

    while (1) {

        # Check if socket closed
        my @ready = $select->can_read(0.1);

        foreach my $fh (@ready) {
            my $buffer = "";
            my $bytes  = sysread($fh, $buffer, 1024);

            if (!$bytes) {
                my $now = time();
                my $elapsed = sprintf("%.2f", $now - $connected_at);

                log_msg("Disconnected after $elapsed seconds.");

                $last_disconnect_time = $now;
                close $sock;
                undef $sock;
                last;
            } else {
                log_msg("Received data: $buffer") if $opt->verbose;
                if ( $buffer eq "940" ) {
                    log_msg("Login failed, exiting.");
                    exit 1;
                }
            }
        }

        # Send SC Status at interval
        if (time() >= $next_status) {
            send_msg($sock, sip_sc_status());
            $next_status = time() + $opt->interval;
        }

        last unless $sock;    # break inner loop if disconnected
    }

    # Backoff before reconnect
    log_msg("Reconnecting in 3 seconds...");
    sleep 3;
}

use constant {
    FID_LOGIN_UID     => 'CN',
    FID_LOGIN_PWD     => 'CO',
    FID_LOCATION_CODE => 'CP',
    LOGIN             => '93',
};

sub sip_login {
    my ($login_user_id, $login_password, $location_code) = @_;

    return
        LOGIN . "00"
      . FID_LOGIN_UID
      . $login_user_id . "|"
      . FID_LOGIN_PWD
      . $login_password . "|"
      . FID_LOCATION_CODE
      . $location_code . "|";
}

sub sip_sc_status {
    return "9900";    # Basic SC Status message
}

sub connect_socket {
    my $sock = IO::Socket::INET->new(
        PeerHost => $opt->host,
        PeerPort => $opt->port,
        Proto    => 'tcp',
        Timeout  => 10,
    );

    return $sock;
}

sub send_msg {
    my ($sock, $msg) = @_;
    log_msg("Sending message: $msg") if $opt->verbose;
    print $sock $msg . $terminator;
}

sub log_msg {
    my ($msg) = @_;
    my $timestamp = strftime( "%Y-%m-%d %H:%M:%S", localtime );
    my $log_line  = "[$timestamp] $msg";

    say $log_line;

    if ( $opt->log_file ) {
        open( my $fh, '>>', $opt->log_file ) or warn "Could not open log file: $!";
        say $fh $log_line;
        close $fh;
    }
}
