Install proxychains ng (new generation) https://github.com/rofl0r/proxychains-ng. You can use it with self-hosted HTTP forward proxies via Squid, Tinyproxy or even Caddy server with HTTP forward proxy module built in.

* [Install proxychains ng](#install-proxychains-ng)
* [Use proxychains4](#use-proxychains4)

# Install proxychains ng

Install on AlmaLinux 9 using GCC 13 Toolset for compilation and install.

```
source /opt/rh/gcc-toolset-13/enable
mkdir -p /home/proxysetup /etc/proxychains
cd /home/proxysetup
git clone https://github.com/rofl0r/proxychains-ng
cd proxychains-ng
./configure --prefix=/usr --sysconfdir=/etc/proxychains
make -j $(nproc)
make install
make install-config
```
```
proxychains4 --help

Usage:  proxychains4 -q -f config_file program_name [arguments]
        -q makes proxychains quiet - this overrides the config setting
        -f allows one to manually specify a configfile to use
        for example : proxychains telnet somehost.com
More help in README file
```

Config installed at `/etc/proxychains/proxychains.conf`

```
make install-config
./tools/install.sh -D -m 644 src/proxychains.conf /etc/proxychains/proxychains.conf
```

Contents of installed `/etc/proxychains/proxychains.conf`:

```
# proxychains.conf  VER 4.x
#
#        HTTP, SOCKS4a, SOCKS5 tunneling proxifier with DNS.


# The option below identifies how the ProxyList is treated.
# only one option should be uncommented at time,
# otherwise the last appearing option will be accepted
#
#dynamic_chain
#
# Dynamic - Each connection will be done via chained proxies
# all proxies chained in the order as they appear in the list
# at least one proxy must be online to play in chain
# (dead proxies are skipped)
# otherwise EINTR is returned to the app
#
strict_chain
#
# Strict - Each connection will be done via chained proxies
# all proxies chained in the order as they appear in the list
# all proxies must be online to play in chain
# otherwise EINTR is returned to the app
#
#round_robin_chain
#
# Round Robin - Each connection will be done via chained proxies
# of chain_len length
# all proxies chained in the order as they appear in the list
# at least one proxy must be online to play in chain
# (dead proxies are skipped).
# the start of the current proxy chain is the proxy after the last
# proxy in the previously invoked proxy chain.
# if the end of the proxy chain is reached while looking for proxies
# start at the beginning again.
# otherwise EINTR is returned to the app
# These semantics are not guaranteed in a multithreaded environment.
#
#random_chain
#
# Random - Each connection will be done via random proxy
# (or proxy chain, see  chain_len) from the list.
# this option is good to test your IDS :)

# Make sense only if random_chain or round_robin_chain
#chain_len = 2

# Quiet mode (no output from library)
#quiet_mode

## Proxy DNS requests - no leak for DNS data
# (disable all of the 3 items below to not proxy your DNS requests)

# method 1. this uses the proxychains4 style method to do remote dns:
# a thread is spawned that serves DNS requests and hands down an ip
# assigned from an internal list (via remote_dns_subnet).
# this is the easiest (setup-wise) and fastest method, however on
# systems with buggy libcs and very complex software like webbrowsers
# this might not work and/or cause crashes.
proxy_dns

# method 2. use the old proxyresolv script to proxy DNS requests
# in proxychains 3.1 style. requires `proxyresolv` in $PATH
# plus a dynamically linked `dig` binary.
# this is a lot slower than `proxy_dns`, doesn't support .onion URLs,
# but might be more compatible with complex software like webbrowsers.
#proxy_dns_old

# method 3. use proxychains4-daemon process to serve remote DNS requests.
# this is similar to the threaded `proxy_dns` method, however it requires
# that proxychains4-daemon is already running on the specified address.
# on the plus side it doesn't do malloc/threads so it should be quite
# compatible with complex, async-unsafe software.
# note that if you don't start proxychains4-daemon before using this,
# the process will simply hang.
#proxy_dns_daemon 127.0.0.1:1053

# set the class A subnet number to use for the internal remote DNS mapping
# we use the reserved 224.x.x.x range by default,
# if the proxified app does a DNS request, we will return an IP from that range.
# on further accesses to this ip we will send the saved DNS name to the proxy.
# in case some control-freak app checks the returned ip, and denies to 
# connect, you can use another subnet, e.g. 10.x.x.x or 127.x.x.x.
# of course you should make sure that the proxified app does not need
# *real* access to this subnet. 
# i.e. dont use the same subnet then in the localnet section
#remote_dns_subnet 127 
#remote_dns_subnet 10
remote_dns_subnet 224

# Some timeouts in milliseconds
tcp_read_time_out 15000
tcp_connect_time_out 8000

### Examples for localnet exclusion
## localnet ranges will *not* use a proxy to connect.
## note that localnet works only when plain IP addresses are passed to the app,
## the hostname resolves via /etc/hosts, or proxy_dns is disabled or proxy_dns_old used.

## Exclude connections to 192.168.1.0/24 with port 80
# localnet 192.168.1.0:80/255.255.255.0

## Exclude connections to 192.168.100.0/24
# localnet 192.168.100.0/255.255.255.0

## Exclude connections to ANYwhere with port 80
# localnet 0.0.0.0:80/0.0.0.0
# localnet [::]:80/0

## RFC6890 Loopback address range
## if you enable this, you have to make sure remote_dns_subnet is not 127
## you'll need to enable it if you want to use an application that 
## connects to localhost.
# localnet 127.0.0.0/255.0.0.0
# localnet ::1/128

## RFC1918 Private Address Ranges
# localnet 10.0.0.0/255.0.0.0
# localnet 172.16.0.0/255.240.0.0
# localnet 192.168.0.0/255.255.0.0

### Examples for dnat
## Trying to proxy connections to destinations which are dnatted,
## will result in proxying connections to the new given destinations.
## Whenever I connect to 1.1.1.1 on port 1234 actually connect to 1.1.1.2 on port 443
# dnat 1.1.1.1:1234  1.1.1.2:443

## Whenever I connect to 1.1.1.1 on port 443 actually connect to 1.1.1.2 on port 443
## (no need to write :443 again)
# dnat 1.1.1.2:443  1.1.1.2

## No matter what port I connect to on 1.1.1.1 port actually connect to 1.1.1.2 on port 443
# dnat 1.1.1.1  1.1.1.2:443

## Always, instead of connecting to 1.1.1.1, connect to 1.1.1.2
# dnat 1.1.1.1  1.1.1.2

# ProxyList format
#       type  ip  port [user pass]
#       (values separated by 'tab' or 'blank')
#
#       only numeric ipv4 addresses are valid
#
#
#        Examples:
#
#               socks5  192.168.67.78   1080    lamer   secret
#               http    192.168.89.3    8080    justu   hidden
#               socks4  192.168.1.49    1080
#               http    192.168.39.93   8080
#
#
#       proxy types: http, socks4, socks5, raw
#         * raw: The traffic is simply forwarded to the proxy without modification.
#        ( auth types supported: "basic"-http  "user/pass"-socks )
#
[ProxyList]
# add proxy here ...
# meanwile
# defaults set to "tor"
socks4  127.0.0.1 9050
```

Uncomment `round_robin_chain`

```
round_robin_chain
#
# Round Robin - Each connection will be done via chained proxies
# of chain_len length
# all proxies chained in the order as they appear in the list
# at least one proxy must be online to play in chain
# (dead proxies are skipped).
# the start of the current proxy chain is the proxy after the last
# proxy in the previously invoked proxy chain.
# if the end of the proxy chain is reached while looking for proxies
# start at the beginning again.
# otherwise EINTR is returned to the app
# These semantics are not guaranteed in a multithreaded environment.
```

Add HTTP forward proxies under the `[ProxyList]` section where values separated by blank or tabs.

```
[ProxyList]
http    192.168.122.60  8081 yourusername yourpassword
http    192.168.122.60  8081 yourusername yourpassword
```

Configure `proxychains4-daemon` as a systemd service `/etc/systemd/system/proxychains4-daemon.service` on port `1054`.

```
[Unit]
Description=ProxyChains4 Daemon for DNS forwarding
After=network.target

[Service]
ExecStart=/usr/bin/proxychains4-daemon 127.0.0.1:1054
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
```
sudo systemctl daemon-reload
sudo systemctl enable proxychains4-daemon
sudo systemctl start proxychains4-daemon
sudo systemctl status proxychains4-daemon --no-pager -l
sudo journalctl -u proxychains4-daemon --no-pager | tail -10
```

Edit `/etc/proxychains/proxychains.conf` file to make proxychains use the daemon for DNS resolution. Look for the section related to DNS, and modify it like this:

```
# Enable proxy DNS requests
proxy_dns_daemon 127.0.0.1:1054
```

Be sure to comment out `proxy_dns` method

```
# method 1. this uses the proxychains4 style method to do remote dns:
# a thread is spawned that serves DNS requests and hands down an ip
# assigned from an internal list (via remote_dns_subnet).
# this is the easiest (setup-wise) and fastest method, however on
# systems with buggy libcs and very complex software like webbrowsers
# this might not work and/or cause crashes.
#proxy_dns
 
# method 2. use the old proxyresolv script to proxy DNS requests
# in proxychains 3.1 style. requires `proxyresolv` in $PATH
# plus a dynamically linked `dig` binary.
# this is a lot slower than `proxy_dns`, doesn't support .onion URLs,
# but might be more compatible with complex software like webbrowsers.
#proxy_dns_old

# method 3. use proxychains4-daemon process to serve remote DNS requests.
# this is similar to the threaded `proxy_dns` method, however it requires
# that proxychains4-daemon is already running on the specified address.
# on the plus side it doesn't do malloc/threads so it should be quite
# compatible with complex, async-unsafe software.
# note that if you don't start proxychains4-daemon before using this,
# the process will simply hang.
proxy_dns_daemon 127.0.0.1:1054
```

# Use proxychains4

Use `proxychains4`

```
proxychains4 curl -Iv https://wordpress.org
```

```
proxychains4 curl -Iv https://wordpress.org
[proxychains] config file found: /etc/proxychains/proxychains.conf
[proxychains] preloading /usr/lib/libproxychains4.so
[proxychains] DLL init: proxychains-ng 4.17-git-3-g1760c93
*   Trying 127.0.0.1:443...
[proxychains] Round Robin chain  ...  192.168.122.60:8081  ...  wordpress.org:443  ...  OK
* Connected to wordpress.org (192.168.122.60) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
*  CAfile: /etc/pki/tls/certs/ca-bundle.crt
* TLSv1.0 (OUT), TLS header, Certificate Status (22):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS header, Certificate Status (22):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS header, Finished (20):
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.2 (OUT), TLS header, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS header, Unknown (23):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=*.wordpress.org
*  start date: Dec  1 00:00:00 2023 GMT
*  expire date: Dec 31 23:59:59 2024 GMT
*  subjectAltName: host "wordpress.org" matched cert's "wordpress.org"
*  issuer: C=GB; ST=Greater Manchester; L=Salford; O=Sectigo Limited; CN=Sectigo ECC Domain Validation Secure Server CA
*  SSL certificate verify ok.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* TLSv1.2 (OUT), TLS header, Unknown (23):
* TLSv1.2 (OUT), TLS header, Unknown (23):
* TLSv1.2 (OUT), TLS header, Unknown (23):
* Using Stream ID: 1 (easy handle 0x564685f61ee0)
* TLSv1.2 (OUT), TLS header, Unknown (23):
> HEAD / HTTP/2
> Host: wordpress.org
> user-agent: curl/7.76.1
> accept: */*
> 
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* TLSv1.2 (IN), TLS header, Unknown (23):
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
* TLSv1.2 (OUT), TLS header, Unknown (23):
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.2 (IN), TLS header, Unknown (23):
< HTTP/2 200 
HTTP/2 200 
< server: nginx
server: nginx
< date: Sat, 28 Sep 2024 09:06:18 GMT
date: Sat, 28 Sep 2024 09:06:18 GMT
< content-type: text/html; charset=UTF-8
content-type: text/html; charset=UTF-8
< vary: Accept-Encoding
vary: Accept-Encoding
< strict-transport-security: max-age=3600
strict-transport-security: max-age=3600
< x-olaf: ⛄
x-olaf: ⛄
< link: <https://wordpress.org/wp-json/>; rel="https://api.w.org/"
link: <https://wordpress.org/wp-json/>; rel="https://api.w.org/"
< link: <https://wordpress.org/wp-json/wp/v2/pages/457>; rel="alternate"; title="JSON"; type="application/json"
link: <https://wordpress.org/wp-json/wp/v2/pages/457>; rel="alternate"; title="JSON"; type="application/json"
< link: <https://w.org/>; rel=shortlink
link: <https://w.org/>; rel=shortlink
< x-frame-options: SAMEORIGIN
x-frame-options: SAMEORIGIN
< alt-svc: h3=":443"; ma=86400
alt-svc: h3=":443"; ma=86400
< x-nc: HIT ord 1
x-nc: HIT ord 1

< 
* Connection #0 to host wordpress.org left intact
```

Inspecting Caddy HTTP forward proxy log `/var/log/caddy/forward_proxy_access_8081.log`

```
tail -1 /var/log/caddy/forward_proxy_access_8081.log | jq -r
{
  "level": "info",
  "ts": 1727514379.0369816,
  "logger": "http.log.access.log0",
  "msg": "handled request",
  "request": {
    "remote_ip": "192.168.122.60",
    "remote_port": "14974",
    "client_ip": "192.168.122.60",
    "proto": "HTTP/1.0",
    "method": "CONNECT",
    "host": "wordpress.org:443",
    "uri": "wordpress.org:443",
    "headers": {
      "Proxy-Authorization": [
        "REDACTED"
      ]
    }
  },
  "bytes_read": 848,
  "user_id": "yourusername",
  "duration": 0.243772872,
  "size": 4602,
  "status": 0,
  "resp_headers": {
    "Server": [
      "Caddy"
    ]
  }
}
```

Direct `192.168.122.60` Caddy HTTP Forward proxy test

```
curl -x http://yourusername:yourpassword@192.168.122.60:8081 -Iv https://wordpress.org
*   Trying 192.168.122.60:8081...
* Connected to 192.168.122.60 (192.168.122.60) port 8081 (#0)
* allocate connect buffer!
* Establish HTTP proxy tunnel to wordpress.org:443
* Proxy auth using Basic with user 'yourusername'
> CONNECT wordpress.org:443 HTTP/1.1
> Host: wordpress.org:443
> Proxy-Authorization: Basic eW91cnVzZXJuYW1lOnlvdXJwYXNzd29yZA==
> User-Agent: curl/7.76.1
> Proxy-Connection: Keep-Alive
> 
< HTTP/1.1 200 OK
HTTP/1.1 200 OK
< Server: Caddy
Server: Caddy
< Content-Length: 0
Content-Length: 0
* Ignoring Content-Length in CONNECT 200 response
< 

* Proxy replied 200 to CONNECT request
* CONNECT phase completed!
* ALPN, offering h2
* ALPN, offering http/1.1
*  CAfile: /etc/pki/tls/certs/ca-bundle.crt
* TLSv1.0 (OUT), TLS header, Certificate Status (22):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* CONNECT phase completed!
* CONNECT phase completed!
* TLSv1.2 (IN), TLS header, Certificate Status (22):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS header, Finished (20):
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.2 (OUT), TLS header, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS header, Unknown (23):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=*.wordpress.org
*  start date: Dec  1 00:00:00 2023 GMT
*  expire date: Dec 31 23:59:59 2024 GMT
*  subjectAltName: host "wordpress.org" matched cert's "wordpress.org"
*  issuer: C=GB; ST=Greater Manchester; L=Salford; O=Sectigo Limited; CN=Sectigo ECC Domain Validation Secure Server CA
*  SSL certificate verify ok.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* TLSv1.2 (OUT), TLS header, Unknown (23):
* TLSv1.2 (OUT), TLS header, Unknown (23):
* TLSv1.2 (OUT), TLS header, Unknown (23):
* Using Stream ID: 1 (easy handle 0x557251de2d80)
* TLSv1.2 (OUT), TLS header, Unknown (23):
> HEAD / HTTP/2
> Host: wordpress.org
> user-agent: curl/7.76.1
> accept: */*
> 
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.2 (IN), TLS header, Unknown (23):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* TLSv1.2 (IN), TLS header, Unknown (23):
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
* TLSv1.2 (OUT), TLS header, Unknown (23):
< HTTP/2 200 
HTTP/2 200 
< server: nginx
server: nginx
< date: Sat, 28 Sep 2024 08:18:58 GMT
date: Sat, 28 Sep 2024 08:18:58 GMT
< content-type: text/html; charset=UTF-8
content-type: text/html; charset=UTF-8
< vary: Accept-Encoding
vary: Accept-Encoding
< strict-transport-security: max-age=3600
strict-transport-security: max-age=3600
< x-olaf: ⛄
x-olaf: ⛄
< link: <https://wordpress.org/wp-json/>; rel="https://api.w.org/"
link: <https://wordpress.org/wp-json/>; rel="https://api.w.org/"
< link: <https://wordpress.org/wp-json/wp/v2/pages/457>; rel="alternate"; title="JSON"; type="application/json"
link: <https://wordpress.org/wp-json/wp/v2/pages/457>; rel="alternate"; title="JSON"; type="application/json"
< link: <https://w.org/>; rel=shortlink
link: <https://w.org/>; rel=shortlink
< x-frame-options: SAMEORIGIN
x-frame-options: SAMEORIGIN
< alt-svc: h3=":443"; ma=86400
alt-svc: h3=":443"; ma=86400
< x-nc: HIT ord 2
x-nc: HIT ord 2

< 
* Connection #0 to host 192.168.122.60 left intact
```