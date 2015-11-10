#!/usr/bin/env bash

#Append the history file, don't delete it
shopt -s histappend

#don't put duplicates or lines starting with space in the history file

HISTCONTROL=ignoreboth

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

#unset git editor
export GIT_EDITOR=vim

#change the default pager to man
export MANPAGER="/bin/sh -c \"col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma' -\""

#add directory listing aliases
alias ls='ls -CF --color=auto'
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'
alias write='/usr/bin/bsd-write'
alias nc='nc.traditional'

#bind ctrl-m to reset terminal
if [[ $- == *i* ]]; then
	bind '"\C-o":"reset\C-m"'
fi

#add dotifiles git alias
alias add='git add -A'
alias co='git commit'
alias push='git push'
alias st='git status'

#fix for mistyping vi
alias ci='vi'

#add install aliase
alias ins='sudo apt-get install'


# add node modules to path
export PATH="$PATH:$HOME/node_modules/.bin"

#add pip to path
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.pip"
export PATH="$PATH:$HOME/.gem/ruby/1.9.1/bin"
export PATH="$PATH:$HOME/.bin"
export PATH="$HOME/.bin/vagrant_1.7.4_x86/opt/vagrant/bin:$PATH"
export CLASSPATH="/usr/share/java/servlet-api-3.0.jar:$CLASSPATH"

#colorize
if [[ $- = *i* ]] ; then
    # Shell is non-interactive.  Be done now!
	export PS1="\[\033[38;5;39m\]\u\[$(tput sgr0)\]\[\033[38;5;158m\]@\[$(tput sgr0)\]\[\033[38;5;39m\]\h\[$(tput sgr0)\]\[\033[38;5;226m\]:\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;49m\]\w\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;15m\]\n\[$(tput sgr0)\]\[\033[38;5;110m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
	return
fi
