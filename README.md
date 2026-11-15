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

`windows/` has the launcher. `Start-Weaselway.ps1` starts the session and both viewers, then fills each monitor with one.
`Weaselway-Taskbar.ps1` runs alongside and keeps the Windows taskbar hidden while a viewer is up; hold a Windows key with the mouse on the bottom edge, or just hover there with the power menu open, to bring it back.

## Otterway

`nixos#otterway` is the same desktop in [Otterway](https://github.com/shipwrecked/otterway)'s VM on a Mac (aarch64).
`nixos/common.nix` holds what both systems share; `configuration.nix` adds WSL's parts, `otterway.nix` the Mac's (the user, and a greetd autologin into Hyprland).
Apply it from the guest, then link the home files as on WSL:

```bash
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#otterway
./script/install.sh
```

On the Mac, `hyprland.lua` leaves out Weaselway's monitor and pointer rules (Otterway's agent sets each display's size, scale and position from the Mac) and the Windows bridges (media keys, health log, clipboard: Otterway shares the Mac clipboard itself), and uses the hardware cursor.
Brave and Cider come from nixpkgs-unstable there and Anki is built from source, because the pinned nixpkgs has no aarch64 build of them.
Not on the Mac: the Outlook calendar on the bar (`agenda` asks Windows' Outlook), the virtual camera and the Windows taskbar flag of the power menu.

