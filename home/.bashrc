eval "$(devbox global shellenv --recompute)"
eval "$(zellij setup --generate-auto-start bash)"
eval "$(starship init bash)"

alias ls='ls -CF --color=auto'
alias ks='ls -CF --color=auto'
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'
alias rc='source ~/.bashrc'
alias gituntrack='git update-index --skip-worktree'
alias gittrack='git update-index --no-skip-worktree'
alias listuntracked='git ls-files -v . | grep ^S'
alias grep='grep --color=always'
alias vi='vim'
alias ci='vi'
alias off='sudo shutdown -h now'
alias python=python3
alias screenseconds="xset dpms "
alias untrack="git update-index --assume-unchanged" 
alias track="git update-index --no-assume-unchanged" 

HISTSIZE=3000
HISTFILESIZE=4000
HISTTIMEFORMAT="%F %T "


