#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
START_DIR=$(pwd)
TEMP_DIR="/tmp"
INSTALL_DIR="$HOME/.tk/"
USER_HOME="$HOME"
USER="$USER"

echo "Getting Root"
echo "Got Root"

apt update

echo "Installing tzdata, otherwise it needs to be reconfigured"
apt-get update
ln -fs /usr/share/zoneinfo/America/Edmonton /etc/localtime
apt-get install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata


echo "Installing Pre-Req Software"
apt-get install -y build-essential clang g++ git libfontconfig1 nodejs libncurses5-dev libncursesw5-dev make python3 python3-pip python3-dev python-is-python3 curl tree
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
source $HOME/.poetry/env

# echo "Installing Vim"
# cd $TEMP_DIR
# git clone https://github.com/vim/vim.git
# cd vim/src
# make
# make install

echo "Cloning dotfiles"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR
rm -r ./dotfiles 2> /dev/null
git clone --single-branch --branch major-refactor https://github.com/tkuipers/dotfiles.git $INSTALL_DIR
echo "Done"

# echo "Installing kitty"
# curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
# ln -s ~/.local/kitty.app/bin/kitty ~/.local/bin/
# cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
# cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
# sed -i "s|Icon=kitty|Icon=/home/$USER/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
# sed -i "s|Exec=kitty|Exec=/home/$USER/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
# echo "Done"

echo "Installing NVM"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
echo "Done"

echo "Installing tk"
cd $INSTALL_DIR
source ~/.poetry/env
ls
poetry install
poetry run tk/src/tk install default
# cat ~/.bashrc
. $HOME/.bashrc
# tk install arterys
# echo "-----------------------------------------------------------------------------"
# cat ~/.bashrc



cd $START_DIR