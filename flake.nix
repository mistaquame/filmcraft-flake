{
  description = "FilmCraft: An open-source, nonlinear video editor written in pure Rust";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      filmcraftVersion = "0.13.0";
      sha256ByArch = {
        "x86_64-linux" = "40e9d685fb3ed1b0a21c9c02211f1a8499e09a47c551244ce7ee80f2584d3a9b";
        "aarch64-linux" = "e55061da7f46dd1465379ac071eb854993722f4ece87ef1a8b70b265927b6894";
      };
      packageFor =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          src = import ./package.nix { inherit (pkgs) lib stdenv fetchurl; };
        in
        src {
          version = filmcraftVersion;
          sha256 = sha256ByArch.${system} or (throw "Unsupported system: ${system}");
        };
    in
    {
      packages = forAllSystems packageFor;

      apps = forAllSystems (
        system:
        let
          pkg = self.packages.${system}.default;
        in
        {
          default = {
            type = "app";
            program = "${pkg}/bin/filmcraft";
          };
        }
      );

      defaultPackage = forAllSystems packageFor;

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell { };
        }
      );
    };
}