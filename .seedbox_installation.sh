#!/bin/bash

## Update Installed Packages & Installing Essential Packages
function Update {
    tput setaf 2; echo "Updating installed packages and install prerequisite"
    tput setaf 7
    apt-get -qqy update && apt-get -qqy upgrade
    apt-get -qqy install sudo
    apt-get -qqy install sysstat
    cd $HOME
    clear
    tput setaf 1
}

## qBittorrent
function qBittorrent_download {
    tput setaf 2; echo "Please enter your choice (qBittorrent Version - libtorrent Version):"
    options=("qBittorrent 4.1.9 - libtorrent-1_1_14" "qBittorrent 4.1.9.1 - libtorrent-1_1_14" "qBittorrent 4.3.3 - libtorrent-v1.2.12-Lactency" "qBittorrent 4.3.3 - libtorrent-v1.2.13" "qBittorrent 4.3.4.1 - libtorrent-v1.2.13-Lactency" "qBittorrent 4.3.4.1 - libtorrent-v1.2.13")
    select opt in "${options[@]}"
    do
        case $opt in
            "qBittorrent 4.1.9 - libtorrent-1_1_14")
                version=4.1.9; curl -s -O https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/qBittorrent/qBittorrent%204.1.9%20-%20libtorrent-1_1_14/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.1.9.1 - libtorrent-1_1_14")
                version=4.1.9.1; curl -s -O https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/qBittorrent/qBittorrent%204.1.9.1%20-%20libtorrent-1_1_14/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.3.3 - libtorrent-v1.2.12-Lactency")
                version=4.3.3; curl -s -O https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/qBittorrent/qBittorrent%204.3.3%20-%20libtorrent-v1.2.12-Lactency/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.3.3 - libtorrent-v1.2.13")
                version=4.3.3; curl -s -O https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/qBittorrent/qBittorrent%204.3.3%20-%20libtorrent-v1.2.13/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.3.4.1 - libtorrent-v1.2.13-Lactency")
                version=4.3.3; curl -s -O https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/qBittorrent/qBittorrent%204.3.4.1%20-%20libtorrent-v1.2.13-Lactency/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            "qBittorrent 4.3.4.1 - libtorrent-v1.2.13")
                version=4.3.3; curl -s -O https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/qBittorrent/qBittorrent%204.3.4.1%20-%20libtorrent-v1.2.13/qbittorrent-nox && chmod +x $HOME/qbittorrent-nox; break
                ;;
            *) tput setaf 1; echo "Please choose a valid version";;
        esac
    done
}
function qBittorrent_install {
    tput setaf 1
    test -e /usr/bin/qbittorrent-nox && rm /usr/bin/qbittorrent-nox
    mv $HOME/qbittorrent-nox /usr/bin/qbittorrent-nox
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
    sudo -u $username mkdir -p /home/$username/qbittorrent/Downloads
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
    elif [[ "${version}" =~ "4.2."|"4.3." ]]; then
        curl -s -O https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Miscellaneous/qb_password_gen && chmod +x $HOME/qb_password_gen
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

function qBittorrent {
    qBittorrent_download
    qBittorrent_install
    qBittorrent_config
    qbport=$(grep -F 'WebUI\Port'  /home/$username/.config/qBittorrent/qBittorrent.conf | grep -Eo '[0-9]{1,5}')
    clear
    tput setaf 2
}

## Install autoremove-torrents
function Decision2 {
    while true; do
        tput setaf 2; read -p "Do you wish to config autoremove-torrents for $1? (Y/N):" yn
        case $yn in
           [Yy]* ) e=0; break;;
           [Nn]* ) e=1; break;;
            * ) tput setaf 1; echo "Please answer yes or no.";;
        esac
    done
}
function autoremove-torrents {
    tput setaf 7
    apt-get -qqy install python3-distutils > /dev/null
    apt-get -qqy install python3-apt > /dev/null
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3 get-pip.py
    rm get-pip.py
    pip -q install autoremove-torrents
    clear
    tput setaf 2
    read -p "Enter desired reserved storage (in GiB): " diskspace
    read -p "Enter desired minimum seedtime (in Second): " seedtime
    # qBittorrent
    tput setaf 2
    unset e
    if [ -z ${qbport+x} ]; then echo "Skipping qBittorrent since it is not installed"; else Decision2 qBittorrent; fi
    if [ "${e}" == "0" ]; then
        touch $HOME/.config.yml
        cat << EOF >>$HOME/.config.yml
General-qb:          
  client: qbittorrent
  host: http://127.0.0.1:$qbport
  username: $username
  password: $password
  strategies:
    Upload:
      status:
        - Uploading
      remove: upload_speed < 1024 and seeding_time > $seedtime
    Leech:
      status:
        - Downloading
      remove: ratio < 1 and progress > 5 and download_speed > 20480
    Disk:
      free_space:
        min: $diskspace
        path: /
        action: remove-old-seeds
  delete_data: true
EOF
    fi
    sed -i 's+127.0.0.1: +127.0.0.1:+g' $HOME/.config.yml
    mkdir $HOME/.autoremove-torrents
    chmod 777 $HOME/.autoremove-torrents
    touch $HOME/.autoremove.sh
    cat << EOF >$HOME/.autoremove.sh
#!/bin/sh

while true; do
  /usr/local/bin/autoremove-torrents --conf=$HOME/.config.yml --log=$HOME/.autoremove-torrents
  sleep 5
done
EOF
    chmod +x $HOME/.autoremove.sh
    apt-get -qqy install screen > /dev/null
    screen -dmS autoremove-torrents $HOME/.autoremove.sh
}