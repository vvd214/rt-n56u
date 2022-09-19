#!/bin/sh

change_dns() {
if [ "$(nvram get adg_redirect)" = 1 ]; then
sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
sed -i '/server=127.0.0.1/d' /etc/storage/dnsmasq/dnsmasq.conf
cat >> /etc/storage/dnsmasq/dnsmasq.conf << EOF
no-resolv
server=127.0.0.1#5335
EOF
/sbin/restart_dhcpd
logger -t "AdGuardHome" "Add DNS forwarding to port 5335"
fi
}
del_dns() {
sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
sed -i '/server=127.0.0.1#5335/d' /etc/storage/dnsmasq/dnsmasq.conf
/sbin/restart_dhcpd
}

set_iptable()
{
    if [ "$(nvram get adg_redirect)" = 2 ]; then
	IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
	for IP in $IPS
	do
		iptables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
		iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
	done

	IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
	for IP in $IPS
	do
		ip6tables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
		ip6tables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
	done
    logger -t "AdGuardHome" "Redirect port 53"
    fi
}

clear_iptable()
{
	OLD_PORT="5335"
	IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
	for IP in $IPS
	do
		iptables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
		iptables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
	done

	IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
	for IP in $IPS
	do
		ip6tables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
		ip6tables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
	done
	
}

getconfig(){
adg_file="/etc/storage/AdGuardHome.yaml"
if [ ! -f "$adg_file" ] || [ ! -s "$adg_file" ] ; then
	cat > "$adg_file" <<-\EEE
bind_host: 0.0.0.0
bind_port: 3030
auth_name: admin
auth_pass: admin
language: 
rlimit_nofile: 0
dns:
  bind_host: 0.0.0.0
  port: 5335
  protection_enabled: true
  filtering_enabled: true
  filters_update_interval: 24
  blocking_mode: nxdomain
  blocked_response_ttl: 10
  querylog_enabled: false
  ratelimit: 20
  ratelimit_whitelist: []
  refuse_any: true
  bootstrap_dns:
  - 9.9.9.10
  - 149.112.112.10
  - 2620:fe::10
  - 2620:fe::fe:10
  all_servers: true
  allowed_clients: []
  disallowed_clients: []
  blocked_hosts: []
  parental_sensitivity: 0
  parental_enabled: true
  safesearch_enabled: false
  safebrowsing_enabled: false
  resolveraddress: ""
  upstream_dns:
  - 9.9.9.10
  - 149.112.112.10
  - 2620:fe::10
  - 2620:fe::fe:10
tls:
  enabled: false
  server_name: ""
  force_https: false
  port_https: 443
  port_dns_over_tls: 853
  certificate_chain: ""
  private_key: ""
filters:
- enabled: true
  url: https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
  name: AdGuard DNS filter
  id: 1
- enabled: true
  url: https://adaway.org/hosts.txt
  name: AdAway Default Blocklist
  id: 2
- enabled: true
  url: https://abpvn.com/android/abpvn.txt
  name: ABVN
  id: 1643333073
- enabled: false
  url: https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt
  name: WindowsSpyBlocker - Hosts spy rules
  id: 1643333518
user_rules: []
dhcp:
  enabled: false
  interface_name: ""
  gateway_ip: ""
  subnet_mask: ""
  range_start: ""
  range_end: ""
  lease_duration: 86400
  icmp_timeout_msec: 1000
clients: []
log_file: ""
verbose: false
schema_version: 3

EEE
	chmod 755 "$adg_file"
fi
}



start_adg(){
	getconfig
	change_dns
	set_iptable
	logger -t "AdGuardHome" "Run AdGuardHome"

	if [ ! -d /tmp/AdGuardHome ] ; then
		mkdir -p /tmp/AdGuardHome
	fi

	eval "/usr/bin/AdGuardHome -c $adg_file -w /tmp/AdGuardHome --no-check-update" &

}
stop_adg(){
killall -9 AdGuardHome
del_dns
clear_iptable
}


case $1 in
start)
	start_adg
	;;
stop)
	stop_adg
	;;
*)
	echo "check"
	;;
esac
