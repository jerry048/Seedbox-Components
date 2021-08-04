#!/bin/sh

## CPU
function CPU_Tweaking {
    normal_1; echo "Optimizing CPU"; normal_2
    apt-get -qqy install tuned
    warn_2
    mkdir /etc/tuned/profile
    touch /etc/tuned/profile/tuned.conf
    cat << EOF >/etc/tuned/profile/tuned.conf
[main]
#CPU & Scheduler Optimization
[cpu]
governor=performance
energy_perf_bias=performance
min_perf_pct=100

[disk]
readahead=4096

[bootloader]
cmdline=skew_tick=1
EOF

    tuned-adm profile profile
}


## Network
#NIC Config
function NIC_Tweaking {
    normal_1; echo "Optimizing NIC Configuration"
    warn_1; echo "Some Configurations might not be supported by the NIC"; warn_2
    interface=$(ip -o -4 route show to default | awk '{print $5}')
    ethtool -G $interface rx 1024
    sleep 1
    ethtool -G $interface tx 2048
    sleep 1
    ethtool -K $interface tso off gso off
    sleep 1
}
function Network_Other_Tweaking {
    normal_1; echo "Doing other Network Tweaking"; warn_2
    #Other 1
    apt-get -qqy install net-tools
    ifconfig $interface txqueuelen 10000
    sleep 1
    #Other 2
    iproute=$(ip -o -4 route show to default)
    ip route change $iproute initcwnd 25 initrwnd 25
}


## Drive
#Scheduler
function Scheduler_Tweaking {
    normal_1; echo "Changing I/O Scheduler"; warn_2
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
}


## File Open Limit
function file_open_limit_Tweaking {
    normal_1; echo "Configuring File Open Limit"; warn_2
    cat << EOF >>/etc/security/limits.conf
## Hard limit for max opened files
$username        hard nofile 1048576
## Soft limit for max opened files
$username        soft nofile 1048576
EOF
}


## sysctl.conf
function kernel_Tweaking {
    normal_1; echo "Configuring sysctl.conf"; warn_2
    cat << EOF >/etc/sysctl.conf
###/proc/sys/kernel/ Variables:
##https://www.kernel.org/doc/Documentation/admin-guide/sysctl/kernel.rst

# Allow for more PIDs
kernel.pid_max = 4194303

# Maximum size of an IPC queue
kernel.msgmnb = 65536

# maximum size of an IPC message
kernel.msgmax = 65536

## Process Scheduler Optimization
kernel.sched_migration_cost_ns = 5000000
kernel.sched_autogroup_enabled = 0
kernel.sched_min_granularity_ns = 10000000
kernel.sched_wakeup_granularity_ns = 15000000





###/proc/sys/fs/
##https://www.kernel.org/doc/Documentation/admin-guide/sysctl/fs.rst

# Maximum number of file-handles that the Linux kernel will allocate
fs.file-max = 1048576

# Maximum number of file-handles a process can allocate
fs.nr_open = 1048576








###/proc/sys/vm Variables:
##https://www.kernel.org/doc/Documentation/admin-guide/sysctl/vm.rst

# Percentage of available system memory which when dirty then system can start writing data to the disks
# NOTE: The total available memory is not equal to total system memory
vm.dirty_background_ratio = 5
# Percentage of available system memory which when dirty, the process doing writes would block and write out dirty pages to the disks
vm.dirty_ratio = 30

# Define when dirty inode is old enough to be eligible for writeback by the kernel flusher threads & interval to wakeup dirtytime_writeback thread
vm.dirty_expire_centisecs = 1000
# Period between each wake up and write old data out to disk
vm.dirty_writeback_centisecs = 100

# Reduce swapping and keep memory pages in physical memory
vm.swappiness = 10

# Approaches to reclaim memory when a zone runs out of memory
# Disabled on workload that benefit from having their data cached
# Enable on workload that is partitioned such that each partition fits within a NUMA node and that accessing remote memory would cause a measurable performance reduction
# Walkserver enables it
# vm.zone_reclaim_mode = 1








###/proc/sys/net/core - Network core options:
##https://www.kernel.org/doc/Documentation/admin-guide/sysctl/net.rst


# NOTE: Difference in polling and interrupt
#		-Interrupt: Interrupt is a hardware mechanism in which, the device notices the CPU that it requires its attention./
#			Interrupt can take place at any time. So when CPU gets an interrupt signal trough the indication interrupt-request line,/
#			CPU stops the current process and respond to the interrupt by passing the control to interrupt handler which services device.
#	    -Polling: In polling is not a hardware mechanism, its a protocol in which CPU steadily checks whether the device needs attention./
#			Wherever device tells process unit that it desires hardware processing, #in polling process unit keeps asking the I/O device whether or not it desires CPU processing./
#			The CPU ceaselessly check every and each device hooked up thereto for sleuthing whether or not any device desires hardware attention.
#	    The Linux kernel uses the interrupt-driven mode by default and only switches to polling mode when the flow of incoming packets exceeds "net.core.dev_weight" number of data frames
# The maximum number of packets that kernel can handle on a NAPI interrupt, it's a Per-CPU variable
#net.core.dev_weight = 64
# Scales the maximum number of packets that can be processed during a RX softirq cycle. Calculation is based on dev_weight (dev_weight * dev_weight_rx_bias)
#net.core.dev_weight_rx_bias = 1
# Scales the maximum number of packets that can be processed during a TX softirq cycle. Calculation is based on dev_weight (dev_weight * dev_weight_tx_bias)
#net.core.dev_weight_tx_bias = 1

# NOTE: If the second column of "cat /proc/net/softnet_stat" is huge, there are frame drops and it might be wise to increase the value of net.core.netdev_max_backlog/
#If the third column increases, there are SoftIRQ Misses and it might be wise to increase either or both net.core.netdev_budget and net.core.netdev_budget_usecs
# Maximum number of packets taken from all interfaces in one polling cycle (NAPI poll).
net.core.netdev_budget = 50000
# Maximum number of microseconds in one polling cycle (NAPI poll).
# NOTE: Could reduce if you have a CPU with high single core performance, NIC that supports RSS
# NOTE: Setting a high number might cause CPU to stall and end in poor overall performance
net.core.netdev_budget_usecs = 8000
# Maximum number  of  packets,  queued  on  the  INPUT  side, when the interface receives packets faster than kernel can process them
net.core.netdev_max_backlog = 100000

# Low latency busy poll timeout for socket reads
# NOTE: Not supported by most NIC
#net.core.busy_read=50
# Low latency busy poll timeout for poll and select
# NOTE: Not supported by most NIC
#net.core.busy_poll=50


# Receive socket buffer size
net.core.rmem_default = 16777216
net.core.rmem_max = 67108864

# Send socket buffer size
net.core.wmem_default = 16777216
net.core.wmem_max = 67108864

# Maximum ancillary buffer size allowed per socket
net.core.optmem_max = 4194304








###/proc/sys/net/ipv4/* Variables:
##https://www.kernel.org/doc/Documentation/networking/ip-sysctl.rst

## Routing Settings
# Time, in seconds, that cached PMTU information is kept
net.ipv4.route.mtu_expires = 1800

# Lowest possible mss setting, actuall advertised MSS depends on the first hop route MTU
net.ipv4.route.min_adv_mss = 536

# Set PMTU to this value if fragmentation-required ICMP is received for that destination
# NOTE: Only necessary if "net.ipv4.ip_no_pmtu_disc" is set to mode 1
#net.ipv4.route.min_pmtu = 1500




## IP
# System IP port limits
net.ipv4.ip_local_port_range = 1024 65535

# Allow Path MTU Discovery
net.ipv4.ip_no_pmtu_disc = 0




## ARP table settings
# The maximum number of bytes which may be used by packets queued for each unresolved address by other network layers
net.ipv4.neigh.default.unres_qlen_bytes = 16777216

# The maximum number of packets which may be queued for each unresolved address by other network layers
# NOTE: Deprecated in Linux 3.3 : use unres_qlen_bytes instead
#net.ipv4.neigh.default.unres_qlen = 1024




## TCP variables
# Maximum queue length of completely established sockets waiting to be accepted
net.core.somaxconn = 500000

#Maximum queue length of incomplete sockets i.e. half-open connection
#NOTE: THis value should not be above "net.core.somaxconn", since that is also a hard open limit of maximum queue length of incomplete sockets/
#Kernel will take the lower one out of two as the maximum queue length of incomplete sockets
net.ipv4.tcp_max_syn_backlog = 500000

# Recover and handle all requests instead of resetting them when system is overflowed with a burst of new connection attempts
net.ipv4.tcp_abort_on_overflow = 0

# Maximal number of TCP sockets not attached to any user file handle (i.e. orphaned connections), held by system.
# NOTE: each orphan eats up to ~64K of unswappable memory
net.ipv4.tcp_max_orphans = 262144

# Maximal number of time-wait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 10000


# Enable Path MTU Discovery, and use initial MSS of tcp_base_mss
net.ipv4.tcp_mtu_probing = 2

# Starting MSS used in Path MTU discovery
net.ipv4.tcp_base_mss = 1460

#  Minimum MSS used in connection, cap it to this value even if advertised ADVMSS option is even lower
net.ipv4.tcp_min_snd_mss = 536


# Enable select acknowledgments 
net.ipv4.tcp_sack = 1
# Send SACK more frequently
net.ipv4.tcp_comp_sack_delay_ns = 2500000
# Reduce SACK that can be compressed
net.ipv4.tcp_comp_sack_nr = 10

# Allows TCP to send "duplicate" SACKs
net.ipv4.tcp_dsack = 1

# Enable Early Retransmit. ER lowers the threshold for triggering fast retransmit when the amount of outstanding data is small and when no previously unsent data can be transmitted
# Default Value
#net.ipv4.tcp_early_retrans = 3

# Disable ECN totally
net.ipv4.tcp_ecn = 0

# Enable Forward Acknowledgment
# NOTE: This is a legacy option, it has no effect anymore
# net.ipv4.tcp_fack = 1


# TCP buffer size
# Values are measured in memory pages. Size of memory pages can be found by "getconf PAGESIZE". Normally it is 4096 bytes
# Vector of 3 INTEGERs: min, pressure, max
#	min: below this number of pages TCP is not bothered about its
#	memory appetite.
#
#	pressure: when amount of memory allocated by TCP exceeds this number
#	of pages, TCP moderates its memory consumption and enters memory
#	pressure mode, which is exited when memory consumption falls
#	under "min".
#
#	max: number of pages allowed for queuing by all TCP sockets
net.ipv4.tcp_mem = 262144 1572864 2097152

# TCP sockets receive buffer
# Vector of 3 INTEGERs: min, default, max
#	min: Minimal size of receive buffer used by TCP sockets.
#	It is guaranteed to each TCP socket, even under moderate memory
#	pressure.
#
#	default: initial size of receive buffer used by TCP sockets.
#	This value overrides net.core.rmem_default used by other protocols.
#
#	max: maximal size of receive buffer allowed for automatically
#	selected receiver buffers for TCP socket. This value does not override
#	net.core.rmem_max.  Calling setsockopt() with SO_RCVBUF disables
#	automatic tuning of that socket's receive buffer size, in which
#	case this value is ignored.
net.ipv4.tcp_rmem = 4194304 16777216 67108864

# Disable receive buffer auto-tuning
net.ipv4.tcp_moderate_rcvbuf = 0

# Distribution of socket receive buffer space between TCP window size(this is the size of the receive window advertised to the other end), and application buffer/
#The overhead (application buffer) is counted as bytes/2^tcp_adv_win_scale i.e. Setting this 2 would mean we use 1/4 of socket buffer space as overhead
# NOTE: Overhead reduces the effective window size, which in turn reduces the maximum possible data in flight which is window size*RTT
# NOTE: Overhead helps isolating the network from scheduling and application  latencies
net.ipv4.tcp_adv_win_scale = 2

# Max reserved byte of TCP window for application buffer. The value will be between window/2^tcp_app_win and mss
# See "https://www.programmersought.com/article/75001203063/" for more detail about tcp_app_win & tcp_adv_win_scale
# NOTE: This application buffer is different from the one assigned by tcp_adv_win_scale
# Default
#net.ipv4.tcp_app_win = 31

# TCP sockets send buffer
# Vector of 3 INTEGERs: min, default, max
#	min: Amount of memory reserved for send buffers for TCP sockets.
#	Each TCP socket has rights to use it due to fact of its birth.
#
#	default: initial size of send buffer used by TCP sockets.  This
#	value overrides net.core.wmem_default used by other protocols.
#	It is usually lower than net.core.wmem_default.
#
#	max: Maximal amount of memory allowed for automatically tuned
#	send buffers for TCP sockets. This value does not override
#	net.core.wmem_max.  Calling setsockopt() with SO_SNDBUF disables
#	automatic tuning of that socket's send buffer size, in which case
#	this value is ignored.
net.ipv4.tcp_wmem = 4194304 16777216 67108864


# Reordering level of packets in a TCP stream
# NOTE: Reordering is costly but it happens quite a lot. Instead of declaring packet lost and requiring retransmit, try harder to reorder first
# Initial reordering level of packets in a TCP stream. TCP stack can then dynamically adjust flow reordering level between this initial value and tcp_max_reordering
net.ipv4.tcp_reordering = 10
# Maximal reordering level of packets in a TCP stream
net.ipv4.tcp_max_reordering = 600


# Number of times SYNACKs for a passive TCP connection attempt will be retransmitted
net.ipv4.tcp_synack_retries = 10
# Number of times initial SYNs for an active TCP connection attempt	will be retransmitted
net.ipv4.tcp_syn_retries = 7

# In seconds, time default value for connections to keep alive
net.ipv4.tcp_keepalive_time = 7200
# How many keepalive probes TCP sends out, until it decides that the connection is broken
net.ipv4.tcp_keepalive_probes = 15
# In seconds, how frequently the probes are send out
net.ipv4.tcp_keepalive_intvl = 60

# Number of retries before killing a TCP connection
# Time, after which TCP decides, that something is wrong due to unacknowledged RTO retransmissions,	and reports this suspicion to the network layer.
net.ipv4.tcp_retries1 = 3
# Time, after which TCP decides to timeout the TCP connection, when RTO retransmissions remain unacknowledged
net.ipv4.tcp_retries2 = 10

# How many times to retry to kill connections on the other side before killing it on our own side
net.ipv4.tcp_orphan_retries = 2

#Disable TCP auto corking, as it needlessly increasing latency when the application doesn't expect to send more data
net.ipv4.tcp_autocorking = 0

# Disables Forward RTO-Recovery, since we are not operating on a lossy wireless network
net.ipv4.tcp_frto = 0

# Protect Against TCP TIME-WAIT Assassination
net.ipv4.tcp_rfc1337 = 1

# Avoid falling back to slow start after a connection goes idle
net.ipv4.tcp_slow_start_after_idle = 0

# Enable both client support & server support of TCP Fast Open
net.ipv4.tcp_fastopen = 3

# Disable timestamps
net.ipv4.tcp_timestamps = 0

# Keep sockets in the state FIN-WAIT-2 for ultra short period if we were the one closing the socket, because this gives us no benefit and eats up memory
net.ipv4.tcp_fin_timeout = 5

# Do not cache metrics on closing connections
net.ipv4.tcp_no_metrics_save = 1

# Enable reuse of TIME-WAIT sockets for new connections
net.ipv4.tcp_tw_reuse = 1


# Allows the use of a large window (> 64 kB) on a TCP connection
net.ipv4.tcp_window_scaling = 1

# Set maximum window size to MAX_TCP_WINDOW i.e. 32767 in times there is no received window scaling option
net.ipv4.tcp_workaround_signed_windows = 1


# The maximum amount of unsent bytes in TCP socket write queue
net.ipv4.tcp_notsent_lowat = 983040

# Controls the amount of data in the Qdisc queue or device queue
net.ipv4.tcp_limit_output_bytes = 3276800

# Controls a per TCP socket cache of one socket buffer
# Use Huge amount of memory
#net.ipv4.tcp_rx_skb_cache = 1

# Congestion Control
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
    sysctl -p > /dev/null
}


## BBR
function Tweaked_BBR {
    ## Update Kernel
    normal_1; echo "Updating Kernel"; normal_2
    echo "deb http://deb.debian.org/debian buster-backports main" | sudo tee -a /etc/apt/sources.list
    apt-get -qqy update && apt-get -qqy install linux-image-5.10.0-0.bpo.8-amd64
    ## Install tweaked BBR automatically on reboot
    wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Miscellaneous/BBR/BBR.sh && chmod +x BBR.sh
    cat << EOF > /etc/systemd/system/bbrinstall.service
[Unit]
Description=BBRinstall
After=network.target

[Service]
Type=oneshot
ExecStart=/root/BBR.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable bbrinstall.service
}


## Deluge

#Deluge Libtorrent Config
function Deluge_libtorrent {
    normal_1; echo "Configuring Deluge Libtorrent Settings"; warn_2
    systemctl stop deluged@$username
    cat << EOF >/home/$username/.config/deluge/ltconfig.conf
{
  "file": 1, 
  "format": 1
}{
  "apply_on_start": true, 
  "settings": {
    "default_cache_min_age": 10, 
    "connection_speed": 500, 
    "connections_limit": 500000, 
    "guided_read_cache": true, 
    "max_rejects": 100, 
    "inactivity_timeout": 120, 
    "active_seeds": -1, 
    "max_failcount": 20, 
    "allowed_fast_set_size": 0, 
    "max_allowed_in_request_queue": 10000, 
    "enable_incoming_utp": false, 
    "unchoke_slots_limit": -1, 
    "peer_timeout": 120, 
    "peer_connect_timeout": 30,
    "handshake_timeout": 30,
    "request_timeout": 5, 
    "allow_multiple_connections_per_ip": true, 
    "use_parole_mode": false, 
    "piece_timeout": 5, 
    "tick_interval": 100, 
    "active_limit": -1, 
    "connect_seed_every_n_download": 50, 
    "file_pool_size": 5000, 
    "cache_expiry": 300, 
    "seed_choking_algorithm": 1, 
    "max_out_request_queue": 10000, 
    "send_buffer_watermark": 10485760, 
    "send_buffer_watermark_factor": 200, 
    "active_tracker_limit": -1, 
    "send_buffer_low_watermark": 3145728, 
    "mixed_mode_algorithm": 0, 
    "max_queued_disk_bytes": 10485760, 
    "min_reconnect_time": 2,  
    "aio_threads": 4, 
    "write_cache_line_size": 256, 
    "torrent_connect_boost": 100, 
    "listen_queue_size": 3000, 
    "cache_buffer_chunk_size": 256, 
    "suggest_mode": 1, 
    "request_queue_time": 5, 
    "strict_end_game_mode": false, 
    "use_disk_cache_pool": true, 
    "predictive_piece_announce": 10, 
    "prefer_rc4": false, 
    "whole_pieces_threshold": 5, 
    "read_cache_line_size": 128, 
    "initial_picker_threshold": 10, 
    "enable_outgoing_utp": false, 
    "cache_size": $Cache1, 
    "low_prio_disk": false
  }
}
EOF
    systemctl start deluged@$username
}

