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
sudo apt-get install -y build-essential clang g++ python3.9-dev vim git libfontconfig1 nodejs

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
cp ./vimrc ~/.vimrc
cp ./secrets ~/.secrets
source ~/.bashrc

echo "Installing Kitty"
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
cp ./kitty.conf $USER_HOME/.config/kitty/kitty.conf

echo "Installing kitty themes"
git clone --depth 1 https://github.com/dexpota/kitty-themes.git $USER_HOME/.config/kitty/kitty-themes
cd ~/.config/kitty
ln -s ./kitty-themes/themes/Zenburn.conf ~/.config/kitty/theme.conf
cd $TEMP_DIR

echo "Setting Kitty as default terminal"
chmod 755 $HOME/.local/kitty.app/bin/kitty
ln -snf $HOME/.local/kitty.app/bin/kitty /usr/local/bin/kitty
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/kitty 50
alternatives --auto x-terminal-emulator

echo "Settin up Vim"
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall


echo "Installing i3 themer"
cd $TEMP_DIR
git clone https://github.com/cizordj/i3-themer.git
