eval "$(devbox global shellenv --recompute)"
eval "$(zellij setup --generate-auto-start bash)"
eval "$(starship init bash)"

[ -f ~/.localrc ] && source ~/.localrc

alias ls='exa'
alias ks='exa'
alias ll='exa -al'
alias la='exa -a'
alias l='exa'
alias rc='source ~/.bashrc'
alias gituntrack='git update-index --skip-worktree'
alias gittrack='git update-index --no-skip-worktree'
alias listuntracked='git ls-files -v . | grep ^S'
alias grep='grep --color=always'
alias vi='nvim'
alias vim='nvim'
alias ci='vi'
alias off='sudo shutdown -h now'
alias python=python3
alias screenseconds="xset dpms "
alias untrack="git update-index --assume-unchanged" 
alias track="git update-index --no-assume-unchanged" 
alias ai="gh-copilot suggest"

export EDITOR=nvim

HISTSIZE=3000
HISTFILESIZE=4000
HISTTIMEFORMAT="%F %T "


