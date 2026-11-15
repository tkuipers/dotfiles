#!/usr/bin/env bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# backup existing configs if they exist
[ -d "$HOME/.config/waybar" ] && [ ! -L "$HOME/.config/waybar" ] && mv "$HOME/.config/waybar" "$HOME/.config/waybar.backup"
[ -d "$HOME/.config/sway" ] && [ ! -L "$HOME/.config/sway" ] && mv "$HOME/.config/sway" "$HOME/.config/sway.backup"
[ -d "$HOME/.config/wofi" ] && [ ! -L "$HOME/.config/wofi" ] && mv "$HOME/.config/wofi" "$HOME/.config/wofi.backup"
[ -d "$HOME/.config/polybar" ] && [ ! -L "$HOME/.config/polybar" ] && mv "$HOME/.config/polybar" "$HOME/.config/polybar.backup"

mkdir -p $HOME/.config/nvim
mkdir -p $HOME/.config/waybar
mkdir -p $HOME/.config/sway
mkdir -p $HOME/.config/wofi
mkdir -p $HOME/.config/polybar
mkdir -p $HOME/.config/alacritty
mkdir -p $HOME/.config/mise
mkdir -p $HOME/Pictures/Wallpapers
mkdir -p $HOME/.config/eza
mkdir -p $HOME/.config/git
mkdir -p $HOME/.config/systemd/user
mkdir -p $HOME/.local/bin

#link starship
ln -fs $SCRIPT_DIR/../home/.config/starship.toml $HOME/.config/starship.toml
#link wezterm
ln -fs $SCRIPT_DIR/../home/.wezterm.lua $HOME/.wezterm.lua
#link bashrc
ln -fs $SCRIPT_DIR/../home/.bashrc $HOME/.bashrc
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
#link eza theme
ln -fs $SCRIPT_DIR/../home/.config/eza/theme.yml $HOME/.config/eza/theme.yml
#link global gitignore
ln -fs $SCRIPT_DIR/../home/.config/git/ignore $HOME/.config/git/ignore
#link sway on wsl helpers
ln -fs $SCRIPT_DIR/../home/.local/bin/start-sway $HOME/.local/bin/start-sway
ln -fs $SCRIPT_DIR/../home/.local/bin/clipboard-to-win $HOME/.local/bin/clipboard-to-win
ln -fs $SCRIPT_DIR/../home/.local/bin/win-to-clipboard $HOME/.local/bin/win-to-clipboard
ln -fs $SCRIPT_DIR/../home/.local/bin/wallpaper-cycle $HOME/.local/bin/wallpaper-cycle
ln -fs $SCRIPT_DIR/../home/.local/bin/theme-apply $HOME/.local/bin/theme-apply
ln -fs $SCRIPT_DIR/../home/.local/bin/waybar-themed $HOME/.local/bin/waybar-themed
ln -fs $SCRIPT_DIR/../home/.local/bin/notification-panel $HOME/.local/bin/notification-panel
ln -fs $SCRIPT_DIR/../home/.local/bin/media-focus $HOME/.local/bin/media-focus
ln -fs $SCRIPT_DIR/../home/.config/systemd/user/win-to-clipboard.service $HOME/.config/systemd/user/win-to-clipboard.service
ln -sfn $SCRIPT_DIR/../home/.config/systemd/user/swaync.service.d $HOME/.config/systemd/user/swaync.service.d
#link mise
ln -fs $SCRIPT_DIR/../home/.config/mise/config.toml $HOME/.config/mise/config.toml
#download wallpapers
while read -r url; do
    file="$HOME/Pictures/Wallpapers/${url##*/}"
    [ -e "$file" ] || curl -fsSL -o "$file" "$url"
done < "$SCRIPT_DIR/wallpapers.txt"

# wallpaper-cycle looks in a folder per theme; until a theme has its own, it uses these
for theme in Aura Mocha; do
  # (a real folder: wallpaper-pick's find does not follow a symlinked one)
  folder=$HOME/Pictures/Wallpapers-$theme
  [ -L "$folder" ] && rm "$folder"
  [ -e "$folder" ] || { mkdir "$folder" && ln "$HOME"/Pictures/Wallpapers/* "$folder"/; }
done

if [ ! -e "$HOME/.localrc" ]; then
    cp $SCRIPT_DIR/../home/.localrc $HOME/.localrc
fi

#link the compositor-neutral helpers and the other compositors' configs
for script in wm theme-set session-switch notification-focus notification-urgent record-toggle keys glass; do
  ln -fs $SCRIPT_DIR/../home/.local/bin/$script $HOME/.local/bin/$script
done

#link desktop extras
for dir in swaync wlogout lazygit fastfetch swayr hypr mango theme weaselway quickshell; do
  ln -sfn $SCRIPT_DIR/../home/.config/$dir $HOME/.config/$dir
done

#link every script, including those not named above
for script in $SCRIPT_DIR/../home/.local/bin/*; do
  ln -fs "$script" "$HOME/.local/bin/${script##*/}"
done

#link the remaining configs
for dir in bat btop cider fzf wallpaper wiremix zathura mimeapps.list; do
  ln -sfn $SCRIPT_DIR/../home/.config/$dir $HOME/.config/$dir
done

#link teams theme
mkdir -p $HOME/.config/teams-for-linux
ln -fs $SCRIPT_DIR/../home/.config/teams-for-linux/config.json $HOME/.config/teams-for-linux/config.json

#link the theme toggle, then render the chosen theme
ln -sfn $SCRIPT_DIR/../home/.config/sway/themes $HOME/.config/sway/themes
$SCRIPT_DIR/../home/.local/bin/theme-apply
