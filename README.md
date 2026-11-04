# Dotfiles

This repository contains my dotfiles.  They are relatively simple and can be installed using
```sh
./script/install.sh
```

## Weaselway

`nixos/` is the NixOS system for the [Weaselway](https://github.com/tkuipers/weaselway/tree/two-displays) WSL distro: SwayFX on two displays, with the development tools. Apply it from the distro:

```bash
sudo nixos-rebuild boot --flake ~/dotfiles/nixos#nixos
```

`windows/` has the launcher. `Start-Weaselway.ps1` starts the session and both viewers, then maximizes one on each monitor.
