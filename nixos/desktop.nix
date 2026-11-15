# The desktop every machine of mine runs, whatever it runs on: the compositors, bar,
# notifications, launcher, themes, fonts and shell tools.  common.nix adds apps.nix (the
# applications, dev tools and services); Otterway's nixos#otterway-desktop runs this alone.
{ config, lib, pkgs, ... }:

{
  # For the lock screen. Change it with `passwd`.
  users.users.nixos.initialPassword = "nixos";

  # SSH, for debugging. Change the password first, or add a key to
  # users.users.nixos.openssh.authorizedKeys.
  # services.openssh.enable = true;

  # Sway session and desktop tools. SwayFX installs as `sway`.
  nixpkgs.config.allowUnfree = true;
  fonts.packages = with pkgs; [ nerd-fonts.iosevka nerd-fonts.jetbrains-mono font-awesome ];
  environment.systemPackages = with pkgs; [
    swayfx swaybg waybar wofi alacritty wl-clipboard grim slurp xwayland jq libva-utils mesa-demos
    # Floating pill tabs for Hyprland groups (~/.config/quickshell/grouptabs)
    quickshell
    wlrctl wlr-randr

    # Shell
    starship eza neovim ripgrep fd fzf bat tmux htop lazygit taskwarrior3
    lsof file tree ncdu unzip zip wget curl
    # theme-apply
    python3

    # Theme
    kmod usbutils v4l-utils ffmpeg-headless
    btop delta cliphist satty awww zathura wiremix
    # swaync's media player puts artist and album on one line, and clicking it does nothing
    (swaynotificationcenter.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace src/controlCenter/widgets/mpris/mpris_player.vala \
          --replace-fail 'string.joinv (" - ", { artist, album })' 'string.joinv ("\n", { artist, album })'
        substituteInPlace src/controlCenter/widgets/mpris/mpris_player.vala \
          --replace-fail 'sub_title.set_text (result);' 'if (album == null && artist != null) {
                result = artist;
            }
            sub_title.set_text (result);'
        substituteInPlace src/controlCenter/widgets/mpris/mpris.vala \
          --replace-fail 'metadata == null || metadata.size () == 0' '
            metadata == null || !metadata.contains ("xesam:title")
            || metadata["xesam:title"].get_string ().length == 0'
        substituteInPlace src/controlCenter/widgets/mpris/mpris_player.vala \
          --replace-fail '/* Callbacks */' 'var open_player = new Gtk.GestureClick ();
            open_player.released.connect (() => {
                try {
                    Process.spawn_command_line_async (Environment.get_home_dir ()
                        + "/.local/bin/media-focus "
                        + (source.media_player as DBusProxy).get_name ());
                } catch (SpawnError e) {
                    warning ("%s", e.message);
                }
            });
            add_controller (open_player);'
      '';
    }))
    wlogout lutgen fastfetch playerctl swayr
    (catppuccin-gtk.override { accents = [ "lavender" ]; variant = "mocha"; })
    (catppuccin-papirus-folders.override { flavor = "mocha"; accent = "lavender"; })
    # One per theme; theme-apply picks it from the theme's "# cursor:" line
    phinger-cursors
    # Alt+Shift+r records a region (record-toggle)
    wf-recorder
  ];

  # Waybar's Hyprland workspaces send Hyprland's old text dispatchers, which a Lua
  # config refuses, so clicking a workspace did nothing. These are the Lua forms.
  # It also shows each app's icon once per workspace, however many windows of it
  # are open there.
  nixpkgs.overlays = [
    (final: prev: {
      waybar = prev.waybar.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/modules/hyprland/workspace.cpp \
            --replace-fail '"dispatch focusworkspaceoncurrentmonitor " + std::to_string(id())' \
              '"dispatch hl.dsp.focus({ workspace = " + std::to_string(id()) + " })"' \
            --replace-fail '"dispatch workspace " + std::to_string(id())' \
              '"dispatch hl.dsp.focus({ workspace = " + std::to_string(id()) + " })"' \
            --replace-fail '"dispatch focusworkspaceoncurrentmonitor name:" + name()' \
              '"dispatch hl.dsp.focus({ workspace = \"name:" + name() + "\" })"' \
            --replace-fail '"dispatch workspace name:" + name()' \
              '"dispatch hl.dsp.focus({ workspace = \"name:" + name() + "\" })"' \
            --replace-fail '"dispatch togglespecialworkspace " + name()' \
              '"dispatch hl.dsp.workspace.toggle_special(\"" + name() + "\")"' \
            --replace-fail '"dispatch togglespecialworkspace"' \
              '"dispatch hl.dsp.workspace.toggle_special()"' \
            --replace-fail 'bool isNotFirst = false;' \
              'bool isNotFirst = false; std::vector<std::string> seenRewrites;' \
            --replace-fail 'windows.append(windowSeparator);' \
              'if (std::ranges::find(seenRewrites, window_repr.repr_rewrite) == seenRewrites.end()) windows.append(windowSeparator);' \
            --replace-fail 'windows.append(window_repr.repr_rewrite);' \
              'if (std::ranges::find(seenRewrites, window_repr.repr_rewrite) == seenRewrites.end()) { windows.append(window_repr.repr_rewrite); seenRewrites.push_back(window_repr.repr_rewrite); }'
        '';
      });
    })
  ];

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

  # Alternatives to sway, picked with `session-switch`. Their modules bring their
  # portals for screen sharing.
  programs.hyprland.enable = true;

  # Index the icon themes. Without the caches GTK scans Papirus's thousands of
  # icons (and breeze and hicolor behind it) on every launch, so wofi took
  # ~400 ms after appearing before it would take keys.
  gtk.iconCache.enable = true;
  # Screen shaders also get focused_output, previous_output and focus_time, so the
  # weather glass can follow focus between screens without being recompiled.
  programs.hyprland.package = pkgs.hyprland.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/hyprland-focus-uniforms.patch
      # Weaselway's pointer is absolute (it follows the Windows cursor), and
      # Hyprland didn't end absolute motion with wl_pointer.frame, so Alacritty
      # only saw a drag on release
      ./patches/hyprland-absolute-pointer-frame.patch
    ];
  });
  programs.mangowc.enable = true;

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


  # Realtime priority for PipeWire's audio threads.
  security.rtkit.enable = true;

  # Leave this at the release the distro was first installed with.
  time.timeZone = "America/Edmonton";
  system.stateVersion = "26.05";
}
