# A virtual camera for the WSL kernel, built against the same kernel trees as
# dxgdrm, for every kernel release it supports, so that it loads.
{ pkgs, dxgdrm }:

dxgdrm.inputs.wsl-kernel.legacyPackages.x86_64-linux.mkModulesAll "v4l2loopback-wsl" (release: {
  pname = "v4l2loopback-wsl";
  version = "${pkgs.linuxPackages.v4l2loopback.version}-${release}";
  inherit release;
  # This kernel ships the media core as modules, so the tree's Module.symvers
  # has no media symbols. Building them gives v4l2loopback their CRCs; only
  # v4l2loopback is installed.
  targets = [
    "drivers/media/mc/mc.ko"
    "drivers/media/v4l2-core/videodev.ko"
  ];
  # videodev calls led_get/led_put, which this vmlinux lacks; it is thrown away,
  # so let modpost warn about them rather than stop.
  KBUILD_MODPOST_WARN = "1";
  external = pkgs.linuxPackages.v4l2loopback.src;
  install = [ "M/v4l2loopback.ko" ];
})
