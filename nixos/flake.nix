# The weaselway image's system flake. nixpkgs and NixOS-WSL come from
# weaselway's lock, so the patched packages match the binary cache.
# `sudo nix flake update --flake /etc/nixos` moves to the newest weaselway.
{
  inputs.weaselway.url = "github:tkuipers/weaselway/two-displays";
  # Only for packages the pinned nixpkgs is too old for (see `unstable` in configuration.nix).
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { weaselway, nixpkgs-unstable, ... }:
    {
      nixosConfigurations.nixos = weaselway.inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit (weaselway.inputs) dxgdrm;
          unstable = import nixpkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
            # Zotero 10 bundles Firefox ESR 140, end-of-life since 2026-10-13. Drop with the next Zotero.
            config.permittedInsecurePackages = [ "firefox-esr-140-bin-unwrapped-140.17.0esr" ];
          };
        };
        modules = [
          weaselway.inputs.nixos-wsl.nixosModules.default
          weaselway.nixosModules.weaselway
          weaselway.nixosModules.image
          ./configuration.nix
        ];
      };
    };
}
