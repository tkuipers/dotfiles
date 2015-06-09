#!/bin/bash

#Install bash_it
git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
bash ~/.bash_it/install.sh

#Install Pentadactyl
git clone https://github.com/5digits/dactyl.git ~/
make ~/dactyl
make install ~/dactyl/pentadactyl

#Install vim
vim +PluginInstall
bash ~/.vim/bundle/YouCompleteMe/install.sh
