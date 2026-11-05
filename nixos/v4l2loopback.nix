# A virtual camera for the WSL kernel, built the way dxgdrm is so that it loads.
{ pkgs, dxgdrm }:

let
  release = "6.18.54.1-microsoft-standard-WSL2";
in
dxgdrm.packages.x86_64-linux."dxgdrm-${release}".overrideAttrs (old: {
  pname = "v4l2loopback-wsl";
  version = "0.15.3-${release}";
  src = pkgs.linuxPackages.v4l2loopback.src;

  # Module.symvers has no media symbols, because this kernel ships them as modules.
  # Those are built from the same tree only for their CRCs, and then thrown away.
  buildPhase = ''
    runHook preBuild
    flags="ARCH=x86_64 CROSS_COMPILE=$CROSS_COMPILE CC=$KGCC LOCALVERSION="
    media=$PWD/kernel/drivers/media
    cp -a $KDIR kernel
    chmod -R u+w kernel
    make -C kernel $flags -j$NIX_BUILD_CORES M=drivers/media/mc modules
    make -C kernel $flags -j$NIX_BUILD_CORES KBUILD_MODPOST_WARN=1 \
      KBUILD_EXTRA_SYMBOLS=$media/mc/Module.symvers M=drivers/media/v4l2-core modules
    make -C $KDIR $flags -j$NIX_BUILD_CORES M=$PWD \
      KBUILD_EXTRA_SYMBOLS="$media/mc/Module.symvers $media/v4l2-core/Module.symvers" modules
    rm -rf kernel
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    ''${CROSS_COMPILE}objcopy --strip-debug v4l2loopback.ko
    remove-references-to -t $KDIR v4l2loopback.ko
    install -Dm644 v4l2loopback.ko $out/lib/modules/${release}/extra/v4l2loopback.ko
    runHook postInstall
  '';
})
