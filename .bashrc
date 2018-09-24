#!/usr/bin/env bash

export EDITOR=vim
export DISPLAY=:0
export PATH="$PATH:/cygdrive/c/cygwin64/bin/"
export PATH="$PATH:/cygdrive/c/Program Files/Sublime Text 3/"
export SVN="https://ins-p-build-v01.corp.ads:18080/svn/AMA_SVN"

export PATH="$PATH:$HOME/node_modules/.bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.pip"
export PATH="$PATH:$HOME/.gem/ruby/1.9.1/bin"
export PATH="$PATH:$HOME/.bin"
export PATH="$HOME/.bin/vagrant_1.7.4_x86/opt/vagrant/bin:$PATH"
export PATH="$PATH:~/apache-ant-1.7.1/bin"
export CLASSPATH="/usr/share/java/servlet-api-3.0.jar:$CLASSPATH"
export GIT_EDITOR=vim
export MANPAGER="/bin/sh -c \"col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma' -\""

if [[ -f  ~/.alias  ]]
then
	. ~/.alias
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

if [[ $- = *i* ]] ; then
	export PS1="\[\033[38;5;39m\]\u\[$(tput sgr0)\]\[\033[38;5;158m\]@\[$(tput sgr0)\]\[\033[38;5;39m\]\h\[$(tput sgr0)\]\[\033[38;5;226m\]:\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;49m\]\w\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;81m\]\$(parse_git_branch)\[$(tput sgr0)\]\[\033[38;5;15m\]\n\[$(tput sgr0)\]\[\033[38;5;110m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
	return
fi

