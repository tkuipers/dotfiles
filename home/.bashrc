eval "$(devbox global shellenv --recompute)"
if [ -z "$SSH_CONNECTION" ]; then
        eval "$(zellij setup --generate-auto-start bash)"
fi
eval "$(starship init bash)"

[ -f ~/.localrc ] && source ~/.localrc
[ -d /opt/homebrew/bin ] && export PATH=$PATH:/opt/homebrew/bin

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
alias gsr="git branch -a | grep "
#alias grxc="git restore --staged  modules/configuration/config/config.xml modules/configuration/config/database-config.xml studio/plugins/ij-studio/lib/studio-branding.jar  modules/configuration/config/plugin/registry/IBillingSummaryPlugin.gwp modules/configuration/config/plugin/registry/IBillingSystemPlugin.gwp"
alias grxc="git restore --staged  modules/configuration/config/config.xml modules/configuration/config/database-config.xml studio/plugins/ij-studio/lib/studio-branding.jar"
# git reset $(git merge-base origin/feature/PASO $(git branch --show-current))
alias ssh1p='ssh.exe'

export EDITOR=nvim

HISTSIZE=3000
HISTFILESIZE=4000
HISTTIMEFORMAT="%F %T "

function reset-lfs() {
    git rm --cached -r .
    git reset --hard
    git rm .gitattributes
    git reset .
    git checkout .
}

folder-size() {
  # Use the current directory if no directory is provided
  target_dir="${1:-.}"

  # Use du to calculate the size of each folder, then sort them in descending order
  du -sh "$target_dir"/* 2>/dev/null | sort -rh
}


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
