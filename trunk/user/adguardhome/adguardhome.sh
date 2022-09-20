#!/bin/sh
SVC_PRIORITY=99
SVC_NAME="AdGuardHome"
WORK_DIR="/tmp/AdGuardHome"
SVC_PATH="/usr/bin/AdGuardHome"
LOG_FILE="syslog"

count=0
while :
do
	ping -c 1 -W 1 -q 8.8.8.8 1>/dev/null 2>&1
	if [ "$?" == "0" ]; then
		break
	fi
	sleep 5
	count=$((count+1))
	if [ $count -gt 18 ]; then
		break
	fi
done

getconfig(){
adg_file="/etc/storage/AdGuardHome.yaml"
if [ ! -f "$adg_file" ] || [ ! -s "$adg_file" ] ; then
	cat > "$adg_file" <<-\EEE
bind_host: 0.0.0.0
bind_port: 3000
auth_name: admin
auth_pass: admin
language: 
rlimit_nofile: 0
dns:
  bind_host: 0.0.0.0
  port: 53
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
  parental_enabled: false
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


	if [ "$(nvram get EnableAGH)" = 1 ]; then
		if grep -q "^#port=0$" /etc/storage/dnsmasq/dnsmasq.conf; then
			sed -i '/port=0/s/^#//g' /etc/storage/dnsmasq/dnsmasq.conf
			/sbin/restart_dhcpd
		else
			if grep -q "^port=0$" /etc/storage/dnsmasq/dnsmasq.conf; then
				true
			else
				echo "port=0" >> /etc/storage/dnsmasq/dnsmasq.conf
				/sbin/restart_dhcpd
			fi
		fi

getconfig

	if [ ! -d /tmp/AdGuardHome ] ; then
		mkdir -p /tmp/AdGuardHome
	fi
	start-stop-daemon -S -b -N $SVC_PRIORITY -x $SVC_PATH -- -w "$WORK_DIR" -c $adg_file -l "$LOG_FILE" --no-check-update
	logger -t "AdGuardHome" "Start AdGuardHome"

else
			if grep -q "^port=0$" /etc/storage/dnsmasq/dnsmasq.conf; then
				sed -i '/port=0/s/^/#/g' /etc/storage/dnsmasq/dnsmasq.conf
				/sbin/restart_dhcpd
			else
				true
			fi
logger -t "AdGuardHome" "Stop AdGuardHome"
killall -9 AdGuardHome
fi

