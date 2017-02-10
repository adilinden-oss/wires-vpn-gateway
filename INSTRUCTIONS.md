# Building the Wires-X VPN Gateway

## Installation

This server is running Debian 8. The system is installed using basic default settings.

```
Disk 1
    /boot                 512MB
    swap                  1GB
    /                     remainder
```

During the package installation ssh server and standard system utilities are selected.

### Additional Packages

Upon first login these additional packages are installed.

```
apt-get install open-vm-tools vim bzip2 gzip zip less build-essential ntp fail2ban
```

### Remove Packages

If commone system utilities were selected during install than all NFS related components were istalled and enabled.  Remove what's not needed.

```
apt-get remove --auto-remove nfs-common rpcbind
```

### postfix

Install postfix from Debian repository.

```
apt-get install postfix
```

Select 'Internet Site' during installation.

## System Configuration Items

### sshd

Edit `/etc/ssh/sshd_config` and change ssh daemon listening port to 222 for obfuscation.  This isn't as much of a security feature as a simple way to lessen how much ssh gets hammered with attacks.  Also change PermitRootLogin to say without-password, this will allow us to use shared key ssh to root.  

### fail2ban

Edit `/etc/fail2ban/jail.conf` and duplicate the ssh section.  Change name to ssh222 and port to 222 on the duplicated section.

### postfix

Edit `/etc/postfix/main.cf` and change the following line to bind postfix to localhost only.

```
inet_interfaces = localhost
```

## OpenVPN

Sources of information:

* https://help.ubuntu.com/lts/serverguide/openvpn.html

### Install

Install packages

```
apt-get install openvpn easy-rsa sudo
```

Create directory for client specific configs

```
mkdir  /etc/openvpn/client.d
```

Create a user for the server to run as

```
addgroup --quiet --system openvpn
adduser --quiet --system --ingroup openvpn --no-create-home \
    --home /nonexistent --shell /usr/sbin/nologin \
    --disabled-password openvpn
```

Allow openvpn to execute the iptables command create the '/etc/sudoers.d/openvpn' file with the following content:

```
Defaults:openvpn !requiretty
openvpn ALL = NOPASSWD: /sbin/iptables
```

### Setup certificate authority

Get the easy_rsa files into the right location

```
mkdir /etc/openvpn/easy-rsa/
cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
```

We need to patch the `/etc/openvpn/easy-rsa/pkitool` file for batch mode to be useable.  Otherwise our `make_client_cert` script will barf...  Edit the `/etc/openvpn/easy-rsa/pkitool` file, change line 285 from

```
KEY_ALTNAMES="$KEY_CN"
```

to

```
KEY_ALTNAMES="DNS:$KEY_CN"
```

Edit `/etc/openvpn/easy-rsa/vars`

```
export KEY_COUNTRY="CA"
export KEY_PROVINCE="ON"
export KEY_CITY="Bedrock"
export KEY_ORG="Fred Flintstone Gateway"
export KEY_EMAIL="fred@bedrock.ca"
export KEY_NAME="N0CALL AMPRNet VPN"
export KEY_OU="N0CALL AMPRNet VPN"
export KEY_CN="amprnetgw"
export KEY_ALTNAMES="DNS:${KEY_CN}"
```

Generate the master certificate and key

```
cd /etc/openvpn/easy-rsa/
source vars
./clean-all
./build-ca
```

Generate server certificate and key

```
./build-key-server amprnetgw
```

Diffie Hellman parameters must be generated for the OpenVPN server

```
./build-dh
```

Copy the keys to where they chould be.

```
cd keys/
cp amprnetgw.crt amprnetgw.key ca.crt dh2048.pem /etc/openvpn/
```

### Generate client certificates

This is to illustrate the manual process.  We will use a custom wrapper explained a bit later.  Defer client certificate generation till later.

```
cd /etc/openvpn/easy-rsa/
source vars
./build-key client1
```

Copy these keys to the client using a secure method.

```
/etc/openvpn/ca.crt
/etc/openvpn/easy-rsa/keys/client1.crt
/etc/openvpn/easy-rsa/keys/client1.key
```

### Configure the server

Place the udp server configuration file server-udp.conf as `/etc/openvpn/server-udp.conf`.

Enable IP forwarding in /etc/sysctl.conf by uncommenting line

```
net.ipv4.ip_forward=1
```

Reload sysctl

```
sysctl -p /etc/sysctl.conf
```

Start the server

```
journalctl -xe
```

Start the templated service

```
service openvpn@server-udp start
```

To have service start at system boot edit /etc/default/openvpn and add

```
AUTOSTART="server-udp"
```

Apply the changes

```
systemctl daemon-reload
```

### Client firewall

Install the `openvpn/up.sh` as `/etc/openvpn/up.sh`.  Also create a symlink

```
ln -s /etc/openvpn/up.sh /etc/openvpn/down.sh
```

Make script executable

```
chmod 755 /etc/openvpn/scripts/up.sh
```

Create the `/etc/openvpn/up-down.d` directory and populate with the `/etc/openvpn/up-down.d/example` and `/etc/openvpn/up-down.d/default` files.  Edit the `default` file for desired default settings.  Make a copy of the `examples` file and name as the common_name of connecting clients to establish client specific rules. Note that script applies either the client specific (if exists) or the defaults, not both.

This will now have OpenVPN create some firewall rules and other possbile routing upon client connection and removal upon client disconnect.

Currently these default rules are geared towards Wires-X port forwarding and protecting the client from any other malicious traffic.

## Client Configuration

Sample configuration file

```
# C:\Users\<username>\OpenVPN\config\client.ovpn
client
remote 10.73.73.30
port 443
proto udp
dev tun
dev-type tun
ns-cert-type server
reneg-sec 86400
comp-lzo yes
cipher aes-128-cbc
verb 3
ca ca.crt
cert client.crt
key client.key
; Set the name of the Windows TAP network interface device here
dev-node MyTAP
```

Note that upon installation of OpenVPN client a new network device is created.  The "dev-node" name needs to match this device.  Best is to rename the network device associated with the TAP adapter to the name specificed in the configuration file: MyTAP.

## Simplify Client Setup

Install rrdtool

```
apt-get install rrdtool
```

Install a webserver

```
apt-get install nginx-light
```

Create a subtle default page `/var/www/html/index.html`

```
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Welcome!</title>
    <style>
      body {
          width: 35em;
          margin: 0 auto;
          font-family: Tahoma, Verdana, Arial, sans-serif;
      }
    </style>
  </head>
  <body>
    <h1>Welcome!</h1>
    <p>... to my world.</p>
    <p><em>Thank you for visiting.</em></p>
  </body>
</html>
```

Allow auto-indexing inside our obfuscated directory structure. Add the following inside the server definition block of /etc/nginx/sites-enabled/default

```
location /files {
    autoindex on;
}
```

Install the `manage_ovpn` script as `root/manage_ovpn`.  Install a crontab to start generating html status and traffic usage reports.

```
*/1 * * * * cd /root/manage_ovpn; ./make_reports status > /dev/null 2>&1
*/5 * * * * cd /root/manage_ovpn; ./make_reports graphs > /dev/null 2>&1
```

Create and manage client certificates using the `make_client_cert` scrips.  Its usage is straigtforward:

```
Usage: ./make_client_cert -n cn email | -u cn  | --update-all
    -n common_name email    : Create client config and cert
    -u common_name          : Update client config keeping same cert
    --update-all            : Update all client configs
```

Download the OpenVPN client file(s) for the operating systems of choice and place them in the `/var/www/html/files` directory for easy access for clients to install on their devices.

## Client autoconnect

On a Windows client, the following command line will connect a Windows client immmediately

```
"C:\Program Files\OpenVPN\bin\openvpn-gui.exe" --connect <client name>.ovpn
```

Create a shortcut with the above command (best to copy existing OpenVPN GUI shortcut) and place into the Startup folder.

## The Net44 Routing Table

Good guide at

```
http://wiki.ampr.org/wiki/Ubuntu_Linux_Gateway_Example
```

Because "my" 44net space is advertised via BGP and not hidden behing NAT, we do not need to use source based routing, nor do we want to use a default route pointing at the UCSD gateway.

### Manual method

Install the ampr specific RIPv2 daemon.

```
mkdir ampr_routing
cd ampr_routing
wget http://www.yo2loj.ro/hamprojects/ampr-ripd-1.15.tgz
mkdir ampr-ripd
cd ampr-ripd
tar xzf ../ampr-ripd-1.15.tgz
```

Note that the Makefile needs to be adjusted for a Debian system.  Change the man path to

```
MANDIR = $(BASEDIR)/share/man/man1
```

Proceed to build

```
make
make install
```

Create the tunnel device.

```
ip tunnel add ampr0 mode ipip local 10.73.73.30 ttl 64
ip link set dev ampr0 up
ip addr add 44.128.0.254/32 dev ampr0
ifconfig ampr0 multicast
```

Create routing rules

```
ip rule add to 44.0.0.0/8 table 44 priority 44
# We do not add these because we are BGP advertising!
#ip rule add from 44.128.0.0/24 table 44 priority 45
#ip route add default dev ampr0 via 169.228.66.251 onlink table 44
```

Run the ampr-ripd daemon in debug mode

```
./ampr-ripd -a 44.128.0.0/24 -i ampr0 -t 44 -d 
```

### Automated method

Edit `/etc/network/interfaces` and add

```
auto ampr0
iface ampr0 inet static
    address 44.128.0.254
    netmask 255.255.255.255
    pre-up ip tunnel add ampr0 mode ipip local 10.73.73.30 ttl 64
    up ip link set dev ampr0 up
    up ifconfig ampr0 multicast
    up ip rule add to 44.0.0.0/8 table 44 priority 44
    down ip rule del to 44.0.0.0/8 table 44 priority 44
    post-down ip tunnel del ampr0
```

Install the wrapper script, the config file and the systemd service file.

```
cp run-ampr/run-ampr /usr/sbin/run-ampr
cp run-ampr/run-ampr.conf /etc/run-ampr.conf
cp run-ampr/run-ampr.service /lib/systemd/system/run-ampr.service
```

Make wrapper executable

```
chmod 755 /usr/sbin/run-ampr
```

Make systemd aware of our new daemon

```
systemctl daemon-reload
systemctl enable run-ampr
systemctl start run-ampr
```

## That's it...
