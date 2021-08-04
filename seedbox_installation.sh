#!/bin/bash

## Update Installed Packages & Installing Essential Packages
function Update {
    normal_1; echo "Updating installed packages and install prerequisite"
    normal_2
    apt-get -qqy update && apt-get -qqy upgrade
    apt-get -qqy install sudo sysstat
    cd $HOME
    tput sgr0; clear
}

## qBittorrent
function qBittorrent {
    normal_1; echo "qBittorrent"; warn_2
    source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent_install.sh)
    qBittorrent_download
    qBittorrent_install
    qBittorrent_config
    qbport=$(grep -F 'WebUI\Port'  /home/$username/.config/qBittorrent/qBittorrent.conf | grep -Eo '[0-9]{1,5}')
    tput sgr0; clear
}

## Deluge
function Deluge {
    normal_1; echo "Deluge"; warn_2
    source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/Deluge/Deluge_install.sh)
    Deluge_download
    Deluge_install
    Deluge_config
    deport=$(cat /home/$username/.config/deluge/core.conf | grep daemon_port | grep -Eo '[0-9]{1,5}')
    tput sgr0; clear
}

## autoremove-torrents
function Decision2 {
    while true; do
        need_input; read -p "Do you wish to config autoremove-torrents for $1? (Y/N):" yn; normal_3
        case $yn in
           [Yy]* ) e=0; break;;
           [Nn]* ) e=1; echo "Skipping"; break;;
            * ) warn_1; echo "Please answer yes or no."; normal_3;;
        esac
    done
}
function autoremove-torrents {
    normal_2
    apt-get -qqy install python3-distutils python3-apt
    [[ $(pip --version) ]] || (apt-get -qqy install curl && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py && rm get-pip.py )
    pip -q install autoremove-torrents
    tput sgr0; clear
    need_input
    read -p "Enter desired reserved storage (in GiB): " diskspace
    read -p "Enter desired minimum seedtime (in Second): " seedtime
    # Deluge
    normal_2
    unset e
    if [ -z ${deport+x} ]; then echo "Skipping Deluge since it is not installed"; else Decision2 Deluge; fi
    if [ "${e}" == "0" ]; then
        normal_1; echo "Configuring autoremove-torrents for Deluge"
        warn_2
        touch $HOME/.config.yml
        cat << EOF >>$HOME/.config.yml
General-de:          
  client: Deluge
  host: 127.0.0.1:$deport
  username: $username
  password: $password
  strategies:
    Upload:
      status:
        - Uploading
      remove: upload_speed < 1024 and seeding_time > $seedtime
    Disk:
      free_space:
        min: $diskspace
        path: /home/$username/
        action: remove-old-seeds
  delete_data: true
M-Team-de:          
  client: Deluge
  host: 127.0.0.1:$deport
  username: $username
  password: $password
  strategies:
    Ratio:
      trackers:
        - tracker.m-team.cc
      upload_ratio: 3
  delete_data: true
EOF
    fi
    # qBittorrent
    normal_2
    unset e
    if [ -z ${qbport+x} ]; then echo "Skipping qBittorrent since it is not installed"; else Decision2 qBittorrent; fi
    if [ "${e}" == "0" ]; then
        normal_1; echo "Configuring autoremove-torrents for qBittorrent"
        warn_2
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
    Disk:
      free_space:
        min: $diskspace
        path: /home/$username/
        action: remove-old-seeds
  delete_data: true
EOF
    fi
    sed -i 's+127.0.0.1: +127.0.0.1:+g' $HOME/.config.yml
    mkdir $HOME/.autoremove-torrents && chmod 755 $HOME/.autoremove-torrents
    touch $HOME/.autoremove.sh
    cat << EOF >$HOME/.autoremove.sh
#!/bin/sh

while true; do
  /usr/local/bin/autoremove-torrents --conf=$HOME/.config.yml --log=$HOME/.autoremove-torrents
  sleep 5
done
EOF
    chmod +x $HOME/.autoremove.sh
    normal_2
    apt-get -qqy install screen
    screen -dmS autoremove-torrents $HOME/.autoremove.sh
}
