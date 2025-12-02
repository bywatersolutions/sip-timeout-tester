# SIP2 Connection Timeout Tester

This Perl script tests how long a SIP2 server keeps a TCP connection
open, both **without authentication** and **after sending a SIP2 login
message**.
It is useful for diagnosing idle timeout behavior on SIP2 servers.

## Requirements

Perl modules used:

-   Modern::Perl
-   IO::Socket::INET
-   Socket
-   Time::HiRes
-   Getopt::Long::Descriptive

Install missing modules via CPAN if required:

    cpan Modern::Perl IO::Socket::INET Time::HiRes Getopt::Long::Descriptive

## Usage

    ./sip2_connection_timer.pl [options]

### Options

 | Option        |Alias                |Description                    |Default    | Required
 | --------------|---------------------|-------------------------------|-----------|----------
 | --host        | -h                  |SIP server host/IP             |127.0.0.1  | No
 | --port        | -p                  |SIP server TCP port            |3000       | No
 | --sip_user    | --su                |SIP login user ID              |none       | Yes
 | --sip_pass    | --sp                |SIP login password             |none       | Yes
 | --location    | --location_code, -l |SIP location code              |none       | Yes
 | --terminator  | -t                  |Record terminator: CR or CRLF  |CR         | No
 | --help        |                     |Show usage information         |---        | No

## Example

### Basic usage:

    ./sip2_connection_timer.pl --host 192.168.1.50 --port 6001 --sip_user sipuser --sip_pass secret123 --location MAIN

### Using CRLF terminator:

    ./sip2_connection_timer.pl -t CRLF --su admin --sp 1234 -l EAST

## License

GPLv3
