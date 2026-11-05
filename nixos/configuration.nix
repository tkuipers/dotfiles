# The weaselway NixOS-WSL system. Edit it and run `sudo nixos-rebuild switch`.
{ pkgs, dxgdrm, ... }:

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
  fonts.packages = with pkgs; [ nerd-fonts.iosevka nerd-fonts.jetbrains-mono font-awesome ];
  environment.systemPackages = with pkgs; [
    swayfx swaybg waybar wofi alacritty wl-clipboard grim slurp xwayland jq libva-utils mesa-demos
    # GPU rasterization draws pages wrong on d3d12: stray triangles on buttons and off colors in text.
    (brave.override { commandLineArgs = "--ozone-platform=wayland --disable-gpu-rasterization"; })
    (writeShellScriptBin "custom-weaselway-session" ''
      export XDG_CURRENT_DESKTOP=sway
      # dxgdrm, not card0: from kernel 6.18.54.1 on card0 is WSL's vgem.
      export WLR_DRM_DEVICES=/dev/dri/by-path/platform-dxgdrm-card
      # The login session hands down CAP_WAKE_ALARM. Portals can't inspect a process
      # holding a capability they lack, so they would refuse every app in the session.
      exec ${util-linux}/bin/setpriv --inh-caps=-wake_alarm --ambient-caps=-wake_alarm sway "$@"
    '')

    # Shell
    zellij starship eza neovim ripgrep fd fzf bat tmux htop lazygit taskwarrior3
    lsof file tree ncdu unzip zip wget curl

    # Development
    git-lfs gh gcc gnumake pkg-config openssl python3 uv flutter android-tools
    nodejs go rustup maven jetbrains.idea claude-code

    cmake ninja meson clang pipx dotnetCorePackages.sdk_8_0 codex

    # Command line clients and utilities
    imagemagick pandoc poppler-utils sqlite mariadb.client dnsutils nmap whois samba
    yamllint silver-searcher unrar zstd xdg-utils wkhtmltopdf sqlcmd texliveMedium

    # Cloud
    kubectl kubernetes-helm terraform awscli2 azure-cli

    # bcp only. sqlcmd above is the Go client, and nixpkgs has no package for bcp.
    (stdenv.mkDerivation {
      pname = "mssql-tools18";
      version = "18.7.1.1-1";
      src = fetchurl {
        url = "https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/m/mssql-tools18/mssql-tools18_18.7.1.1-1_amd64.deb";
        sha256 = "1nyfhw39c1wvh3njpqc2s28wr2lkn9kfjjn4anj3izgk3xn4khyp";
      };
      nativeBuildInputs = [ dpkg autoPatchelfHook ];
      buildInputs = [ unixODBC libtool.lib stdenv.cc.cc.lib ];
      unpackPhase = "dpkg-deb -x $src .";
      installPhase = ''
        mkdir -p $out/bin
        cp -r opt $out/
        ln -s $out/opt/mssql-tools18/bin/bcp $out/bin/bcp
      '';
    })

    # Theme
    kmod usbutils v4l-utils ffmpeg-headless
    btop delta cliphist satty
    swaynotificationcenter wlogout lutgen fastfetch playerctl swayr
    (catppuccin-gtk.override { accents = [ "lavender" ]; variant = "mocha"; })
    (catppuccin-papirus-folders.override { flavor = "mocha"; accent = "lavender"; })
    catppuccin-cursors.mochaLavender

    # Applications
    vscode code-cursor bruno beekeeper-studio teams-for-linux firefox thunderbird
    zotero anki-bin
    # Outlook in an Electron wrapper. Not in nixpkgs, so this wraps the release AppImage.
    (let
      pname = "prospect-mail";
      version = "1.3.2";
      src = fetchurl {
        url = "https://github.com/julian-alarcon/prospect-mail/releases/download/v${version}/Prospect-Mail-${version}.AppImage";
        sha256 = "982b7d1bba8d89f8c4b028aed7b529976768b6f48091d6e8c2dcf45c8c47d064";
      };
      contents = appimageTools.extract { inherit pname version src; };
    in appimageTools.wrapType2 {
      inherit pname version src;
      # Without it Electron has no way to show notifications.
      extraPkgs = pkgs: [ pkgs.libnotify ];
      # On its default X11 path the window never appears.
      extraInstallCommands = ''
        source ${makeWrapper}/nix-support/setup-hook
        wrapProgram $out/bin/prospect-mail --add-flags "--ozone-platform=wayland --disable-gpu"
        install -Dm444 ${contents}/prospect-mail.desktop $out/share/applications/prospect-mail.desktop
        substituteInPlace $out/share/applications/prospect-mail.desktop --replace-fail 'Exec=AppRun' 'Exec=prospect-mail'
        cp -r ${contents}/usr/share/icons $out/share/icons
      '';
    })
    # Without libpulse, Cider's sound falls back to ALSA, which has no devices here.
    (cider-2.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [ makeWrapper ];
      postFixup = (old.postFixup or "") + ''
        wrapProgram $out/bin/cider-2 --prefix LD_LIBRARY_PATH : ${libpulseaudio}/lib
      '';
    }))
  ];

  # Separate from the Windows app, so it needs its own sign-in. Commit signing
  # and ssh.exe go through the Windows one.
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "nixos" ];
  };
  environment.etc."1password/custom_allowed_browsers" = {
    text = "brave\n";
    mode = "0755";
  };

  # usbipd attaches as root, which starts a root user manager. These would then run
  # there too, fail on the taken ports and retry forever, setting up the GPU each time.
  systemd.user.services.weaselwayd.unitConfig.ConditionUser = "!root";
  systemd.user.services.weaselwayd-2.unitConfig.ConditionUser = "!root";
  # win-to-clipboard carries the clipboard instead
  systemd.user.services.weaselwayd.serviceConfig.ExecStart = pkgs.lib.mkForce "${pkgs.weaselwayd}/bin/weaselwayd --follow-client --no-clipboard";

  # Teams sees these as "Weaselway" and "Webcam Mic". camera-toggle feeds them.
  systemd.services.weaselway-virtual-camera = {
    description = "Load the virtual camera";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.kmod ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      [ -d /sys/module/v4l2loopback ] && exit
      modprobe videodev
      insmod ${pkgs.callPackage ./v4l2loopback.nix { inherit dxgdrm; }}/lib/modules/$(uname -r)/extra/v4l2loopback.ko \
        devices=1 video_nr=10 card_label=Weaselway exclusive_caps=1
    '';
  };
  services.pipewire.extraConfig.pipewire."30-webcam-mic"."context.objects" = [
    {
      factory = "adapter";
      args = {
        "factory.name" = "support.null-audio-sink";
        "node.name" = "weaselway_camera_mic";
        "node.description" = "Webcam Mic";
        "media.class" = "Audio/Source/Virtual";
        "audio.position" = "[ MONO ]";
      };
    }
  ];

  # Other WSL distros share this kernel and /dev, and their udev resets the GPU
  # nodes when they start. Apps here then can't open them, so put them back.
  systemd.services.weaselway-dri-perms = {
    description = "Keep the dxgdrm device nodes open to Weaselway";
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ coreutils inotify-tools systemd ];
    serviceConfig.Restart = "always";
    script = ''
      until [ -d /dev/dri ]; do sleep 1; done
      while true; do
        for node in /dev/dri/by-path/platform-dxgdrm-*; do
          [ -e "$node" ] || continue
          if [ "$(stat -Lc %a "$node")" != 666 ]; then
            udevadm trigger --subsystem-match=drm --action=change
            udevadm settle --timeout=10
            break
          fi
        done
        inotifywait -qq -t 60 -e attrib -e create /dev/dri || true
      done
    '';
  };

  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "catppuccin-mocha-lavender-standard";
      icon-theme = "Papirus-Dark";
      cursor-theme = "catppuccin-mocha-lavender-cursors";
      font-name = "JetBrainsMono Nerd Font 11";
    };
  }];

  # Screen sharing. With two monitors, slurp asks which one to share.
  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      settings.screencast = {
        chooser_type = "simple";
        chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
      };
    };
    config.sway = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
    };
  };

  environment.sessionVariables.IDEA_HOME = "/home/nixos/idea/current";

  environment.unixODBCDrivers = with pkgs.unixODBCDrivers; [ msodbcsql18 ];

  # Same major version and locale as the Ubuntu cluster these databases came from.
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    extensions = ps: [ ps.postgis ];
    initdbArgs = [ "--encoding=UTF8" "--locale=C.UTF-8" ];
    settings.timezone = "America/Denver";
  };

  virtualisation.docker.enable = true;
  users.users.nixos.extraGroups = [ "docker" ];

  # Java 21 by default, and 17 for the projects that still need it.

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
  systemd.tmpfiles.rules = let
    # Guidewire Studio refuses any other IntelliJ version. nix-ld runs it unpatched.
    studioIdea = pkgs.runCommand "idea-2025.3.4" {
      src = pkgs.fetchurl {
        url = "https://download.jetbrains.com/idea/idea-2025.3.4.tar.gz";
        sha256 = "b86ddae3a3fd6c2afbaca160a3b7d54f4b4fa6d1361ac2616bdb7a6416632ea1";
      };
    } ''
      mkdir -p $out
      tar -xzf $src --strip-components=1 -C $out
    '';
  in [
    # ~/.localrc points IDEA_HOME here.
    "d /home/nixos/idea 0755 nixos users -"
    "L+ /home/nixos/idea/current - - - - ${studioIdea}"
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

  # Builds take only CPU nothing else wants. WSL's CPUs are Windows threads, so
  # a build on every core starves the viewer on Windows, and the sound pops.
  nix.daemonCPUSchedPolicy = "idle";

  # Realtime priority for PipeWire's audio threads.
  security.rtkit.enable = true;

  # Leave this at the release the distro was first installed with.
  time.timeZone = "America/Edmonton";
  system.stateVersion = "26.05";
}
