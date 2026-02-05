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
            ({ modulesPath, ... }: {
              imports = [ (modulesPath + "/installer/sd-card/sd-image-aarch64.nix") ];
              nixpkgs.overlays = [ chromiumOverlay ];
            })
            ./configuration.nix
          ];
        };
      };
    };
}

