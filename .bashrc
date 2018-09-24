#!/usr/bin/env bash

export EDITOR=vim
export DISPLAY=:0
export PATH="$PATH:/cygdrive/c/cygwin64/bin/"
export PATH="$PATH:/cygdrive/c/Program Files/Sublime Text 3/"
export SVN="https://ins-p-build-v01.corp.ads:18080/svn/AMA_SVN"
if [[ -f  ~/.sonarFunction  ]]
then
	. ~/.sonarFunction
fi
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
alias ks='ls -CF --color=auto'
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'
alias write='/usr/bin/bsd-write'
alias nc='nc.traditional'
alias rc='. ~/.bashrc'
alias c='cd /cygdrive/c'
alias postgres='psql -hlocalhost --user postgres --password'
alias gituntrack='git update-index --skip-worktree'
alias gittrack='git update-index --no-skip-worktree'
alias listuntracked='git ls-files -v . | grep ^S'
alias search='find . | grep -i --color=always'
alias fix='kill -WINCH $$'
alias grep='grep --color=always'
alias nmap="/cygdrive/c/Program\ Files\ \(x86\)/Nmap/nmap.exe"
alias sqlite='sqlite3'
alias vi='vim'
alias findjar='/usr/bin/find . -name "*.jar" | xargs grep '
alias findgosu='grep -Rn --include=\*.{gs,gsx,etx,eti}'
alias findeti='/usr/bin/find . | grep "eti" | grep '
alias findetx='/usr/bin/find . | grep "etx" | grep '
alias findfile='/usr/bin/find . | grep '
alias dc='doing view color'
alias dn='doing now'
alias dl='doing later'
alias dsl='doing view later'
alias donetask='doing finish'

#alias makegs="for f in $(/usr/bin/find.exe .); do cp \"$f\" \"${f%.*}.gs\"; done"
#alias find="/usr/bin/find.exe"

#bind ctrl-m to reset terminal
if [[ $- == *i* ]]; then
	bind '"\C-o":"reset\C-m"'
fi

function getfromsvn(){
  svn co "https://ins-p-build-v01.corp.ads:18080/svn/AMA_SVN/$1"
}
#add dotifiles git alias
alias add='git add -A'
alias co='git commit'
alias push='git push'
alias st='git status'

#fix for mistyping vi
alias ci='vi'

#add install aliase
alias ins='sudo apt-get install'


function cloneFromVM() {
	git clone "http://192.168.61.131/root/$1.git"
}

# add node modules to path
export PATH="$PATH:$HOME/node_modules/.bin"

#add pip to path
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.pip"
export PATH="$PATH:$HOME/.gem/ruby/1.9.1/bin"
export PATH="$PATH:$HOME/.bin"
export PATH="$HOME/.bin/vagrant_1.7.4_x86/opt/vagrant/bin:$PATH"
export PATH="$PATH:~/apache-ant-1.7.1/bin"
export CLASSPATH="/usr/share/java/servlet-api-3.0.jar:$CLASSPATH"

parse_git_branch() {
	     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

#colorize
if [[ $- = *i* ]] ; then
    # Shell is non-interactive.  Be done now!
	export PS1="\[\033[38;5;39m\]\u\[$(tput sgr0)\]\[\033[38;5;158m\]@\[$(tput sgr0)\]\[\033[38;5;39m\]\h\[$(tput sgr0)\]\[\033[38;5;226m\]:\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;49m\]\w\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;81m\]\$(parse_git_branch)\[$(tput sgr0)\]\[\033[38;5;15m\]\n\[$(tput sgr0)\]\[\033[38;5;110m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"
	return
fi

