{
  description = "FilmCraft: An open-source, nonlinear video editor written in pure Rust";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      version = "0.15.0";
      hashByArch = {
        "x86_64-linux" = "sha256-IrEGtMpilNmz6aSvQLQKZToYl0NzZIBQRqAd26pLIsE=";
      };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          filmcraft = pkgs.callPackage ./package.nix {
            inherit version;
            hash = hashByArch.${system} or (throw "Unsupported system: ${system}");
            libva = pkgs.libva;
            addDriverRunpath = pkgs.addDriverRunpath;
          };
        in
        {
          inherit filmcraft;
          default = filmcraft;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = nixpkgs.lib.getExe self.packages.${system}.default;
        };
      });

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell { };
      });
    };
}
