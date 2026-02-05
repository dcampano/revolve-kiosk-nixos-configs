{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # Leaving this here in case there is ever a reason that I 
    # need to pin Chromium to a specific revision
    nixpkgs-chromium.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, nixpkgs-chromium, ... }:
    let
      system = "aarch64-linux"; # change to "aarch64-linux" on Raspberry Pi, etc.
      chromiumOverlay = final: prev: {
        chromium = (import nixpkgs-chromium {
          inherit system;
          config = prev.config;  # carries allowUnfree, etc.
        }).chromium;
      };
    in
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ ... }: { nixpkgs.overlays = [ chromiumOverlay ]; })
            ./configuration.nix
          ];
        };
        nixos-sd = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ modulesPath, lib, ... }: {
              imports = [ (modulesPath + "/installer/sd-card/sd-image-aarch64.nix") ];
              nixpkgs.overlays = [ chromiumOverlay ];
              fileSystems."/" = lib.mkForce {
                device = "/dev/disk/by-label/NIXOS_SD";
                fsType = "ext4";
              };
              sdImage.populateRootCommands = ''
                mkdir -p ./files/etc/nixos
                cp ${./flake.nix} ./files/etc/nixos/flake.nix
                cp ${./configuration.nix} ./files/etc/nixos/configuration.nix
                cp ${./hardware-configuration.nix} ./files/etc/nixos/hardware-configuration.nix
              '';
            })
            ./configuration.nix
          ];
        };
      };
    };
}

