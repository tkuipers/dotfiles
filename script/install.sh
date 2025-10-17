#/usr/bin/env bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

mkdir -p $HOME/.config/zellij/layouts
mkdir -p $HOME/.config/nvim
mkdir -p $HOME/.config/waybar
mkdir -p $HOME/.config/sway
mkdir -p $HOME/.config/wofi
mkdir -p $HOME/.config/polybar
mkdir -p $HOME/.config/alacritty

# backup existing configs if they exist
[ -d "$HOME/.config/waybar" ] && [ ! -L "$HOME/.config/waybar" ] && mv "$HOME/.config/waybar" "$HOME/.config/waybar.backup"
[ -d "$HOME/.config/sway" ] && [ ! -L "$HOME/.config/sway" ] && mv "$HOME/.config/sway" "$HOME/.config/sway.backup"
[ -d "$HOME/.config/wofi" ] && [ ! -L "$HOME/.config/wofi" ] && mv "$HOME/.config/wofi" "$HOME/.config/wofi.backup"
[ -d "$HOME/.config/polybar" ] && [ ! -L "$HOME/.config/polybar" ] && mv "$HOME/.config/polybar" "$HOME/.config/polybar.backup"

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
#link waybar
ln -fs $SCRIPT_DIR/../home/.config/waybar/config $HOME/.config/waybar/config
#link sway
ln -fs $SCRIPT_DIR/../home/.config/sway/config $HOME/.config/sway/config
ln -fs $SCRIPT_DIR/../home/.config/sway/config.d $HOME/.config/sway/config.d
#link wofi
ln -fs $SCRIPT_DIR/../home/.config/wofi/config $HOME/.config/wofi/config
ln -fs $SCRIPT_DIR/../home/.config/wofi/style.css $HOME/.config/wofi/style.css
#link polybar
ln -fs $SCRIPT_DIR/../home/.config/polybar/config $HOME/.config/polybar/config
ln -fs $SCRIPT_DIR/../home/.config/polybar/executable_i3wmthemer_bar_launch.sh $HOME/.config/polybar/executable_i3wmthemer_bar_launch.sh
ln -fs $SCRIPT_DIR/../home/.config/polybar/executable_spotify.sh $HOME/.config/polybar/executable_spotify.sh
#link alacritty
ln -fs $SCRIPT_DIR/../home/.config/alacritty/alacritty.toml $HOME/.config/alacritty/alacritty.toml
#link taskwarrior
ln -fs $SCRIPT_DIR/../home/.taskrc $HOME/.taskrc

if [ ! -e "$HOME/.localrc" ]; then
    cp $SCRIPT_DIR/../home/.localrc $HOME/.localrc
fi
