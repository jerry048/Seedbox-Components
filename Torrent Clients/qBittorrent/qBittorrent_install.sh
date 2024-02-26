## List of qBittorrent Version that is supported
declare -a qb_ver_list=("4.1.9" "4.1.9.1" "4.2.5" "4.3.9" "4.4.5" "4.5.5" "4.6.2")

## List of libtorrent Version that is supported
declare -a lib_ver_list=("1_1_14" "v1.2.19" "v2.0.10")

qb_ver_choose(){
	need_input "Please choose your qBittorrent Version:"
	#Generate the list of qBittorrent Version that is supported
	unset options i
	for i in "${qb_ver_list[@]}"
	do
		options+=("qBittorrent $i")
	done

	select opt in "${options[@]}"
	do
		case $opt in
		qBittorrent*)
			qb_ver=${opt}; break
			;;
		*) warn "Please choose a valid version" ;;
		esac
	done
}

lib_ver_choose(){
	## Check if qb_ver is empty
	if [[ -z "$qb_ver" ]]; then
		qb_ver_choose
	fi

	## Allow users to determine which version of libtorrent to go with the qBittorrent
	need_input "Please choose your libtorrent version:"
	#Generate the list of libtorrent Version that is supported
	unset options i
	for i in "${lib_ver_list[@]}"
	do
		options+=("libtorrent-$i")
	done

	select opt in "${options[@]}"
	do
		case $opt in
		libtorrent*)
			lib_ver=${opt}; break
			;;
		*) warn "Please choose a valid version" ;;
		esac
	done
}

lib_ver_check(){
	## Check if lib_ver is empty
	if [[ -z "$lib_ver" ]]; then
		lib_ver_choose
	fi
	## Check if the libtorrent version is supported
	if [[ ! " ${lib_ver_list[@]} " =~ " ${lib_ver} " ]]; then
		warn "libtorrent $lib_ver is not supported"
		lib_ver_choose
	fi
	## Check if the libtorrent version is compatible with qBittorrent version
	if [[ "${qb_ver}" =~ "4.1." ]]; then
		while true
		do
			if [[ ! "${lib_ver}" == "libtorrent-1_1_14" ]]; then
				tput sgr0; clear
				warn "qBittorrent $qb_ver is not compatible with libtorrent $lib_ver"
				warn "qBittorrent $qb_ver is compatible with libtorrent-1_1_x only"
				warn "Please choose a compatible version"
				lib_ver_choose
			else
				break
			fi
		done
	elif [[ "${qb_ver}" =~ "4.2." ]]; then
		while true
		do
			if [[ ! "${lib_ver}" =~ "libtorrent-v1.2." ]]; then
				tput sgr0; clear
				warn "qBittorrent $qb_ver is not compatible with libtorrent $lib_ver"
				warn "qBittorrent $qb_ver is compatible with libtorrent-v1.2.x only"
				warn "Please choose a compatible version"
				lib_ver_choose
			else
				break
			fi
	done
	elif [[ "${qb_ver}" =~ "4.3." ]]; then
		while true
		do
			if [[ ! "${lib_ver}" =~ "libtorrent-v1.2." ]]; then
				tput sgr0; clear
				warn "qBittorrent $qb_ver is not compatible with libtorrent $lib_ver"
				warn "qBittorrent $qb_ver is compatible with libtorrent-v1.2.x only"
				warn "Please choose a compatible version"
				lib_ver_choose
			else
				break
			fi
	done
	elif [[ "${qb_ver}" =~ "4.4." ]]; then
		while true
		do
			if [[ ! "${lib_ver}" =~ "libtorrent-v1.2." ]] && [[ ! "${lib_ver}" =~ "libtorrent-v2.0." ]]; then
				tput sgr0; clear
				warn "qBittorrent $qb_ver is not compatible with libtorrent $lib_ver";
				warn "qBittorrent $qb_ver is compatible with libtorrent-v1.2.x or libtorrent-v2.0.x only";
				warn "Please choose a compatible version";
				lib_ver_choose
			else
				break
			fi
		done
	elif [[ "${qb_ver}" =~ "4.5." ]]; then
		while true
		do
			if [[ ! "${lib_ver}" =~ "libtorrent-v1.2." ]] && [[ ! "${lib_ver}" =~ "libtorrent-v2.0." ]]; then
				tput sgr0; clear
				warn "qBittorrent $qb_ver is not compatible with libtorrent $lib_ver"
				warn "qBittorrent $qb_ver is compatible with libtorrent-v1.2.x or libtorrent-v2.0.x only"
				warn "Please choose a compatible version"
				lib_ver_choose
			else
				break
			fi
		done
	elif [[ "${qb_ver}" =~ "4.6." ]]; then
		while true
		do
			if [[ ! "${lib_ver}" =~ "libtorrent-v1.2." ]] && [[ ! "${lib_ver}" =~ "libtorrent-v2.0." ]]; then
				tput sgr0; clear
				warn "qBittorrent $qb_ver is not compatible with libtorrent $lib_ver"
				warn "qBittorrent $qb_ver is compatible with libtorrent-v1.2.x or libtorrent-v2.0.x only"
				warn "Please choose a compatible version"
				lib_ver_choose
			else
				break
			fi
		done
	fi
}

qb_install_check(){
	# Check if qBittorrent version and libtorrent version are supported
	## Check if the qBittorrent version is supported
	if [[ ! " ${qb_ver_list[@]} " =~ " ${qb_ver} " ]]; then
		warn "qBittorrent $qb_ver is not supported"
		qb_ver_choose
	fi
	## Check if the libtorrent version is supported
	if [[ ! " ${lib_ver_list[@]} " =~ " ${lib_ver} " ]]; then
		warn "libtorrent $lib_ver is not supported"
		lib_ver_check
	fi
	## Check if the libtorrent version is compatible with qBittorrent version
	lib_ver_check
}


install_qBittorrent_(){
	username=$1
	password=$2
	qb_ver=$3
	lib_ver=$4
	qb_cache=$5
	qb_port=$6
	qb_incoming_port=$7

	## Check if qBittorrent is running
	if pgrep -i -f qbittorrent; then
		warn "qBittorrent is running. Stopping it now..."
		pkill -s $(pgrep -i -f qbittorrent)
	fi
	# Check if it is still running
	if pgrep -i -f qbittorrent; then
		warn "Failed to stop qBittorrent. Please stop it manually"
		return 1
	fi

	## Check if qbittorrent-nox is installed
	if test -e /usr/bin/qbittorrent-nox; then
		warn "qBittorrent is already installed. Replacing it now..."
		rm /usr/bin/qbittorrent-nox
	fi

	## Download qBittorrent-nox executable
	# Determine the CPU architecture
	if [[ $(uname -m) == "x86_64" ]]; then
		arch="x86_64"
	elif [[ $(uname -m) == "aarch64" ]]; then
		arch="ARM64"
	else
		warn "Unsupported CPU architecture"
		return 1
	fi
	wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/$arch/qBittorrent%20$qb_ver%20-%20$lib_ver/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox
	#Check if the download is successful
	if [ $? -ne 0 ]; then
		warn "Failed to download qBittorrent-nox executable"
		return 1
	fi

	# Install qbittorrent-nox
	mv $HOME/qbittorrent-nox /usr/bin/qbittorrent-nox
	mkdir -p /home/$username/qbittorrent/Downloads && chown $username /home/$username/qbittorrent/Downloads
    mkdir -p /home/$username/.config/qBittorrent && chown $username /home/$username/.config/qBittorrent

	# Create systemd services
	if test -e /etc/systemd/system/qbittorrent-nox@.service; then
		warn "qBittorrent systemd services already exist. Removing it now..."
		rm /etc/systemd/system/qbittorrent-nox@.service
	fi
	touch /etc/systemd/system/qbittorrent-nox@.service
	cat << EOF >/etc/systemd/system/qbittorrent-nox@.service
[Unit]
Description=qBittorrent
After=network.target

[Service]
Type=forking
User=$username
LimitNOFILE=infinity
ExecStart=/usr/bin/qbittorrent-nox -d
ExecStop=/usr/bin/killall -w -s 9 /usr/bin/qbittorrent-nox
Restart=on-failure
TimeoutStopSec=20
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable qbittorrent-nox@$username
    systemctl start qbittorrent-nox@$username

	## Configure qBittorrent
	# Check for Virtual Environment since some of the tunning might not work on virtual machine
	systemd-detect-virt > /dev/null
	if [ $? -eq 0 ]; then
		warn "Virtualization is detected, skipping some of the tunning"
		aio=8
		low_buffer=3072
		buffer=15360
		buffer_factor=200
	else
		#Determine if it is a SSD or a HDD
		disk_name=$(printf $(lsblk | grep -m1 'disk' | awk '{print $1}'))
		disktype=$(cat /sys/block/$disk_name/queue/rotational)
		if [ "${disktype}" == 0 ]; then
			aio=12
			low_buffer=5120
			buffer=20480
			buffer_factor=250
		else
			aio=4
			low_buffer=3072
			buffer=10240
			buffer_factor=150
		fi
	fi

	# Editing qBittorrent settings
    systemctl stop qbittorrent-nox@$username

    if [[ "${qb_ver}" =~ "4.1." ]]; then
        md5password=$(echo -n $password | md5sum | awk '{print $1}')
        cat << EOF >/home/$username/.config/qBittorrent/qBittorrent.conf
[BitTorrent]
Session\AsyncIOThreadsCount=$aio
Session\SendBufferLowWatermark=$low_buffer
Session\SendBufferWatermark=$buffer
Session\SendBufferWatermarkFactor=$buffer_factor

[LegalNotice]
Accepted=true

[Network]
Cookies=@Invalid()

[Preferences]
Connection\PortRangeMin=$qb_incoming_port
Downloads\DiskWriteCacheSize=$qb_cache
Downloads\SavePath=/home/$username/qbittorrent/Downloads/
Queueing\QueueingEnabled=false
WebUI\Password_ha1=@ByteArray($md5password)
WebUI\Port=$qb_port
WebUI\Username=$username
EOF
    elif [[ "${qb_ver}" =~ "4.2."|"4.3." ]]; then
        wget  https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/$arch/qb_password_gen && chmod +x $HOME/qb_password_gen
        #Check if the download is successful
		if [ $? -ne 0 ]; then
			warn "Failed to download qb_password_gen"
			#Clean up
			rm -r /home/$username/qbittorrent/Downloads
			rm -r /home/$username/.config/qBittorrent
			rm /usr/bin/qbittorrent-nox
			rm /etc/systemd/system/qbittorrent-nox@.service
			return 1
		fi
		PBKDF2password=$($HOME/qb_password_gen $password)
        cat << EOF >/home/$username/.config/qBittorrent/qBittorrent.conf
[BitTorrent]
Session\AsyncIOThreadsCount=$aio
Session\SendBufferLowWatermark=$low_buffer
Session\SendBufferWatermark=$buffer
Session\SendBufferWatermarkFactor=$buffer_factor

[LegalNotice]
Accepted=true

[Network]
Cookies=@Invalid()

[Preferences]
Connection\PortRangeMin=$qb_incoming_port
Downloads\DiskWriteCacheSize=$qb_cache
Downloads\SavePath=/home/$username/qbittorrent/Downloads/
Queueing\QueueingEnabled=false
WebUI\Password_PBKDF2="@ByteArray($PBKDF2password)"
WebUI\Port=$qb_port
WebUI\Username=$username
EOF
    elif [[ "${qb_ver}" =~ "4.4."|"4.5."|"4.6." ]]; then
        wget  https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/$arch/qb_password_gen && chmod +x $HOME/qb_password_gen
        #Check if the download is successful
		if [ $? -ne 0 ]; then
			warn "Failed to download qb_password_gen"
			#Clean up
			rm -r /home/$username/qbittorrent/Downloads
			rm -r /home/$username/.config/qBittorrent
			rm /usr/bin/qbittorrent-nox
			rm /etc/systemd/system/qbittorrent-nox@.service
			return 1
		fi
		PBKDF2password=$($HOME/qb_password_gen $password)
        cat << EOF >/home/$username/.config/qBittorrent/qBittorrent.conf
[Application]
MemoryWorkingSetLimit=$qb_cache

[BitTorrent]
Session\AsyncIOThreadsCount=$aio
Session\DefaultSavePath=/home/$username/qbittorrent/Downloads/
Session\DiskCacheSize=$qb_cache
Session\Port=$qb_incoming_port
Session\QueueingSystemEnabled=false
Session\SendBufferLowWatermark=$low_buffer
Session\SendBufferWatermark=$buffer
Session\SendBufferWatermarkFactor=$buffer_factor

[LegalNotice]
Accepted=true

[Network]
Cookies=@Invalid()

[Preferences]
WebUI\Password_PBKDF2="@ByteArray($PBKDF2password)"
WebUI\Port=$qb_port
WebUI\Username=$username
EOF
    rm qb_password_gen
    fi
    systemctl start qbittorrent-nox@$username
}

return 0