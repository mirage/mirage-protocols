
module type ETHERNET = Ethernet.S
[@@ocaml.deprecated "Please use 'Ethernet.S' directly (and depend on ethernet >= 3.0.0)"]

module type ARP = Arp.S
[@@ocaml.deprecated "Please use 'Arp.S' directly (and depend on arp >= 3.0.0)"]

module type IP = Tcpip.Ip.S
[@@ocaml.deprecated "Please use 'Tcpip.Ip.S' directly (and depend on tcpip >= 7.0.0)"]

module type IPV4 = Tcpip.Ip.S with type ipaddr = Ipaddr.V4.t
[@@ocaml.deprecated "Please use 'Tcpip.Ip.S with type ipaddr = Ipaddr.V4.t' directly (and depend on tcpip >= 7.0.0)"]

module type IPV6 = Tcpip.Ip.S with type ipaddr = Ipaddr.V6.t
[@@ocaml.deprecated "Please use 'Tcpip.Ip.S with type ipaddr = Ipaddr.V6.t' directly (and depend on tcpip >= 7.0.0)"]

module type ICMP = Icmpv4.S
[@@ocaml.deprecated "Please use 'Tcpip.Icmpv4.S' directly (and depend on tcpip >= 7.0.0)"]

module type ICMPV4 = Icmpv4.S
[@@ocaml.deprecated "Please use 'Tcpip.Icmpv4.S' directly (and depend on tcpip >= 7.0.0)"]

module type UDP = Tcpip.Udp.S
[@@ocaml.deprecated "Please use 'Tcpip.Udp.S' directly (and depend on tcpip >= 7.0.0)"]

module type UDPV4 = Tcpip.Udp.S with type ipaddr = Ipaddr.V4.t
[@@ocaml.deprecated "Please use 'Tcpip.Udp.S with type ipaddr = Ipaddr.V4.t' directly (and depend on tcpip >= 7.0.0)"]

module type UDPV6 = Tcpip.Udp.S with type ipaddr = Ipaddr.V6.t
[@@ocaml.deprecated "Please use 'Tcpip.Udp.S with type ipaddr = Ipaddr.V6.t' directly (and depend on tcpip >= 7.0.0)"]

module type TCP = Tcpip.Tcp.S
[@@ocaml.deprecated "Please use 'Tcpip.Tcp.S' directly (and depend on tcpip >= 7.0.0)"]

module type TCPV4 = Tcpip.Tcp.S with type ipaddr = Ipaddr.V4.t
[@@ocaml.deprecated "Please use 'Tcpip.Tcp.S with type ipaddr = Ipaddr.V4.t' directly (and depend on tcpip >= 7.0.0)"]

module type TCPV6 = Tcpip.Tcp.S with type ipaddr = Ipaddr.V6.t
[@@ocaml.deprecated "Please use 'Tcpip.Tcp.S with type ipaddr = Ipaddr.V6.t' directly (and depend on tcpip >= 7.0.0)"]
