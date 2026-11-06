#/usr/bin/env bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

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

if [ ! -e "$HOME/.localrc" ]; then
    cp $SCRIPT_DIR/../home/.localrc $HOME/.localrc
fi

#link desktop extras
for dir in swaync wlogout lazygit fastfetch swayr; do
  ln -sfn $SCRIPT_DIR/../home/.config/$dir $HOME/.config/$dir
done

#link teams theme
mkdir -p $HOME/.config/teams-for-linux
ln -fs $SCRIPT_DIR/../home/.config/teams-for-linux/config.json $HOME/.config/teams-for-linux/config.json

#link the theme toggle, then render the chosen theme
ln -sfn $SCRIPT_DIR/../home/.config/sway/themes $HOME/.config/sway/themes
$SCRIPT_DIR/../home/.local/bin/theme-apply
