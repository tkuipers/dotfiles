export PATH="$PATH:/snap/bin"

# Start zellij and close terminal when it exits
if [ -z "$SSH_CONNECTION" ] && [ -z "$ZELLIJ" ]; then
    cd ~
    exec zellij
fi

eval "$(starship init bash)"

[ -f ~/.localrc ] && source ~/.localrc
[ -d /opt/homebrew/bin ] && export PATH=$PATH:/opt/homebrew/bin

alias ls='eza'
alias ks='eza'
alias ll='eza -al'
alias la='eza -a'
alias l='eza'
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
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export PATH="$PATH:$HOME/.local/bin"
export EZA_CONFIG_DIR="$HOME/.config/eza"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
####################
# Added by sway-wsl2
####################

# Set environment variables when running sway
if [[ $XDG_SESSION_DESKTOP == "sway" ]]; then
  # Default browser is "wslview"
  export BROWSER=firefox

  # Allows xdg-open to open programs within the VM, instead of windows
  export DE=generic

  # Allow VSCode to open within the VM instead of telling you to install it on windows
  export DONT_PROMPT_WSL_INSTALL=1

  # Uncomment to get kitty working. GTK_USE_PORTAL may break some other things so I left it disabled for now
  # Kitty is low resolution in WSL2 though for some reason? Would stick to xfce4-terminal or another terminal emulator
  # export GTK_USE_PORTAL=1
  # export LIBGL_ALWAYS_INDIRECT=0
  # export GALLIUM_DRIVER=llvmpipe
fi

