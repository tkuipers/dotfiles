#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
START_DIR=$(pwd)
TEMP_DIR="/tmp"
USER_HOME="$HOME"
USER="$USER"

echo "Installing tzdata, otherwise it needs to be reconfigured"
apt-get update
ln -fs /usr/share/zoneinfo/America/Edmonton /etc/localtime
apt-get install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata

echo "Getting Root"
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

echo "Installing Pre-Req Software"
apt-get install -y build-essential clang g++ python3.9-dev vim git libfontconfig1

echo "Cloning dotfiles"
cd $TEMP_DIR
rm -r ./dotfiles 2> /dev/null
git clone  https://github.com/tkuipers/dotfiles.git
echo "Done"

echo "Setting Bash Environment"
cd dotfiles
cp ./bashrc ~/.bashrc
cp ./alias ~/.alias
cp ./function ~/.function
source ~/.bashrc

echo "Installing Kitty"
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
cp ./kitty.conf $USER_HOME/.config/kitty/kitty.conf

echo "Installing kitty themes"
git clone --depth 1 git@github.com:dexpota/kitty-themes.git $USER_HOME/.config/kitty/kitty-themes
cd ~/.config/kitty
ln -s ./kitty-themes/themes/Zenburn.conf ~/.config/kitty/theme.conf
cd $TEMP_DIR

echo "Setting Kitty as default terminal"
chmod 755 $HOME/.local/bin/kitty
ln -snf $HOME/.local/bin/kitty /usr/local/bin/kitty
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/kitty 50
alternatives --auto x-terminal-emulator
