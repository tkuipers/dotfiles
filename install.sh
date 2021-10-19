#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
START_DIR=$(pwd)
TEMP_DIR="/tmp"
USER_HOME="$HOME"
USER="$USER"

ln -fs /usr/share/zoneinfo/America/Edmonton /etc/localtime
apt-get install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata

echo "Getting Root"
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

echo "Installing Pre-Req Software"
apt-get update
apt-get install -y build-essential clang g++ python3.9-dev vim git

echo "Cloning dotfiles"
cd $TEMP_DIR
rm -r ./dotfiles 2> /dev/null
git clone  https://github.com/tkuipers/dotfiles.git
echo "Done"

echo "Setting Bash Environment"
cd dotfiles
# cp ./bashrc ~/.bashrc
# cp ./alias ~/.alias
# cp ./function ~/.function
# source ~/.bashrc
echo "Done"

echo "Installing Kitty"
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

echo "Installing kitty themes"
# Install themes for kitty
# git clone --depth 1 git@github.com:dexpota/kitty-themes.git ~/.config/kitty/kitty-themes
# cd ~/.config/kitty
# ln -s ./kitty-themes/themes/Zenburn.conf ~/.config/kitty/theme.conf
echo "Done"
