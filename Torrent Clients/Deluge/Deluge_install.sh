libtorrent_Ver=1.1.14
Deluge_majver=1
Deluge_minver=1.3
Deluge_rev=1.3.15
dewebport=8112

function Deluge_download {
    normal_1; echo "Downloading Deluge"; normal_2
    if [[ "${Deluge_minver}" = "1.3" ]]; then
        while true; do
            result=$(wget -4 http://download.deluge-torrent.org/source/$Deluge_minver/deluge-$Deluge_rev.tar.xz 2>&1)
            if [[ ! $result =~ 404 ]]; then
                break
            fi
            sleep 2
        done
    fi
    tput sgr0; clear
}

function Deluge_install {
    normal_1; echo "Installing Deluge"; normal_2
    distro_codename="$(source /etc/os-release && printf "%s" "${VERSION_CODENAME}")"
    if [[ $distro_codename = buster ]]; then
        ## Installing Libtorrent
        apt-get -qqy install libboost-all-dev libboost-dev python python-twisted python-openssl python-setuptools intltool python-xdg python-chardet geoip-database python-notify python-pygame python-glade2 librsvg2-common xdg-utils python-mako 
        wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/Deluge/libtorrent/buster_libtorrent-rasterbar_$libtorrent_Ver-amd64.deb
        dpkg -r libtorrent-rasterbar
        dpkg -i /root/buster_libtorrent-rasterbar_$libtorrent_Ver-amd64.deb && rm /root/buster_libtorrent-rasterbar_$libtorrent_Ver-amd64.deb
        ldconfig
        if [ ! $? -eq 0 ]; then
            warn_1; echo "Libtorrent install failed"; normal_4
            exit 1
        fi
        ## Installing Deluge
        test -e $HOME/deluge-$Deluge_rev && rm -r $HOME/deluge-$Deluge_rev
        tar xf deluge-$Deluge_rev.tar.xz && rm /root/deluge-$Deluge_rev.tar.xz && cd deluge-$Deluge_rev && wget --no-check-certificate https://pypi.python.org/packages/2.7/s/setuptools/setuptools-0.6c11-py2.7.egg
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
        cd $HOME && rm -r deluge-$Deluge_rev
    elif [[ $distro_codename = bullseye ]]; then
        apt-get -qqy install libboost-dev libboost-system-dev libboost-chrono-dev libboost-random-dev libssl-dev libgeoip-dev python2 python2-dev python-pkg-resources python-xdg intltool librsvg2-common xdg-utils geoip-database
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py && python2 get-pip.py
        pip install Twisted service-identity mako chardet pyopenssl
        wget http://archive.ubuntu.com/ubuntu/pool/universe/p/pyxdg/python-xdg_0.26-1ubuntu1_all.deb
        dpkg -i python-xdg_0.26-1ubuntu1_all.deb
        wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/Deluge/boost/boost-1-69-0_20220512-1_amd64.deb
        dpkg -i boost-1-69-0_20220512-1_amd64.deb
        wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/Deluge/libtorrent/bullseye_libtorrent-rasterbar_$libtorrent_Ver-amd64.deb
        dpkg -r libtorrent-rasterbar
        dpkg -i /root/bullseye_libtorrent-rasterbar_$libtorrent_Ver-amd64.deb && rm /root/bullseye_libtorrent-rasterbar_$libtorrent_Ver-amd64.deb
        ldconfig
        if [ ! $? -eq 0 ]; then
            warn_1; echo "Libtorrent install failed"; normal_4
            exit 1
        fi
        ## Installing Deluge
        test -e $HOME/deluge-$Deluge_rev && rm -r $HOME/deluge-$Deluge_r
        tar xJvf deluge-$Deluge_rev.tar.xz && rm /root/deluge-$Deluge_rev.tar.xz && cd deluge-$Deluge_rev
        python2 setup.py build
        if [ ! $? -eq 0 ]; then
            warn_1; echo "Deluge build failed"; normal_4
            exit 1
        fi
        python2 setup.py install --install-layout=deb
        if [ ! $? -eq 0 ]; then
            warn_1; echo "Deluge install failed"; normal_4
            exit 1
        fi
        cd $HOME && rm -r deluge-$Deluge_rev
    fi
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
ExecStart=/usr/bin/deluged -d
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
ExecStart=/usr/bin/deluge-web
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
