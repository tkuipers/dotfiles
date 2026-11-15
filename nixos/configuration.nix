# The weaselway NixOS-WSL system. Edit it and run `sudo nixos-rebuild switch`.
# What it shares with the Otterway (Mac) system is in common.nix.
{ config, pkgs, dxgdrm, unstable, ... }:

{
  imports = [ ./common.nix ];

  nixpkgs.hostPlatform = "x86_64-linux";

  wsl.enable = true;
  # uid 1000: WSL only wires up /run/user/1000.
  wsl.defaultUser = "nixos";

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

  environment.systemPackages = with pkgs; [
    # The compositor is sway unless ~/.config/weaselway/session names another (hyprland
    # or mango). `session-switch` picks one for the next start only. If anything but
    # sway quits within a minute of starting, the session carries on in sway.
    (writeShellScriptBin "custom-weaselway-session" ''
      # dxgdrm, not card0: from kernel 6.18.54.1 on card0 is WSL's vgem.
      card=/dev/dri/by-path/platform-dxgdrm-card
      export WLR_DRM_DEVICES=$card AQ_DRM_DEVICES=$card
      next=$XDG_RUNTIME_DIR/weaselway-session-next
      if [ -f "$next" ]; then
        session=$(cat "$next")
        rm -f "$next"
      else
        session=$(${gnugrep}/bin/grep -m1 -oE '^[a-z]+' "$HOME/.config/weaselway/session" 2>/dev/null)
      fi
      # The login session hands down CAP_WAKE_ALARM. Portals can't inspect a process
      # holding a capability they lack, so they would refuse every app in the session.
      run=(${util-linux}/bin/setpriv --inh-caps=-wake_alarm --ambient-caps=-wake_alarm)
      case $session in
        # Not the /run/wrappers one: its capabilities make glibc ignore LD_LIBRARY_PATH,
        # so Mesa's GBM can't find the d3d12 driver in /run/opengl-driver/lib.
        hyprland) compositor=${config.programs.hyprland.package}/bin/Hyprland desktop=Hyprland ;;
        mango) compositor=mango desktop=mango:wlroots ;;
      esac
      if [ -n "$compositor" ]; then
        started=$SECONDS
        XDG_CURRENT_DESKTOP=$desktop "''${run[@]}" "$compositor" "$@"
        status=$?
        if [ "$status" -eq 0 ] || [ $((SECONDS - started)) -ge 60 ]; then exit "$status"; fi
        echo "$compositor quit with $status after $((SECONDS - started))s; starting sway" >&2
      fi
      export XDG_CURRENT_DESKTOP=sway
      exec "''${run[@]}" sway "$@"
    '')
  ];

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

  # Builds take only CPU nothing else wants. WSL's CPUs are Windows threads, so
  # a build on every core starves the viewer on Windows, and the sound pops.
  nix.daemonCPUSchedPolicy = "idle";
}
