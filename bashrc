#!/usr/bin/env bash
export TERMINAL=alacritty
export EDITOR=vim
export DISPLAY=:0
export PATH="$PATH:/cygdrive/c/cygwin64/bin/"
export PATH="$PATH:/cygdrive/c/Program Files/Sublime Text 3/"
export SVN="https://ins-p-build-v01.corp.ads:18080/svn/AMA_SVN"
export LD_LIBRARY_PATH=. # required for running test programs in build/release/bin
export SCONSFLAGS=-j12
export ARTERYS_MIDDLE_ROOT="$HOME/Arterys/middle"
export ARTERYS_DICOMM_ROOT="$HOME/Arterys/arterys-dicomweb-server"

export BAT_THEME=zenburn
export PATH="$PATH:$HOME/node_modules/.bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.pip"
export PATH="$PATH:$HOME/.gem/ruby/1.9.1/bin"
export PATH="$PATH:$HOME/.bin"
export PATH="$HOME/.bin/vagrant_1.7.4_x86/opt/vagrant/bin:$PATH"
export PATH="$HOME/WebStorm/bin:$PATH"
export PATH="$PATH:~/apache-ant-1.7.1/bin"
export JAVA_HOME="/usr/bin/jdk1.6.0_45/"
export PATH="$PATH:$JAVA_HOME/bin"
export UAA_JAVA_CMD="/home/administrator/Downloads/jdk1.8.0_241/bin/java"
export ANT_HOME="/usr/bin/apache-ant-1.7.1/"
export PATH="$PATH:$ANT_HOME/bin"
export NODE_HOME="/usr/bin/node-v7.2.1-linux-x64/"
export WEBSTORM_HOME="$HOME/WebStorm"
export PATH="$PATH:$WEBSTORM_HOME/bin"
export PATH="$PATH:$NODE_HOME/bin"
export KITTY_HOME="/usr/bin/kitty.app"
export PATH="$PATH:$KITTY_HOME/bin"
export SCRIPTS_HOME="$HOME/.scripts"
export PATH="$PATH:$SCRIPTS_HOME"
export PC_HOME="$HOME/PolicyCenter"
export PATH="$PATH:$PC_HOME/bin"
export POSTMAN_HOME="$HOME/Downloads/Postman"
export PATH="$PATH:$POSTMAN_HOME"
export INTELLIJ_HOME="$HOME/Downloads/idea-IC-193.5233.102"
export PATH="$PATH:$INTELLIJ_HOME/bin"
export PYCHARM_HOME="$HOME/Downloads/pycharm-community-2020.1/"
export PATH="$PATH:$PYCHARM_HOME/bin"
export GRADLE_HOME="$HOME/Downloads/gradle-2.14.1-bin"
export PATH="$PATH:$GRADLE_HOME/bin"
export FLUTTER_HOME="$HOME/flutter"
export PATH="$PATH:$FLUTTER_HOME/bin"
export GO_HOME="$HOME/go"
export PATH="$PATH:$GO_HOME/bin"


export AGL_TOP=$HOME/workspace_agl
export CLASSPATH="/usr/share/java/servlet-api-3.0.jar:$CLASSPATH"
export GIT_EDITOR=vim
export MANPAGER="/bin/sh -c \"col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma' -\""

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
if [[ -f  ~/.alias  ]]
then
	. ~/.alias
fi

if [[ -f  ~/.function  ]]
then
	. ~/.function
fi

if [[ -f  ~/.tizonia  ]]
then
	. ~/.tizonia
fi

source /usr/share/bash-completion/completions/git

if [[ -f  /usr/share/bash-completion/completions/git  ]]
then
	. /usr/share/bash-completion/completions/git
fi

shopt -s histappend
HISTCONTROL=ignoreboth

HISTSIZE=1000
HISTFILESIZE=2000

if [[ $- == *i* ]]; then
	bind '"\C-o":"reset\C-m"'
fi

function getfromsvn(){
  svn co "https://ins-p-build-v01.corp.ads:18080/svn/AMA_SVN/$1"
}

parse_git_branch() {
	     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

function configs() {
	cp ~/.gwconfigs/ClaimCenter/$1config.xml ~/gw/ClaimCenter/modules/configuration/config/config.xml
	cp ~/.gwconfigs/PolicyCenter/$1config.xml ~/gw/PolicyCenter/modules/configuration/config/config.xml
	cp ~/.gwconfigs/BillingCenter/$1config.xml ~/gw/BillingCenter/modules/configuration/config/config.xml
	cp ~/.gwconfigs/ContactManager/$1config.xml ~/gw/ContactManager/modules/configuration/config/config.xml
	cp ~/.gwconfigs/SuiteConfig/$1suite-config.xml ~/gw/PolicyCenter/modules/configuration/config/suite/suite-config.xml
	cp ~/.gwconfigs/SuiteConfig/$1suite-config.xml ~/gw/BillingCenter/modules/configuration/config/suite/suite-config.xml
	cp ~/.gwconfigs/SuiteConfig/$1suite-config.xml ~/gw/ClaimCenter/modules/configuration/config/suite/suite-config.xml
	cp ~/.gwconfigs/SuiteConfig/$1suite-config.xml ~/gw/ContactManager/modules/configuration/config/suite/suite-config.xml
}

function resetConfig() {
	git checkout HEAD^ modules/configuration/config/config.xml
	git checkout HEAD^ modules/configuration/config/suite/suite-config.xml
}

function gittrim(){
	git fetch --prune
	git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d
}

function gitforcetrim(){
	git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -D
}

function rnbwdirs(){
	dirs #  | lolcat -f --freq=0.5
}

function cpyuppers(){
	for f in $(find . -maxdepth 1 -printf '%P\n')
	do
		if [ -f ../$f ]; then
			cp -r ../$f $f
		fi
	done
}

function cpylower(){
	for f in $(find $1 -maxdepth 1 -printf '%P\n')
	do
		if [ -f $f ]; then
			cp -r ../$f $f
		fi
	done
}
if [[ $- = *i* ]] ; then
	export PS1="\[\033[38;5;39m\]\u\[$(tput sgr0)\]\[\033[38;5;158m\]@\[$(tput sgr0)\]\[\033[38;5;39m\]\h\[$(tput sgr0)\]\[\033[38;5;226m\]:\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;36m\]\$(rnbwdirs)\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;81m\]\$(parse_git_branch)\[$(tput sgr0)\]\[\033[38;5;15m\]\n\[$(tput sgr0)\]\[\033[38;5;110m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
	return
fi
export DOCKER_HOST=tcp://localhost:2375

# compton --config $HOME/.config/compton/compton.conf &
source /home/administrator/Arterys/phi-home/phi-service-run/arterys-phi/cli/lib/bashrc.sh
