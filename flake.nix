{
  description = "Reproducible tooling for the Pelasgus GitHub profile";

  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg:
              inputs.nixpkgs.lib.getName pkg == "operator-mono-ligature";
          };
        in
        {
          packages = {
            operator-mono = pkgs.callPackage ./nix/operator-mono.nix { };
            default = pkgs.callPackage ./nix/operator-mono.nix { };
          };

          devShells = {
            default = pkgs.mkShellNoCC {
              packages = with pkgs; [
              nushell
              openssh
              python3
              ];
            };
          };
        };
    };
}
