#/usr/bin/env bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

curl -fsSL https://get.jetify.com/devbox | bash

sudo chmod 755 /usr/local/bin/devbox

mkdir -p $HOME/.config/zellij/layouts
mkdir -p $HOME/.config/nvim

# symlink the devbox file
#link  devbox
ln -fs $SCRIPT_DIR/../devbox.json $(devbox global path -q)/devbox.json
#link starship
ln -fs $SCRIPT_DIR/../home/.config/starship.toml $HOME/.config/starship.toml
#link wezterm
ln -fs $SCRIPT_DIR/../home/.wezterm.lua $HOME/.wezterm.lua
#link bashrc
ln -fs $SCRIPT_DIR/../home/.bashrc $HOME/.bashrc
#link zellij
ln -fs $SCRIPT_DIR/../home/.config/zellij/config.kdl $HOME/.config/zellij/config.kdl
#link layouts for zellij
ln -fs $SCRIPT_DIR/../home/.config/zellij/layouts/terminal.kdl $HOME/.config/zellij/layouts/terminal.kdl
#link vimrc
#ln -fs $SCRIPT_DIR/../home/.vimrc $HOME/.vimrc
#vim +'PlugInstall --sync' +qa
# nvim config
ln -fs $SCRIPT_DIR/../home/.config/nvim/init.lua $HOME/.config/nvim/init.lua
#link taskwarrior
ln -fs $SCRIPT_DIR/../home/.taskrc $HOME/.taskrc

if [ ! -e "$HOME/.localrc" ]; then
    cp $SCRIPT_DIR/../home/.localrc $HOME/.localrc
fi
