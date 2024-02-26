#!/bin/sh

# This script is used to check the latest version of BBR
# and update the local version file if the latest version is different from the local version

# Project URL:
git_bbr="https://github.com/google/bbr.git"

# Check if git is installed
if ! [ -x "$(command -v git)" ]; then
	apt -y update && apt -y upgrade
	apt -y install git
fi

# Get the latest version of BBR
remote=$(git ls-remote $git_bbr -h refs/heads/master | cut -f1)

# Get the local version of BBR
#Check if the local version file exists
if ! [ -f /$HOME/local_ver ]; then
	touch /$HOME/local_ver
	cat <<EOF > /$HOME/local_ver
$remote
EOF
fi
local=$(cat /$HOME/local_ver)

# BBRv3 Compile
bbr_compile() {
	# Install Dependencies
	apt -y update && apt -y upgrade
	if ! dpkg -s build-essential >/dev/null 2>&1; then
		apt -y install build-essential
	fi
	if ! dpkg -s libncurses-dev >/dev/null 2>&1; then
		apt -y install libncurses-dev
	fi
	if ! dpkg -s libssl-dev >/dev/null 2>&1; then
		apt -y install libssl-dev
	fi
	if ! dpkg -s libelf-dev >/dev/null 2>&1; then
		apt -y install libelf-dev
	fi
	if ! dpkg -s bison >/dev/null 2>&1; then
		apt -y install bison
	fi
	if ! dpkg -s bc >/dev/null 2>&1; then
		apt -y install bc
	fi
	if ! dpkg -s flex >/dev/null 2>&1; then
		apt -y install flex
	fi
	if ! dpkg -s rsync >/dev/null 2>&1; then
		apt -y install rsync
	fi
	if ! dpkg -s debhelper >/dev/null 2>&1; then
		apt -y install debhelper
	fi
	if ! dpkg -s dwarves >/dev/null 2>&1; then
		apt -y install dwarves
	fi
	if ! dpkg -s git >/dev/null 2>&1; then
		apt -y install git
	fi


	# Remove old files
	rm -rf /$HOME/bbr


	# Clone the latest version of BBR
	git clone -o google-bbr -b v3 $git_bbr /$HOME/bbr
	if [ $? -ne 0 ]; then
		rm -rf /$HOME/bbr
		exit 1
	fi


	# Compile BBR
	cd /$HOME/bbr
	wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/BBR/BBRv3/.config
	make bindeb-pkg -j$(nproc)
	if [ $? -ne 0 ]; then
		rm -rf /$HOME/bbr
		exit 1
	fi
}

# Check for update
if [ "$remote" != "$local" ]; then
	bbr_compile
	if [ $? -eq 0 ]; then
		cat <<EOF > /$HOME/local_ver
$remote
EOF
		exit 0
	fi
else
	exit 0
fi


