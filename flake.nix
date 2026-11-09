{
  description = "HEX local-first voice dictation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      package = pkgs: self.packages.${pkgs.stdenv.hostPlatform.system}.hex;
    in
    {
      packages = forSystems (
        pkgs:
        let
          hex =
            if pkgs.stdenv.hostPlatform.isDarwin then
              pkgs.callPackage ./nix/package-darwin.nix { }
            else
              pkgs.callPackage ./nix/package.nix { };
        in
        {
          inherit hex;
          default = hex;
        }
      );

      overlays.default = final: _prev: {
        hex =
          if final.stdenv.hostPlatform.isDarwin then
            final.callPackage ./nix/package-darwin.nix { }
          else
            final.callPackage ./nix/package.nix { };
      };

      nixosModules.hex =
        { pkgs, ... }:
        {
          imports = [ ./nix/module.nix ];
          programs.hex.package = nixpkgs.lib.mkDefault (package pkgs);
        };
      nixosModules.default = self.nixosModules.hex;

      homeManagerModules.hex =
        { pkgs, ... }:
        {
          imports = [ ./nix/hm-module.nix ];
          programs.hex.package = nixpkgs.lib.mkDefault (package pkgs);
        };
      homeManagerModules.default = self.homeManagerModules.hex;

      devShells = forSystems (pkgs: {
        default = (package pkgs).devShell or (pkgs.mkShell { });
      });
      checks = forSystems (
        pkgs:
        if pkgs.stdenv.hostPlatform.isLinux then
          import ./nix/checks.nix { inherit self pkgs; }
        else
          {
            package = pkgs.runCommand "hex-darwin-package-check" { } ''
              ${pkgs.lib.getExe (package pkgs)} --version
              touch "$out"
            '';
          }
      );
      formatter = forSystems (pkgs: pkgs.nixfmt);
    };
}
