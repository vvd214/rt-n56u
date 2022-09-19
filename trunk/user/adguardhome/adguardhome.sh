#!/bin/sh

#######################################################################
# (1) run process from superuser root (less security)
# (0) run process from unprivileged user "nobody" (more security)
SVC_ROOT=1

# process priority (0-normal, 19-lowest)
SVC_PRIORITY=5
#######################################################################

SVC_NAME="AdGuardHome"
SVC_PATH="/usr/bin/AdGuardHome"
WORK_DIR="/tmp/AdGuardHome"
DIR_CONF="/etc/storage/AdGuardHome.yaml"
adg_port=3000
	
LOG_FILE="syslog"

func_start()
{
	if [ -n "`pidof AdGuardHome`" ] ; then
		return 0
	fi

	echo -n "Starting $SVC_NAME:."
	
	replace_dnsmasq=1
	
	if [ $replace_dnsmasq -eq 1 ] ; then
		if grep -q "^#port=0$" /etc/storage/dnsmasq/dnsmasq.conf; then
			sed -i '/port=0/s/^#//g' /etc/storage/dnsmasq/dnsmasq.conf
		else
			if grep -q "^port=0$" /etc/storage/dnsmasq/dnsmasq.conf; then
				true
			else
				echo "port=0" >> /etc/storage/dnsmasq/dnsmasq.conf
			fi
		fi
		killall dnsmasq
	fi

	if [ ! -d "${WORK_DIR}" ] ; then
		mkdir -p "${WORK_DIR}"
	fi

	if [ $SVC_ROOT -eq 0 ] ; then
		chmod 777 "${WORK_DIR}"
		svc_user=" -c nobody"
	fi
	lan_ipaddr=`nvram get lan_ipaddr`

	start-stop-daemon -S -b -N $SVC_PRIORITY$svc_user -x $SVC_PATH -- -w "$WORK_DIR" -c "$DIR_CONF" -l "$LOG_FILE" -h "$lan_ipaddr" -p "$adg_port" --no-check-update
	
	if [ $? -eq 0 ] ; then
		echo "[  OK  ]"
		logger -t "$SVC_NAME" "daemon is started"
	else
		echo "[FAILED]"
	fi
}

func_stop()
{
	# Make sure not running
	if [ -z "`pidof AdGuardHome`" ] ; then
		return 0
	fi
	
	echo -n "Stopping $SVC_NAME:."
	
	# stop daemon
	killall -q AdGuardHome
	
	# gracefully wait max 25 seconds while AGH stop
	i=0
	while [ -n "`pidof AdGuardHome`" ] && [ $i -le 25 ] ; do
		echo -n "."
		i=$(( $i + 1 ))
		sleep 1
	done
	
	tr_pid=`pidof AdGuardHome`
	if [ -n "$tr_pid" ] ; then
		# force kill (hungup?)
		kill -9 "$tr_pid"
		sleep 1
		echo "[KILLED]"
		logger -t "$SVC_NAME" "Cannot stop: Timeout reached! Force killed."
	else
		echo "[  OK  ]"
	fi

	restart_dnsmasq=1
	if [ $restart_dnsmasq -eq 1 ] ; then
		if grep -q "^port=0$" /etc/storage/dnsmasq/dnsmasq.conf; then
			sed -i '/port=0/s/^/#/g' /etc/storage/dnsmasq/dnsmasq.conf
		fi
		killall dnsmasq
	fi
}

case "$1" in
start)
	func_start
	;;
stop)
	func_stop
	;;
restart)
	func_stop
	func_start
	;;
*)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
	;;
esac
