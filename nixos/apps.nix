# The applications, dev tools and services every machine of mine runs (desktop.nix is the
# desktop itself).  Imported through common.nix.
{ config, lib, pkgs, unstable, ... }:

let
  # Downloads that come per architecture: the URL and hash for this machine's.
  arch = pkgs.stdenv.hostPlatform.system;
  pick = urls: urls.${arch} or (throw "no ${arch} download for this package");
  # Where the pinned nixpkgs has no aarch64 build (or no package at all), the Mac takes
  # it from unstable or builds it from source; WSL keeps what it had.
  onArm = arch == "aarch64-linux";
  brave = if onArm then unstable.brave else pkgs.brave; # removed from Otterway's nixpkgs
  cider-2 = if onArm then unstable.cider-2 else pkgs.cider-2; # x86_64-only in the pin
  anki = if onArm then pkgs.anki else pkgs.anki-bin; # anki-bin is x86_64-only
in
{
  environment.systemPackages = with pkgs; [
    # GPU rasterization draws pages wrong on d3d12: stray triangles on buttons and off colors in text.
    # Video flickering large parts of the page was fixed by weaselway v1.6.0's fence fixes in Mesa and
    # dxgdrm; before that, --disable-gpu-memory-buffer-video-frames and
    # --disable_post_sub_buffers_for_onscreen_surfaces worked around it.
    (brave.override { commandLineArgs = "--ozone-platform=wayland --disable-gpu-rasterization"; })

    # Development
    git-lfs gh gcc gnumake pkg-config openssl uv flutter android-tools
    nodejs go rustup maven jetbrains.idea claude-code

    cmake ninja meson clang pipx dotnetCorePackages.sdk_8_0 unstable.codex

    # Command line clients and utilities
    imagemagick pandoc poppler-utils sqlite mariadb.client dnsutils nmap whois samba
    yamllint silver-searcher unrar zstd xdg-utils wkhtmltopdf sqlcmd texliveMedium

    # Cloud
    kubectl kubernetes-helm terraform awscli2 azure-cli

    # bcp only. sqlcmd above is the Go client, and nixpkgs has no package for bcp.
    (stdenv.mkDerivation {
      pname = "mssql-tools18";
      version = "18.7.1.1-1";
      src = fetchurl (pick {
        x86_64-linux = {
          url = "https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/m/mssql-tools18/mssql-tools18_18.7.1.1-1_amd64.deb";
          sha256 = "1nyfhw39c1wvh3njpqc2s28wr2lkn9kfjjn4anj3izgk3xn4khyp";
        };
        aarch64-linux = {
          url = "https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/m/mssql-tools18/mssql-tools18_18.7.1.1-1_arm64.deb";
          sha256 = "0fh7affwksq54yxsga3h2p3sjyjz057pj0v8136sgrbk5qvd0p42";
        };
      });
      nativeBuildInputs = [ dpkg autoPatchelfHook ];
      buildInputs = [ unixODBC libtool.lib stdenv.cc.cc.lib ];
      unpackPhase = "dpkg-deb -x $src .";
      installPhase = ''
        mkdir -p $out/bin
        cp -r opt $out/
        ln -s $out/opt/mssql-tools18/bin/bcp $out/bin/bcp
      '';
    })

    # Applications
    # Teams hands its player paths inside app.asar, which only Electron can read,
    # so a pw-play in front of the real one plays an unpacked copy.
    (let
      sounds = runCommand "teams-for-linux-sounds" { nativeBuildInputs = [ asar ]; } ''
        app=${teams-for-linux}/share/teams-for-linux/app.asar
        mkdir $out && cd $out
        for sound in $(asar list $app | grep '^/app/assets/sounds/.*\.wav$'); do
          asar extract-file $app "''${sound#/}"
        done
      '';
      player = writeShellScriptBin "pw-play" ''
        exec ${pipewire}/bin/pw-play "${sounds}/$(basename "''${@: -1}")"
      '';
    in symlinkJoin {
      name = "teams-for-linux";
      paths = [ teams-for-linux ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/teams-for-linux --prefix PATH : ${player}/bin";
    })
    vscode code-cursor bruno beekeeper-studio firefox thunderbird
    # From unstable: the library was last opened by Zotero 10, which the pinned 9.x refuses.
    unstable.zotero anki
    # Outlook in an Electron wrapper. Not in nixpkgs, so this wraps the release AppImage.
    (let
      pname = "prospect-mail";
      version = "1.3.2";
      src = fetchurl (pick {
        x86_64-linux = {
          url = "https://github.com/julian-alarcon/prospect-mail/releases/download/v${version}/Prospect-Mail-${version}.AppImage";
          sha256 = "982b7d1bba8d89f8c4b028aed7b529976768b6f48091d6e8c2dcf45c8c47d064";
        };
        aarch64-linux = {
          url = "https://github.com/julian-alarcon/prospect-mail/releases/download/v${version}/Prospect-Mail-${version}-arm64.AppImage";
          sha256 = "0flwfz6hqpav9q45bl38pw2ri6i0d5hr3vkscsavq70bidhwrqmx";
        };
      });
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
      stdenv.cc.cc zlib zstd openssl curl icu libxml2 libyaml libffi readline ncurses sqlite
      glib nss nspr alsa-lib freetype fontconfig expat dbus
      libx11 libxext libxrender libxtst libxi libxcursor libxrandr libxcomposite libxdamage libxfixes
      libxcb libxkbcommon libdrm libgbm wayland gtk3 pango cairo atk at-spi2-atk at-spi2-core cups
    ];
  };

  # IntelliJ where ~/.localrc looks for it.
  systemd.tmpfiles.rules = let
    # Guidewire Studio refuses any other IntelliJ version. nix-ld runs it unpatched.
    studioIdea = pkgs.runCommand "idea-2025.3.4" {
      src = pkgs.fetchurl (pick {
        x86_64-linux = {
          url = "https://download.jetbrains.com/idea/idea-2025.3.4.tar.gz";
          sha256 = "b86ddae3a3fd6c2afbaca160a3b7d54f4b4fa6d1361ac2616bdb7a6416632ea1";
        };
        aarch64-linux = {
          url = "https://download.jetbrains.com/idea/idea-2025.3.4-aarch64.tar.gz";
          sha256 = "14ksffc8pcas257b40b2z7x3vqnjymibxv51xchnslx1gnrqdgbp";
        };
      });
    } ''
      mkdir -p $out
      tar -xzf $src --strip-components=1 -C $out
    '';
  in [
    # ~/.localrc points IDEA_HOME here.
    "d /home/nixos/idea 0755 nixos users -"
    "L+ /home/nixos/idea/current - - - - ${studioIdea}"
  ];
}
