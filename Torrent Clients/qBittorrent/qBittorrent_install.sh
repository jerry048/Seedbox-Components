function qBittorrent_download {
    need_input; echo "Please enter your choice (qBittorrent Version - libtorrent Version):"; normal_3
    options=("qBittorrent 4.1.9 - libtorrent-1_1_14" "qBittorrent 4.1.9.1 - libtorrent-1_1_14" "qBittorrent 4.3.3 - libtorrent-v1.2.13" "qBittorrent 4.3.4.1 - libtorrent-v1.2.13" "qBittorrent 4.3.5 - libtorrent-v1.2.13" "qBittorrent 4.3.6 - libtorrent-v1.2.14" "qBittorrent 4.3.7 - libtorrent-v1.2.14" "qBittorrent 4.3.8 - libtorrent-v1.2.14" "qBittorrent 4.4.0beta2 - libtorrent-v2.0.4")
    select opt in "${options[@]}"
    do
        case $opt in
            "qBittorrent 4.1.9 - libtorrent-1_1_14")
                version=4.1.9; wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent/qBittorrent%204.1.9%20-%20libtorrent-1_1_14/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.1.9.1 - libtorrent-1_1_14")
                version=4.1.9.1; wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent/qBittorrent%204.1.9.1%20-%20libtorrent-1_1_14/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.3.3 - libtorrent-v1.2.13")
                version=4.3.3; wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent/qBittorrent%204.3.3%20-%20libtorrent-v1.2.13/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.3.4.1 - libtorrent-v1.2.13")
                version=4.3.4.1; wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent/qBittorrent%204.3.4.1%20-%20libtorrent-v1.2.13/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.3.5 - libtorrent-v1.2.13")
                version=4.3.5; wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent/qBittorrent%204.3.5%20-%20libtorrent-v1.2.13/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.3.6 - libtorrent-v1.2.14")
                version=4.3.6; wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent/qBittorrent%204.3.6%20-%20libtorrent-v1.2.14/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.3.7 - libtorrent-v1.2.14")
                version=4.3.7; wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent/qBittorrent%204.3.7%20-%20libtorrent-v1.2.14/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.3.8 - libtorrent-v1.2.14")
                version=4.3.8; wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent/qBittorrent%204.3.8%20-%20libtorrent-v1.2.14/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.4.0beta2 - libtorrent-v2.0.4")
                version=4.4.0; wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent/qBittorrent%204.4.0beta2%20-%20libtorrent-v2.0.4/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            *) warn_1; echo "Please choose a valid version"; normal_3;;
        esac
    done
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
    systemctl stop qbittorrent-nox@$username
    if [[ "${version}" =~ "4.1." ]]; then
        md5password=$(echo -n $password | md5sum | awk '{print $1}')
        cat << EOF >/home/$username/.config/qBittorrent/qBittorrent.conf
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
    elif [[ "${version}" =~ "4.2."|"4.3."|"4.4." ]]; then
        wget  https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qb_password_gen && chmod +x $HOME/qb_password_gen
        PBKDF2password=$($HOME/qb_password_gen $password)
        cat << EOF >/home/$username/.config/qBittorrent/qBittorrent.conf
[LegalNotice]
Accepted=true

[Network]+
Cookies=@Invalid()

[Preferences]
Connection\PortRangeMin=45000
Downloads\DiskWriteCacheSize=$Cache2
Downloads\SavePath=/home/$username/qbittorrent/Downloads/
Queueing\QueueingEnabled=false
WebUI\Password_PBKDF2="@ByteArray($PBKDF2password)"
WebUI\Port=8080
WebUI\Username=$username
EOF
    rm qb_password_gen
    fi
    systemctl start qbittorrent-nox@$username
}