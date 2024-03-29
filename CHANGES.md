### v8.0.0 (2021-12-15)

* Deprecate this package, the module types are now defined by arp (>= 3.0.0),
  ethernet (>= 3.0.0) and tcpip (>= 7.0.0) (#30 @hannesm)

### v7.0.0 (2021-11-15)

* Remove Mirage_protocols_lwt module (#29 @hannesm)
* Remove mirage-device dependency (#29 @hannesm)

### v6.0.0 (2021-11-09)

Simplify UDP and TCP module types to set the stage for an alternative TCP stack,
and allow TCP and UDP to hold the listeners internally (instead of hiding them
in a Mirage_stack.S.

- Revise UDP module type:
   - removed type ipinput
   - add a val listen : t -> port:int -> callback -> unit
   - add a val unlisten : t -> port:int -> unit
   - val input is now: t -> src:ipaddr -> dst:ipaddr -> Cstruct.t -> unit Lwt.t
- Revise TCP module type
   - removed type ipinput
   - removed type listener
   - add a val listen : t -> port:int -> ?keepalive:Keepalive.t -> (flow -> unit Lwt.t) -> unit
   - add a val unlisten : t -> port:int -> unit
   - val input is now: t -> src:ipaddr -> dst:ipaddr -> Cstruct.t -> unit Lwt.t

In #28 by @hannesm

### v5.0.0 (2020-11-25)

- Retire ipv4_config type and DHCP_CLIENT module type (#27 @hannesm)
- Revise IP.mtu (used to be of type t -> int, now t -> dst:ipaddr -> int) to
  support dual stack (#27 @hannesm)
- Revise ICMP.write, now has ?src:ipaddr (#27 @hannesm)
- Revise UDP.write. now has ?src:ipaddr (#27 @hannesm)

### v4.0.1 (2019-11-04)

* provide deprecated Mirage_protocols_lwt for smooth transition (#25 @hannesm)

### v4.0.0 (2019-10-24)

- remove mirage-protocols-lwt (#23 @hannesm)
- specialise mirage-protocols to Lwt.t, Cstruct,t, Ipaddr.V4/V6.t, Macaddr.t (#23 @hannesm)
- raise lower OCaml bound to 4.06.0 (#23 @hannesm)

### v3.1.0 (2019-10-14)

- add polymorphic variant `Would_fragment to Ip.error (#20 @hannesm)
- extend ICMP.write and UDP.write with optional ttl:int argument (#21 @phaer)
- remove IP.set_ip (#20 @hannesm)

### v3.0.0 (2019-07-18)

- replace `uipaddr` with `pp_ipaddr`, since the only use is to print
  human-readable IP addresses (#18 @yomimono @linse)
- port to dune from jbuilder (#17 @hannesm)

### v2.0.0 (2019-02-24)

- Ethif/ETHIF renamed to Ethernet/ETHERNET (#16)
- Ethernet.proto defines a polymorphic variant of ethernet types (#15)
- Ip.proto defines a polymorphic variant of ip types (#15)
- Ethernet.writev is removed (#15)
- Ethernet.write expects an optional source mac address, a destination mac
  address, a protocol, an optional size and a fill function. Ethernet writes
  the Ethernet header to the buffer. (#15)
- Ip.writev and Ip.checksum are removed (#15)
- Ip.write expects an optional fragment, ttl, src, and a size and fill function,
  as well as a list of payload buffers. Size default to MTU. (#15)
- migrated build system to dune

### v1.4.1 (2019-01-10)

- ipaddr3 compatibility

### v1.4.0 (2018-09-15)

- remove unused types, since `connect` no longer in signatures (since Mirage3)
  `netif` from ETHIF
  `ethif` and `prefix` from IP
  `ip` from UDP and TCP

### v1.3.0 (2017-09-06)

- add support for TCP keepalives by changing the signature of the
  `TCP.input` function
- jbuilder is now a build dependency

### v1.2.0 (2017-06-15)

- port build to Jbuilder

### v1.1.0 (2016-03-02)

- require an mtu function in the ETHIF module type.

### v1.0.0 (2016-12-29)

- import ETHIF, ARP, IP, IPV4, IPV6, TCP, UDP, ICMP module types from mirage-types and mirage-types-lwt
