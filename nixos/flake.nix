# The weaselway image's system flake. nixpkgs and NixOS-WSL come from
# weaselway's lock, so the patched packages match the binary cache.
# `sudo nix flake update --flake /etc/nixos` moves to the newest weaselway.
#
# Two systems: nixosConfigurations.nixos is Weaselway on WSL (x86_64), .otterway is the
# same desktop in Otterway's VM on a Mac (aarch64).  What they share is common.nix.
{
  inputs.weaselway.url = "github:tkuipers/weaselway/two-displays";
  # Only for packages the pinned nixpkgs is too old for (see `unstable` in configuration.nix).
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  # Otterway's guest layer and its nixpkgs (so the patched kernel and Mesa match the
  # binary cache the Mac serves to the guest).
  inputs.otterway.url = "git+ssh://git@github.com/shipwrecked/otterway?ref=main";

  outputs =
    { weaselway, nixpkgs-unstable, otterway, ... }:
    let
      unstableFor = system: import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        # Zotero 10 bundles Firefox ESR 140, end-of-life since 2026-10-13. Drop with the next Zotero.
        config.permittedInsecurePackages = [ "firefox-esr-140-bin-unwrapped-140.17.0esr" ];
      };
    in
    {
      nixosConfigurations.nixos = weaselway.inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit (weaselway.inputs) dxgdrm;
          unstable = unstableFor "x86_64-linux";
        };
        modules = [
          weaselway.inputs.nixos-wsl.nixosModules.default
          weaselway.nixosModules.weaselway
          weaselway.nixosModules.image
          ./configuration.nix
        ];
      };

      nixosConfigurations.otterway = otterway.lib.mkGuest [
        { _module.args = { unstable = unstableFor "aarch64-linux"; otterwayInput = otterway; }; }
        ./otterway.nix
        ./apps.nix
      ];
      # The desktop without the applications, dev tools and services (a smaller disk).
      nixosConfigurations.otterway-desktop = otterway.lib.mkGuest [
        { _module.args = { otterwayInput = otterway; }; }
        ./otterway.nix
      ];
    };
}
