#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
START_DIR=$(pwd)
TEMP_DIR="/tmp"
USER_HOME="$HOME"
USER="$USER"

echo "Getting Root"
sudo echo "Got Root"

sudo add-apt-repository ppa:jonathonf/vim -y
sudo apt update

echo "Installing tzdata, otherwise it needs to be reconfigured"
sudo apt-get update
sudo ln -fs /usr/share/zoneinfo/America/Edmonton /etc/localtime
sudo apt-get install -y tzdata
sudo dpkg-reconfigure --frontend noninteractive tzdata


echo "Installing Pre-Req Software"
sudo apt-get install -y build-essential clang g++ git libfontconfig1 nodejs libncurses5-dev libncursesw5-dev make python3 python3-dev python-is-python3
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
source $HOME/.poetry/env

echo "Installing Vim"
cd $TEMP_DIR
git clone https://github.com/vim/vim.git
cd vim/src
make
sudo make install

echo "Cloning dotfiles"
cd $TEMP_DIR
rm -r ./dotfiles 2> /dev/null
git clone  https://github.com/tkuipers/dotfiles.git
echo "Done"

echo "Installing kitty"
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
ln -s ~/.local/kitty.app/bin/kitty ~/.local/bin/
cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
sed -i "s|Icon=kitty|Icon=/home/$USER/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
sed -i "s|Exec=kitty|Exec=/home/$USER/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
echo "Done"

echo "Installing NVM"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
echo "Done"

echo "Installing tk"



cd $START_DIR