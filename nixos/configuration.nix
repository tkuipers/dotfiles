# The weaselway NixOS-WSL system. Edit it and run `sudo nixos-rebuild switch`.
{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "x86_64-linux";

  wsl.enable = true;
  # uid 1000: WSL only wires up /run/user/1000.
  wsl.defaultUser = "nixos";
  # For the lock screen. Change it with `passwd`.
  users.users.nixos.initialPassword = "nixos";

  weaselway.enable = true;
  # The GPU to render on, by a substring of its name.
  # weaselway.adapter = "nvidia";

  # Plasma, without a display manager: ww-start-session does its job.
  services.desktopManager.plasma6.enable = true;
  weaselway.session = "custom";
  weaselway.displays = 2;
  services.displayManager.sddm.enable = false;

  # Left out to keep the image under GitHub's 2 GiB limit. Delete a line and
  # rebuild to get it back.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    kwin-x11
    krdp
    plasma-workspace-wallpapers
  ];
  programs.kde-pim.enable = false;
  services.fwupd.enable = false;

  # No screen reader: orca needs speech-dispatcher, whose voices are ~650 MB of
  # the image. To get them back, delete both lines and rebuild.
  services.orca.enable = false;
  services.speechd.enable = false;

  # SSH, for debugging. Change the password first, or add a key to
  # users.users.nixos.openssh.authorizedKeys.
  # services.openssh.enable = true;

  # Sway session and desktop tools. SwayFX installs as `sway`.
  nixpkgs.config.allowUnfree = true;
  fonts.packages = with pkgs; [ nerd-fonts.iosevka nerd-fonts.jetbrains-mono ];
  environment.systemPackages = with pkgs; [
    swayfx swaybg waybar wofi alacritty wl-clipboard grim slurp xwayland jq libva-utils mesa-demos
    # GPU rasterization draws pages wrong on d3d12: stray triangles on buttons and off colors in text.
    (brave.override { commandLineArgs = "--ozone-platform=wayland --disable-gpu-rasterization"; })
    (writeShellScriptBin "custom-weaselway-session" ''
      export XDG_CURRENT_DESKTOP=sway
      # dxgdrm, not card0: from kernel 6.18.54.1 on card0 is WSL's vgem.
      export WLR_DRM_DEVICES=/dev/dri/by-path/platform-dxgdrm-card
      exec sway "$@"
    '')

    # Shell
    zellij starship eza neovim ripgrep fd fzf bat tmux htop lazygit taskwarrior3
    lsof file tree ncdu unzip zip wget curl

    # Development
    git-lfs gh gcc gnumake pkg-config openssl postgresql python3 uv flutter android-tools
    nodejs go rustup gradle maven jetbrains.idea claude-code

    # Cloud
    kubectl kubernetes-helm terraform awscli2 azure-cli

    # Applications
    vscode code-cursor bruno beekeeper-studio
  ];

  # Java 21 by default, and 17 for the projects that still need it.
  programs.java = {
    enable = true;
    package = pkgs.corretto21;
  };
  environment.etc."jdks/17".source = pkgs.corretto17;
  environment.etc."jdks/21".source = pkgs.corretto21;

  # Binaries downloaded for a regular Linux, such as JDKs, node and JetBrains IDEs.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc zlib zstd openssl curl icu libxml2 libyaml libffi readline ncurses
      glib nss nspr alsa-lib freetype fontconfig expat dbus
      libx11 libxext libxrender libxtst libxi libxcursor libxrandr libxcomposite libxdamage libxfixes
      libxcb libxkbcommon libdrm libgbm wayland gtk3 pango cairo atk at-spi2-atk at-spi2-core cups
    ];
  };

  # Paths Ubuntu had: scripts and symlinks in the copied home directory use them.
  systemd.tmpfiles.rules = [
    "L+ /home/administrator - - - - /home/nixos"
    "L+ /bin/bash - - - - /run/current-system/sw/bin/bash"
  ];

  # The system is a flake; git is needed for its git inputs.
  nix.channel.enable = false;
  programs.git.enable = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Leave this at the release the distro was first installed with.
  system.stateVersion = "26.05";
}
