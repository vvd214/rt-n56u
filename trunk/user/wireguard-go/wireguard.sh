#!/bin/sh
sleep 5 ;
IFACE="wg0"
ADDR="10.127.0.1"
MASK="24"
if [ "`nvram get wan_proto`" = "pppoe" ]; then
  WAN="ppp0"
else
  WAN="`nvram get wan_ifname`"
fi


cfg_file="/etc/storage/wireguard.conf"

if [ ! -f "$cfg_file" ] || [ ! -s "$cfg_file" ] ; then
	cat > "$cfg_file" <<-\EEE
[Interface]
ListenPort = 55551
PrivateKey = iBgjJQutq3JUpixs8Su25YS4Jd5SDlYLxgaJAvy4rm4=

[Peer]
PublicKey = UrnVAkJLr/n4FzGdX4XUo/MOscnG5CRwws8Z0ZP9mhM=
AllowedIPs = 10.127.0.2/32

[Peer]
PublicKey = gjxr2Lf0AkX5jzlBACklKVG0VSFJu8a1xe4XoVJiVBU=
AllowedIPs = 10.127.0.3/32

[Peer]
PublicKey = fsEWNFdxxJhzZiWgKMqST2/7FYm7hcmVmzTiJGSYOg4=
AllowedIPs = 10.127.0.4/32

[Peer]
PublicKey = dGdWjXT7PSutgNawJ5P0e6+l9jm07KnzgmYxd1EKEUQ=
AllowedIPs = 10.127.0.5/32

[Peer]
PublicKey = fgR1hK6+SpX7NHrORj38Coy1/ICTEWsTXn3RwYY4gRw=
AllowedIPs = 10.127.0.6/32

EEE
fi
	(killall wireguard ; sleep 1 ; wireguard wg0  2>/dev/null) && \
	(ip link show ${IFACE} 2>/dev/null) && \
	(ip addr add ${ADDR}/${MASK} dev ${IFACE}) && \
	(wg setconf ${IFACE} $cfg_file) && \
	(sleep 1) && \
	(ip link set ${IFACE} up)

ifconfig ${IFACE}

echo 1 > /proc/sys/net/ipv4/ip_forward
echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects

iptables -I INPUT -i ${WAN} -p udp -m udp --dport 55551 -j ACCEPT
iptables -I INPUT -i ${IFACE} -j ACCEPT
iptables -I FORWARD -i ${IFACE} -o ${IFACE} -j ACCEPT
iptables -I FORWARD -i ${IFACE} -o br0 -j ACCEPT
iptables -I FORWARD -i br0 -o ${IFACE} -j ACCEPT

iptables -I FORWARD -i ${IFACE} -o ${WAN} -j ACCEPT
iptables -I FORWARD -i ${WAN} -o ${IFACE} -j ACCEPT

iptables -t nat -A POSTROUTING -s 10.127.0.0/24 -o ${WAN} -j MASQUERADE

/bin/ip route add 10.127.0.0/24 dev wg0

