(** MirageOS signatures for network protocols

        {e %%VERSION%% } *)

(** {2 Ethernet layer} *)

(** Ethernet errors and protocols. *)
module Ethernet : sig
  type error = [ `Exceeds_mtu ]
  val pp_error: error Fmt.t

  type proto = [ `ARP | `IPv4 | `IPv6 ]
  val pp_proto: proto Fmt.t
end

(** Ethernet (IEEE 802.3) is a widely used data link layer. The hardware is
   usually a twisted pair or fibre connection, on the software side it consists
   of an Ethernet header where source and destination mac addresses, and a type
   field, indicating the type of the next layer, are present. The Ethernet layer
   consists of network card mac address and MTU information, and provides
   decapsulation and encapsulation. *)
module type ETHERNET = sig

  type error = private [> Ethernet.error]
  (** The type for ethernet interface errors. *)

  val pp_error: error Fmt.t
  (** [pp_error] is the pretty-printer for errors. *)

  include Mirage_device.S

  val write: t -> ?src:Macaddr.t -> Macaddr.t -> Ethernet.proto -> ?size:int ->
    (Cstruct.t -> int) -> (unit, error) result Lwt.t
  (** [write eth ~src dst proto ~size payload] outputs an ethernet frame which
     header is filled by [eth], and its payload is the buffer from the call to
     [payload]. [Payload] gets a buffer of [size] (defaults to mtu) to fill with
     their payload. If [size] exceeds {!mtu}, an error is returned. *)

  val mac: t -> Macaddr.t
  (** [mac eth] is the MAC address of [eth]. *)

  val mtu: t -> int
  (** [mtu eth] is the Maximum Transmission Unit of the [eth] i.e. the maximum
      size of the payload, excluding the ethernet frame header. *)

  val input:
    arpv4:(Cstruct.t -> unit Lwt.t) ->
    ipv4:(Cstruct.t -> unit Lwt.t) ->
    ipv6:(Cstruct.t -> unit Lwt.t) ->
    t -> Cstruct.t -> unit Lwt.t
  (** [input ~arpv4 ~ipv4 ~ipv6 eth buffer] decodes the buffer and demultiplexes
      it depending on the protocol to the callback. *)
end

(** {2 ARP} *)

(** Arp errors. *)
module Arp : sig
  type error = [ `Timeout ]
  val pp_error : error Fmt.t
end

(** Address resolution protocol, translating network addresses (e.g. IPv4)
    into link layer addresses (MAC). *)
module type ARP = sig
  include Mirage_device.S

  type error = private [> Arp.error]
  (** The type for ARP errors. *)

  val pp_error: error Fmt.t
  (** [pp_error] is the pretty-printer for errors. *)

  (** Prettyprint cache contents *)
  val pp : t Fmt.t

  (** [get_ips arp] gets the bound IP address list in the [arp]
      value. *)
  val get_ips : t -> Ipaddr.V4.t list

  (** [set_ips arp] sets the bound IP address list, which will transmit a
      GARP packet also. *)
  val set_ips : t -> Ipaddr.V4.t list -> unit Lwt.t

  (** [remove_ip arp ip] removes [ip] to the bound IP address list in
      the [arp] value, which will transmit a GARP packet for any remaining IPs in
      the bound IP address list after the removal. *)
  val remove_ip : t -> Ipaddr.V4.t -> unit Lwt.t

  (** [add_ip arp ip] adds [ip] to the bound IP address list in the
      [arp] value, which will transmit a GARP packet also. *)
  val add_ip : t -> Ipaddr.V4.t -> unit Lwt.t

  (** [query arp ip] queries the cache in [arp] for an ARP entry
      corresponding to [ip], which may result in the sender sleeping
      waiting for a response. *)
  val query : t -> Ipaddr.V4.t -> (Macaddr.t, error) result Lwt.t

  (** [input arp frame] will handle an ARP frame. If it is a response,
      it will update its cache, otherwise will try to satisfy the
      request. *)
  val input : t -> Cstruct.t -> unit Lwt.t
end

(** {2 IP layer} *)

(** IP errors and protocols. *)
module Ip : sig

  type error = [
    | `No_route of string (** can't send a message to that destination *)
    | `Would_fragment (** would need to fragment, but fragmentation is disabled *)
  ]

  val pp_error : error Fmt.t

  type proto = [ `TCP | `UDP | `ICMP ]
  val pp_proto: proto Fmt.t
end

(** An Internet Protocol (IP) layer reassembles IP fragments into packets,
   removes the IP header, and on the sending side fragments overlong payload
   and inserts IP headers. *)
module type IP = sig

  type error = private [> Ip.error]
  (** The type for IP errors. *)

  val pp_error: error Fmt.t
  (** [pp_error] is the pretty-printer for errors. *)

  type ipaddr
  (** The type for IP addresses. *)

  val pp_ipaddr : ipaddr Fmt.t
  (** [pp_ipaddr] is the pretty-printer for IP addresses. *)

  include Mirage_device.S

  type callback = src:ipaddr -> dst:ipaddr -> Cstruct.t -> unit Lwt.t
  (** An input continuation used by the parsing functions to pass on
      an input packet down the stack.

      [callback ~src ~dst buf] will be called with [src] and [dst]
      containing the source and destination IP address respectively,
      and [buf] will be a buffer pointing at the start of the IP
      payload. *)

  val input:
    t ->
    tcp:callback -> udp:callback -> default:(proto:int -> callback) ->
    Cstruct.t -> unit Lwt.t
  (** [input ~tcp ~udp ~default ip buf] demultiplexes an incoming
      [buffer] that contains an IP frame. It examines the protocol
      header and passes the result onto either the [tcp] or [udp]
      function, or the [default] function for unknown IP protocols. *)

  val write: t -> ?fragment:bool -> ?ttl:int ->
    ?src:ipaddr -> ipaddr -> Ip.proto -> ?size:int -> (Cstruct.t -> int) ->
    Cstruct.t list -> (unit, error) result Lwt.t
  (** [write t ~fragment ~ttl ~src dst proto ~size headerf payload] allocates a
     buffer, writes the IP header, and calls the headerf function. This may
     write to the provided buffer of [size] (default 0). If [size + ip header]
     exceeds the maximum transfer unit, an error is returned. The [payload] is
     appended. The optional [fragment] argument defaults to [true], in which
     case multiple IP-fragmented frames are sent if the payload is too big for a
     single frame. When it is [false], the don't fragment bit is set and if the
     payload and header would exceed the maximum transfer unit, an error is
     returned. *)

  val pseudoheader : t -> ?src:ipaddr -> ipaddr -> Ip.proto -> int -> Cstruct.t
  (** [pseudoheader t ~src dst proto len] gives a pseudoheader suitable for use in
      TCP or UDP checksum calculation based on [t]. *)

  val src: t -> dst:ipaddr -> ipaddr
  (** [src ip ~dst] is the source address to be used to send a
      packet to [dst].  In the case of IPv4, this will always return
      the same IP, which is the only one set. *)

  val get_ip: t -> ipaddr list
  (** Get the IP addresses associated with this interface. For IPv4, only
      one IP address can be set at a time, so the list will always be of
      length 1 (and may be the default value, 0.0.0.0). *)

  val mtu: t -> int
  (** [mtu ip] is the Maximum Transmission Unit of the [ip] i.e. the maximum
      size of the payload, not including the IP header. *)
end

(** IPv4 layer *)
module type IPV4 = IP with type ipaddr = Ipaddr.V4.t

(** IPv6 layer *)
module type IPV6 = IP with type ipaddr = Ipaddr.V6.t

(* No Icmp module, as there are no exposed error polymorphic variants *)

(** {2 ICMP layer} *)

(** Internet Control Message Protocol: error messages and operational
    information. *)
module type ICMP = sig
  include Mirage_device.S

  type ipaddr
  (** The type for IP addresses. *)

  type error (* entirely abstract since we expose none in an Icmp module *)
  (** The type for ICMP errors. *)

  val pp_error: error Fmt.t
  (** [pp_error] is the pretty-printer for errors. *)

  val input : t -> src:ipaddr -> dst:ipaddr -> Cstruct.t -> unit Lwt.t
  (** [input t src dst buffer] reacts to the ICMP message in
      [buffer]. *)

  val write : t -> dst:ipaddr -> ?ttl:int -> Cstruct.t -> (unit, error) result Lwt.t
  (** [write t dst ~ttl buffer] sends the ICMP message in [buffer] to [dst]
      over IP. Passes the time-to-live ([ttl]) to the IP stack if given. *)
end

(** ICMPv4 layer *)
module type ICMPV4 = ICMP with type ipaddr = Ipaddr.V4.t

(** ICMPv6 layer *)
module type ICMPV6 = ICMP with type ipaddr = Ipaddr.V6.t

(** {2 UDP layer} *)

(* No Udp module, as there are no exposed error polymorphic variants *)

(** User datagram protocol layer: connectionless message-oriented
    communication. *)
module type UDP = sig

  type error (* entirely abstract since we expose none in a Udp module *)
  (** The type for UDP errors. *)

  val pp_error: error Fmt.t
  (** [pp] is the pretty-printer for errors. *)

  type ipaddr
  (** The type for an IP address representations. *)

  type ipinput
  (** The type for input function continuation to pass onto the
      underlying {!IP} layer. This will normally be a NOOP for a
      conventional kernel, but a direct implementation will parse the
      buffer. *)

  include Mirage_device.S

  type callback = src:ipaddr -> dst:ipaddr -> src_port:int -> Cstruct.t -> unit Lwt.t
  (** The type for callback functions that adds the UDP metadata for
      [src] and [dst] IP addresses, the [src_port] of the connection
      and the [buffer] payload of the datagram. *)

  val input: listeners:(dst_port:int -> callback option) -> t -> ipinput
  (** [input listeners t] demultiplexes incoming datagrams based on
      their destination port.  The [listeners] callback will either
      return a concrete handler or a [None], which results in the
      datagram being dropped. *)

  val write: ?src_port:int -> ?ttl:int -> dst:ipaddr -> dst_port:int -> t -> Cstruct.t ->
    (unit, error) result Lwt.t
  (** [write ~src_port ~ttl ~dst ~dst_port udp data] is a task
      that writes [data] from an optional [src_port] to a [dst]
      and [dst_port] IP address pair. An optional time-to-live ([ttl]) is passed
      through to the IP layer. *)

end

(** UDPv4 layer *)
module type UDPV4 = UDP with type ipaddr = Ipaddr.V4.t

(** UDPv6 layer *)
module type UDPV6 = UDP with type ipaddr = Ipaddr.V6.t

(** {2 TCP layer} *)

(** TCP errors. *)
module Tcp : sig
  type error = [ `Timeout | `Refused]
  type write_error = [ error | Mirage_flow.write_error ]

  val pp_error : error Fmt.t
  val pp_write_error : write_error Fmt.t
end

(** Configuration for TCP keep-alives.
    Keep-alive messages are probes sent on an idle connection. If no traffic
    is received after a certain number of probes are sent, then the connection
    is assumed to have been lost. *)
module Keepalive: sig
  type t = {
    after: Duration.t;    (** initial delay before sending probes on an idle
                              connection *)
    interval: Duration.t; (** interval between successive probes *)
    probes: int;          (** total number of probes to send before assuming
                              that, if the connection is still idle it has
                              been lost *)
  }
  (** Configuration for TCP keep-alives *)
end

(** Transmission Control Protocol layer: reliable ordered streaming
    communication. *)
module type TCP = sig

  type error = private [> Tcp.error]
  (** The type for TCP errors. *)

  type write_error = private [> Tcp.write_error]
  (** The type for TCP write errors. *)

  type ipaddr
  (** The type for IP address representations. *)

  type ipinput
  (** The type for input function continuation to pass onto the
      underlying {!IP} layer. This will normally be a NOOP for a
      conventional kernel, but a direct implementation will parse the
      buffer. *)

  type flow
  (** A flow represents the state of a single TCPv4 stream that is connected
      to an endpoint. *)

  include Mirage_device.S

  include Mirage_flow.S with
      type flow   := flow
  and type error  := error
  and type write_error := write_error

  val dst: flow -> ipaddr * int
  (** Get the destination IPv4 address and destination port that a
      flow is currently connected to. *)

  val write_nodelay: flow -> Cstruct.t -> (unit, write_error) result Lwt.t
  (** [write_nodelay flow buffer] writes the contents of [buffer]
      to the flow. The thread blocks until all data has been successfully
      transmitted to the remote endpoint.
      Buffering within the layer is minimized in this mode.
      Note that this API will change in a future revision to be a
      per-flow attribute instead of a separately exposed function. *)

  val writev_nodelay: flow -> Cstruct.t list -> (unit, write_error) result Lwt.t
  (** [writev_nodelay flow buffers] writes the contents of [buffers]
      to the flow. The thread blocks until all data has been successfully
      transmitted to the remote endpoint.
      Buffering within the layer is minimized in this mode.
      Note that this API will change in a future revision to be a
      per-flow attribute instead of a separately exposed function. *)

  val create_connection: ?keepalive:Keepalive.t -> t -> ipaddr * int -> (flow, error) result Lwt.t
  (** [create_connection ~keepalive t (addr,port)] opens a TCPv4 connection
      to the specified endpoint.

      If the optional argument [?keepalive] is provided then TCP keep-alive
      messages will be sent to the server when the connection is idle. If
      no responses are received then eventually the connection will be disconnected:
      [read] will return [Ok `Eof] and write will return [Error `Closed] *)

  type listener = {
    process: flow -> unit Lwt.t; (** process a connected flow *)
    keepalive: Keepalive.t option; (** optional TCP keepalive configuration *)
  }
  (** A TCP listener on a particular port *)

  val input: t -> listeners:(int -> listener option) -> ipinput
  (** [input t listeners] returns an input function continuation to be
      passed to the underlying {!IP} layer.

      When the layer receives a TCP SYN (i.e. a connection request) to a
      particular [port], it will evaluate [listeners port]:

      - If [listeners port] is [None], the input function will return an RST
        to refuse the connection.
      - If [listeners port] is [Some listener] then the connection will be
        accepted and the resulting flow will be processed by [listener.process].
        If [listener.keepalive] is [Some configuration] then the TCP keep-alive
        [configuration] will be applied before calling [listener.process].
  *)
end

(** TCPv4 layer *)
module type TCPV4 = TCP with type ipaddr = Ipaddr.V4.t

(** TCPv6 layer *)
module type TCPV6 = TCP with type ipaddr = Ipaddr.V6.t

(** {2 DHCP client} *)

(** IPv4 Configuration *)
type ipv4_config = {
  address : Ipaddr.V4.t;
  network : Ipaddr.V4.Prefix.t;
  gateway : Ipaddr.V4.t option;
}

(** Dynamic host configuration protocol: a client engaging in lease
    transactions. *)
module type DHCP_CLIENT = sig
  type t = ipv4_config Lwt_stream.t
end
