#!/usr/bin/env bash

# Path to the bash it configuration
export BASH_IT="$HOME/.bash_it"

# Lock and Load a custom theme file
# location /.bash_it/themes/
export BASH_IT_THEME='luan'

# Your place for hosting Git repos. I use this for private repos.
export GIT_HOSTING='git@git.domain.com'

# Don't check mail when opening terminal.
unset MAILCHECK

#Add keybindings for scrolling using <ctrl>jkl;
bind '"\e^j":"\e[A"'


# Change this to your console based IRC client of choice.
export IRC_CLIENT='irssi'

# Set this to the command you use for todo.txt-cli
export TODO="t"

# Set this to false to turn off version control status checking within the prompt for all themes
export SCM_CHECK=true

#add directory listing aliases
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'

#add dotifiles git alias
alias add='git add -A'
alias co='git commit'
alias push='git push'
alias st='git status'

#add install aliases
alias ins='sudo apt-get install'

# https://github.com/xvzf/vcprompt
#export VCPROMPT_EXECUTABLE=~/.vcprompt/bin/vcprompt

# Load Bash It
source $BASH_IT/bash_it.sh

#Append the history file, don't delete it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000
