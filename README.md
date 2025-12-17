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
| --port        | -P                  |SIP server TCP port            |3000       | No
| --sip_user    | -u, --su            |SIP login user ID              |none       | Yes
| --sip_pass    | -p, --sp            |SIP login password             |none       | Yes
| --location    | -l                  |SIP location code              |none       | Yes
| --terminator  | -t                  |Record terminator: CR or CRLF  |CR         | No
| --help        | -h                  |Show usage information         |           | No

## Example

### Basic usage:

    ./sip2_connection_timer.pl --host 192.168.1.50 --port 6001 --sip_user sipuser --sip_pass secret123 --location MAIN

### Using CRLF terminator:

    ./sip2_connection_timer.pl -t CRLF --su admin --sp 1234 -l EAST


# SIP Continuous Timeout Tester

This script (`sip_continuous_timeout_tester.pl`) connects to a SIP2 server, logs in, and sends periodic status messages (SIP 99) to keep the connection alive or test timeout behavior. It automatically reconnects if the connection is dropped.

## Usage

    ./sip_continuous_timeout_tester.pl [options]

### Options

| Option        |Alias                |Description                    |Default    | Required
| --------------|---------------------|-------------------------------|-----------|----------
| --host        | -h                  |SIP server host/IP             |127.0.0.1  | No
| --port        | -P                  |SIP server TCP port            |3000       | No
| --sip_user    | -u, --su            |SIP login user ID              |none       | Yes
| --sip_pass    | -p, --sp            |SIP login password             |none       | Yes
| --location    | -l                  |SIP location code              |none       | Yes
| --interval    | -i                  |Seconds between SIP 99 messages|60         | No
| --terminator  | -t                  |Record terminator: CR or CRLF  |CR         | No
| --verbose     | -v                  |Enable verbose output          |Disabled   | No
| --log-file    | -f                  |Log output to file             |none       | No
| --help        |                     |Show usage information         |           | No

### Example

    ./sip_continuous_timeout_tester.pl --host 192.168.1.50 --port 6001 --sip_user sipuser --sip_pass secret123 --location MAIN --interval 30 --verbose --log-file sip_test.log


### Docker Usage

You can also run the continuous tester using Docker.

**Build the image:**

    docker build -t sip-tester .

**Run the container:**

    docker run --env SIP_USER=sipuser --env SIP_PASS=secret123 --env SIP_LOCATION=MAIN sip-tester

Supported environment variables (override command line defaults):

*   `SIP_HOST`
*   `SIP_PORT`
*   `SIP_USER`
*   `SIP_PASS`
*   `SIP_LOCATION`
*   `SIP_INTERVAL`
*   `SIP_TERMINATOR`
*   `SIP_VERBOSE`
*   `SIP_LOG_FILE`

## License

GPLv3
