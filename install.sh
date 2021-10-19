#!/bin/bash

START_DIR=$(pwd)
TEMP_DIR="/tmp"
USER_HOME="$HOME"

echo "Getting Root"
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

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

echo "Installing kitty themes"
# Install themes for kitty
# git clone --depth 1 git@github.com:dexpota/kitty-themes.git ~/.config/kitty/kitty-themes
# cd ~/.config/kitty
# ln -s ./kitty-themes/themes/Zenburn.conf ~/.config/kitty/theme.conf
echo "Done"
