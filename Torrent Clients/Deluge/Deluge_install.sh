libtorrent_Ver=1.1.14
Deluge_Ver=1.3.15
dewebport=8112

function Deluge_download {
    normal_1; echo "Downloading Deluge and its dependencies"; normal_2
    if [[ "${Deluge_Ver}" =~ "1.3." ]]; then
        wget -4 http://download.deluge-torrent.org/source/deluge-$Deluge_Ver.tar.xz
        apt-get -qqy install libboost-all-dev libboost-dev python python-twisted python-openssl python-setuptools intltool python-xdg python-chardet geoip-database python-notify python-pygame python-glade2 librsvg2-common xdg-utils python-mako 
 #  elif [[ "${Deluge_Ver}" =~ "2.0." ]]; then
 #      wget -4 http://download.deluge-torrent.org/source/2.0/deluge-$Deluge_Ver.tar.xz
 #      apt-get -qqy install python3-geoip python3-dbus  python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-appindicator3 python3-pygame libnotify4 librsvg2-common xdg-utils
    fi
    wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/Deluge/libtorrent/libtorrent-rasterbar_$libtorrent_Ver-amd64.deb
    tput sgr0; clear
}

function Deluge_install {
    normal_1; echo "Installing Deluge"; normal_2
    ## Installing Libtorrent
    dpkg -r libtorrent-rasterbar
    dpkg -i /root/libtorrent-rasterbar_$libtorrent_Ver-amd64.deb && rm /root/libtorrent-rasterbar_$libtorrent_Ver-amd64.deb
    ldconfig
    if [ ! $? -eq 0 ]; then
        warn_1; echo "Libtorrent install failed"; normal_4
        exit 1
    fi
    ## Installing Deluge
    test -e $HOME/deluge-$Deluge_Ver && rm -r $HOME/deluge-$Deluge_Ver
    tar xf deluge-$Deluge_Ver.tar.xz && rm /root/deluge-$Deluge_Ver.tar.xz && cd deluge-$Deluge_Ver
    python setup.py clean -a
    python setup.py build
    if [ ! $? -eq 0 ]; then
        warn_1; echo "Deluge build failed"; normal_4
        exit 1
    fi
    python setup.py install
    if [ ! $? -eq 0 ]; then
        warn_1; echo "Deluge install failed"; normal_4
        exit 1
    fi
    cd $HOME && rm -r deluge-$Deluge_Ver
    ## Creating systemd services 
    cat << EOF > /etc/systemd/system/deluged@.service
[Unit]
Description=Deluge-Daemon
After=network-online.target

[Service]
Type=simple
UMask=002
User=$username
LimitNOFILE=infinity
ExecStart=/usr/local/bin/deluged -d
ExecStop=/usr/bin/killall -w -s 9 /usr/bin/deluged
Restart=on-failure
TimeoutStopSec=20
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    cat << EOF > /etc/systemd/system/deluge-web@.service
[Unit]
Description=Deluge-WebUI
After=network-online.target deluged.service
Wants=deluged.service

[Service]
Type=simple
User=$username
ExecStart=/usr/local/bin/deluge-web
ExecStop=/usr/bin/killall -w -s 9 /usr/bin/deluge-web
TimeoutStopSec=5
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    mkdir -p /home/$username/deluge/completed /home/$username/deluge/download /home/$username/deluge/torrent && chown -R $username /home/$username/deluge
    mkdir -p /home/$username/.config/deluge/plugins
    systemctl enable deluged@$username && systemctl start deluged@$username
    systemctl enable deluge-web@$username && systemctl start deluge-web@$username
}

function Deluge_config {
    systemctl stop deluged@$username && systemctl stop deluge-web@$username
    ## Setting up auth file
    echo "$username:$password:10" >> /home/$username/.config/deluge/auth

    ## Setting up Daemon config
    cat << EOF >/home/$username/.config/deluge/core.conf
{
  "file": 1, 
  "format": 1
}{
  "info_sent": 0.0, 
  "lsd": false, 
  "send_info": false, 
  "move_completed_path": "/home/$username/deluge/completed", 
  "enc_in_policy": 1, 
  "queue_new_to_top": false, 
  "ignore_limits_on_local_network": true, 
  "rate_limit_ip_overhead": true, 
  "daemon_port": 58846, 
  "natpmp": false, 
  "max_active_limit": -1, 
  "utpex": false, 
  "max_active_downloading": -1, 
  "max_active_seeding": -1, 
  "allow_remote": true, 
  "max_half_open_connections": -1, 
  "download_location": "/home/$username/deluge/download", 
  "compact_allocation": false, 
  "max_upload_speed": -1.0, 
  "cache_expiry": 300,
  "prioritize_first_last_pieces": false, 
  "auto_managed": true, 
  "enc_level": 2, 
  "max_connections_per_second": -1, 
  "dont_count_slow_torrents": true, 
  "random_outgoing_ports": true, 
  "max_upload_slots_per_torrent": -1, 
  "new_release_check": false, 
  "enc_out_policy": 1, 
  "outgoing_ports": [
    0, 
    0
  ], 
  "seed_time_limit": -1,
  "cache_size": $Cache1, 
  "share_ratio_limit": -1.0, 
  "max_download_speed": -1.0, 
  "geoip_db_location": "/usr/share/GeoIP/GeoIP.dat", 
  "torrentfiles_location": "/home/$username/deluge/torrent", 
  "stop_seed_at_ratio": false, 
  "peer_tos": "0xB8", 
  "listen_interface": "", 
  "upnp": false, 
  "max_download_speed_per_torrent": -1, 
  "max_upload_slots_global": -1, 
  "enabled_plugins": [
    "ltConfig"
  ], 
  "random_port": true, 
  "autoadd_enable": true, 
  "max_connections_global": -1, 
  "enc_prefer_rc4": false, 
  "listen_ports": [
    6881, 
    6891
  ], 
  "dht": false, 
  "stop_seed_ratio": 2.0, 
  "seed_time_ratio_limit": -1.0, 
  "max_upload_speed_per_torrent": -1, 
  "copy_torrent_file": true, 
  "del_copy_torrent_file": false, 
  "move_completed": false, 
  "proxies": {
    "peer": {
      "username": "", 
      "password": "", 
      "type": 0, 
      "hostname": "", 
      "port": 8080
    }, 
    "web_seed": {
      "username": "", 
      "password": "", 
      "type": 0, 
      "hostname": "", 
      "port": 8080
    }, 
    "tracker": {
      "username": "", 
      "password": "", 
      "type": 0, 
      "hostname": "", 
      "port": 8080
    }, 
    "dht": {
      "username": "", 
      "password": "", 
      "type": 0, 
      "hostname": "", 
      "port": 8080
    }
  }, 
  "add_paused": false, 
  "max_connections_per_torrent": -1, 
  "remove_seed_at_ratio": false, 
  "autoadd_location": "/home/$username/deluge/watch/", 
  "plugins_location": "/home/$username/.config/deluge/plugins"
}
EOF

    ## Setting up WebUI config
    DWSALT=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)
    wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/Deluge/deluge.Userpass.py
    wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/Deluge/deluge.addHost.py
    DWP=$(python2 /root/deluge.Userpass.py $password $DWSALT)
	DUDID=$(python2 /root/deluge.addHost.py)
    cat << EOF >/home/$username/.config/deluge/web.conf
{
  "file": 1,
  "format": 1
}{
  "port": 8112,
  "enabled_plugins": [
    "ltConfig"
  ],
  "pwd_sha1": "$DWP",
  "theme": "gray",
  "show_sidebar": true,
  "sidebar_show_zero": false,
  "pkey": "ssl/daemon.pkey",
  "https": false,
  "sessions": {},
  "base": "/",
  "pwd_salt": "$DWSALT",
  "show_session_speed": true,
  "first_login": false,
  "cert": "ssl/daemon.cert",
  "session_timeout": 3600,
  "default_daemon": "$DUDID",
  "sidebar_multiple_filters": true
}
EOF
    rm /root/deluge.Userpass.py /root/deluge.addHost.py
    
    ## Setting up Hostlist
    cat << EOF > /home/$username/.config/deluge/hostlist.conf.1.2
{
  "file": 1,
  "format": 1
}{
  "hosts": [
    [
      "$DUDID",
      "127.0.0.1",
      58846,
      "$username",
      "$password"
    ]
  ]
}
EOF

    ## Setting up plugins
    cd /home/$username/.config/deluge/plugins
    wget https://github.com/ratanakvlun/deluge-ltconfig/releases/download/v0.3.1/ltConfig-0.3.1-py2.7.egg
    cd $HOME
    chown -R $username /home/$username/.config/deluge
    systemctl start deluged@$username && systemctl start deluge-web@$username
}