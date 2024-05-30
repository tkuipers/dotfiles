eval "$(devbox global shellenv --recompute)"
eval "$(zellij setup --generate-auto-start bash)"
eval "$(starship init bash)"

alias ls='ls -CF --color=auto'
alias ks='ls -CF --color=auto'
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'
alias rc='source ~/.zshrc'
alias gituntrack='git update-index --skip-worktree'
alias gittrack='git update-index --no-skip-worktree'
alias listuntracked='git ls-files -v . | grep ^S'
alias grep='grep --color=always'
alias vi='vim'
alias ci='vi'
alias off='sudo shutdown -h now'
alias python=python3
alias start_video='recordmydesktop --windowid $(xwininfo | grep --color=never "id: 0x" | grep -Po --color=never "0x[\d]+") --stop-shortcut=Control+s'
alias screenseconds="xset dpms "
alias untrack="git update-index --assume-unchanged" 
alias track="git update-index --no-assume-unchanged" 
alias screenshot="import ~/Pictures/$(date '+%d%m%Y::%H%M%S').png"

HISTSIZE=3000
HISTFILESIZE=4000
HISTTIMEFORMAT="%F %T "


