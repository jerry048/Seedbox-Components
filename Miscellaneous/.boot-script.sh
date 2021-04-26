#!/bin/sh

function boot_script {
	touch /etc/rc.local && chmod +x /etc/rc.local
	cat <<'EOF' > /etc/rc.local
#!/bin/sh
## Network
#NIC Config
interface=$(/sbin/ip -o -4 route show to default | awk '{print $5}')
/sbin/ethtool -G $interface rx 1024
sleep 1
/sbin/ethtool -G $interface tx 2048
sleep 1
/sbin/ethtool -K $interface tso off gso off
sleep 1
#Other 1
/sbin/ifconfig $interface txqueuelen 10000
sleep 1
#Other 2
iproute=$(/sbin/ip -o -4 route show to default)
/sbin/ip route change $iproute initcwnd 25 initrwnd 25
## Drive
#Scheduler
i=1
drive=()
disk=$(lsblk -nd --output NAME)
diskno=$(echo $disk | awk '{print NF}')
while [ $i -le $diskno ]
do
	device=$(echo $disk | awk -v i=$i '{print $i}')
	drive+=($device)
	i=$(( $i + 1 ))
done
i=1
x=0
disktype=$(cat /sys/block/sda/queue/rotational)
if [ "${disktype}" == 0 ]; then
	while [ $i -le $diskno ]
	do
		diskname=$(eval echo ${drive["$x"]})
		echo kyber > /sys/block/$diskname/queue/scheduler
		i=$(( $i + 1 ))
		x=$(( $x + 1 ))
	done
else
	while [ $i -le $diskno ]
	do
		diskname=$(eval echo ${drive["$x"]})
		echo mq-deadline > /sys/block/$diskname/queue/scheduler
		i=$(( $i + 1 ))
		x=$(( $x + 1 ))
	done
fi
clear
exit 0
EOF
}
