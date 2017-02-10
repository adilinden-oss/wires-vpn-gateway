# Wires-X VPN Gateway

[Yaesu](https://www.yaesu.com) [Wires-X](https://www.yaesu.com/jp/en/wires-x/index.php) and [IRLP (Internet Radio Linking Project)](http://www.irlp.net) are Internet linking methods for [Amateur Radio](https://en.wikipedia.org/wiki/Amateur_radio) use.  Both systems rely on [UDP](https://en.wikipedia.org/wiki/User_Datagram_Protocol) to transport voice packets between connected systems and to communicate with the central server infrastructure providing directory services and other functions.  When placed behind a firewall (which is generally good practise) a number of port forwarding rules are needed on the firewall to allow these systems to communicate.  This can be a painful and sometimes impossible task if one is not in control of the firewall, think WiFi hotspots, cellular mobile internet, and so forth.

This project describes how I built an OpenVPN gateway to provide fully routable public IP addresses to [Yaesu](https://www.yaesu.com) [Wires-X](https://www.yaesu.com/jp/en/wires-x/index.php) nodes.  I have not tried it with [IRLP (Internet Radio Linking Project)](http://www.irlp.net) yet, but I see no reason why it wouldn't work.  I have successfully used my [Wires-X](https://www.yaesu.com/jp/en/wires-x/index.php) nodes attached to my phones Hotspot feature.  I am also able to run multiple [Wires-X](https://www.yaesu.com/jp/en/wires-x/index.php) systems behind a single [NAT](https://en.wikipedia.org/wiki/Network_address_translation) router, which would otherwise be difficult and at the very least require two public IP addresses from the Internet service provider.

## Overview

This particular system was built on [Debian](https://www.debian.org) [Jesse](https://www.debian.org/releases/jessie/) deployed on [VMWare](http://www.vmware.com) vSphere infrastructure.  It time permits I will see if the same build instructions are useable on a [Raspberry Pi](https://www.raspberrypi.org).

Major moving parts of the project are provided by the community version of [OpenVPN](https://openvpn.net) and various standard Linux utilities.

The same system also provides connectivity to the [AMPRNet](https://www.ampr.org) IPIP tunnels mesh network.  The instructions on how I set this up are included as well.

## Prerequisites

This project requires access to some public IP addresses.  On the public facing side a public IP address is required.  Also a small subnet of public IP addresses is needed to provide to remote systems connecting to this gateway.  The port forwarding requirements mandate that each connecting system have its own dedicate public IP address.  This pool of public IP addresses needs to be routed to the gateway by the Internet service provider it is connected to.

## Installation

See the [installation](INSTALL.md) [guide](INSTALL.md) for all the gory details.

## Contributing

Any suggestions, comments, improvements are welcome.

## Authors

* **Adi Linden** - *Initial work* - [github/adilinden](https://github.com/adilinden)
