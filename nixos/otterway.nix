# The Otterway system: the same desktop as Weaselway (desktop.nix), in a VM on a Mac
# (aarch64-linux, libkrun).  Otterway's NixOS module brings the kernel, Mesa (Venus/Zink),
# otter-agent, PipeWire on virtio-snd, the shared folders, the network and the boot
# hand-off; this file adds what Weaselway's module and NixOS-WSL did on WSL: the user and
# the session.
#
# Apply it in the guest:
#   sudo nixos-rebuild switch --flake ~/dotfiles/nixos#otterway           (desktop + apps)
#   sudo nixos-rebuild switch --flake ~/dotfiles/nixos#otterway-desktop   (desktop only)
# The next VM start boots it.  Home files: ./script/install.sh, as on WSL.
{ config, lib, pkgs, otterwayInput, ... }:

let
  # Hyprland with the user's config.  start-hyprland is Hyprland's watchdog launcher
  # (without it Hyprland draws a warning banner).
  session = pkgs.writeShellScript "otterway-hyprland-session" ''
    set -eu
    export XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=Hyprland
    # ~/.config/hypr/hyprland.lua leaves out Weaselway's monitors and Windows bridges.
    export DESKTOP_HOST=otterway
    # greetd's session gets no locale from PAM; apps would run in "C".
    export LANG=${config.i18n.defaultLocale}
    # GL comes from Zink on Venus (the virtio-gpu path to the Mac's GPU).
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    exec systemd-cat --identifier=compositor start-hyprland -- -c "$HOME/.config/hypr/hyprland.lua"
  '';
in
{
  imports = [ ./desktop.nix ];  # the flake adds ./apps.nix for nixos#otterway

  otterway.enable = true;

  users.users.nixos = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "video" "audio" "input" "render" ];
  };

  nixpkgs.overlays = [
    (final: prev: {
      # Otterway's one compositor-side patch: Hyprland's hardware cursor on virtio-gpu,
      # so the guest's cursor is the Mac's pointer (Otterway P2.8).
      aquamarine = prev.aquamarine.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [
          "${otterwayInput}/guest/nixos/patches/aquamarine/0001-drm-use-virtual-GPUs-cursor-plane.patch"
        ];
        # Two jobs: more run Otterway's 4 GB Linux builder out of memory.
        preBuild = (o.preBuild or "") + "\nNIX_BUILD_CORES=2\n";
      });
      # Built from source (the patches above and in common.nix keep it out of every
      # binary cache).  On Otterway's 4 GB Linux builder more jobs run out of memory.
      hyprland = prev.hyprland.overrideAttrs (o: {
        preBuild = (o.preBuild or "") + "\nNIX_BUILD_CORES=2\n";
      });
      # Rebuilt against that Hyprland; same limit.
      xdg-desktop-portal-hyprland = prev.xdg-desktop-portal-hyprland.overrideAttrs (o: {
        preBuild = (o.preBuild or "") + "\nNIX_BUILD_CORES=2\n";
      });
    })
  ];

  # Log straight into Hyprland, every time: if the session exits, greetd starts it again.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = { command = "${session}"; user = "nixos"; };
      default_session = { command = "${session}"; user = "nixos"; };
    };
  };
  systemd.services."autovt@tty1".enable = false;
  # Start the session when the virtio-gpu device appears (not at graphical.target), and
  # without NixOS's Type=idle wait: the same as Otterway's own test system.
  systemd.services.greetd = {
    wantedBy = lib.mkForce [ ];
    unitConfig.ConditionPathExists = "/dev/dri/card0";
    serviceConfig.Type = lib.mkForce "simple";
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card0", TAG+="systemd", ENV{SYSTEMD_WANTS}+="greetd.service"
  '';
  security.polkit.enable = true;
}
