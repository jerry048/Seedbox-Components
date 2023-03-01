function qBittorrent_download {
    ## Allow users to determine which version of qBittorrent to be installed
    need_input; echo "Please enter your choice (qBittorrent Version - libtorrent Version):"; normal_3
    options=("qBittorrent 4.1.9 - libtorrent-1_1_14" "qBittorrent 4.1.9.1 - libtorrent-1_1_14" "qBittorrent 4.3.8 - libtorrent-v1.2.14" "qBittorrent 4.3.9 - libtorrent-v1.2.18" "qBittorrent 4.4.5 - libtorrent-v1.2.18" "qBittorrent 4.4.5 - libtorrent-v2.0.8" "qBittorrent 4.5.2 - libtorrent-v1.2.18" "qBittorrent 4.5.2 - libtorrent-v2.0.8")
    select opt in "${options[@]}"
    do
        case $opt in
            "qBittorrent 4.1.9 - libtorrent-1_1_14")
                qBver=4.1.9 && libver=libtorrent-1_1_14; break
                ;;
            "qBittorrent 4.1.9.1 - libtorrent-1_1_14")
                qBver=4.1.9.1 && libver=libtorrent-1_1_14; break
                ;;
            "qBittorrent 4.3.8 - libtorrent-v1.2.14")
                qBver=4.3.8 && libver=libtorrent-v1.2.14; break
                ;;
            "qBittorrent 4.3.9 - libtorrent-v1.2.18")
                qBver=4.3.9 && libver=libtorrent-v1.2.18; break
                ;;
            "qBittorrent 4.4.5 - libtorrent-v1.2.18")
                qBver=4.4.5 && libver=libtorrent-v1.2.18; break
                ;;
            "qBittorrent 4.4.5 - libtorrent-v2.0.8")
                qBver=4.4.5 && libver=libtorrent-v2.0.8; break
                ;;
            "qBittorrent 4.5.2 - libtorrent-v1.2.18")
                qBver=4.5.2 && libver=libtorrent-v1.2.18; break
                ;;
            "qBittorrent 4.5.2 - libtorrent-v2.0.8")
                qBver=4.5.2 && libver=libtorrent-v2.0.8; break
                ;;
            *) warn_1; echo "Please choose a valid version"; normal_3;;
        esac
    done
    wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent/qBittorrent%20$qBver%20-%20$libver/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox
}

function qBittorrent_install {
    normal_2
    ## Shut down qBittorrent if it has been already installed
    pgrep -i -f qbittorrent && pkill -s $(pgrep -i -f qbittorrent)
    test -e /usr/bin/qbittorrent-nox && rm /usr/bin/qbittorrent-nox
    mv $HOME/qbittorrent-nox /usr/bin/qbittorrent-nox
    ## Creating systemd services
    test -e /etc/systemd/system/qbittorrent-nox@.service && rm /etc/systemd/system/qbittorrent-nox@.service
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
    mkdir -p /home/$username/qbittorrent/Downloads && chown $username /home/$username/qbittorrent/Downloads
    mkdir -p /home/$username/.config/qBittorrent && chown $username /home/$username/.config/qBittorrent
    systemctl enable qbittorrent-nox@$username
    systemctl start qbittorrent-nox@$username
}

function qBittorrent_config {
    ## Determine if it is a SSD or a HDD and tune certain parameters
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
    ##
    systemctl stop qbittorrent-nox@$username
    ##
    if [[ "${qBver}" =~ "4.1." ]]; then
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
Connection\PortRangeMin=45000
Downloads\DiskWriteCacheSize=$Cache2
Downloads\SavePath=/home/$username/qbittorrent/Downloads/
Queueing\QueueingEnabled=false
WebUI\Password_ha1=@ByteArray($md5password)
WebUI\Port=8080
WebUI\Username=$username
EOF
    elif [[ "${qBver}" =~ "4.2."|"4.3." ]]; then
        wget  https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qb_password_gen && chmod +x $HOME/qb_password_gen
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
Connection\PortRangeMin=45000
Downloads\DiskWriteCacheSize=$Cache_qB
Downloads\SavePath=/home/$username/qbittorrent/Downloads/
Queueing\QueueingEnabled=false
WebUI\Password_PBKDF2="@ByteArray($PBKDF2password)"
WebUI\Port=8080
WebUI\Username=$username
EOF
    elif [[ "${qBver}" =~ "4.4."|"4.5." ]]; then
        wget  https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qb_password_gen && chmod +x $HOME/qb_password_gen
        PBKDF2password=$($HOME/qb_password_gen $password)
        cat << EOF >/home/$username/.config/qBittorrent/qBittorrent.conf
[Application]
MemoryWorkingSetLimit=$Cache_qB

[BitTorrent]
Session\AsyncIOThreadsCount=$aio
Session\DefaultSavePath=/home/$username/qbittorrent/Downloads/
Session\DiskCacheSize=$Cache_qB
Session\Port=45000
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
WebUI\Port=8080
WebUI\Username=$username
EOF
    rm qb_password_gen
    fi
    systemctl start qbittorrent-nox@$username
}
