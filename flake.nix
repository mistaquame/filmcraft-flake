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
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      filmcraftVersion = "0.13.0";
      sha256ByArch = {
        "x86_64-linux" = "40e9d685fb3ed1b0a21c9c02211f1a8499e09a47c551244ce7ee80f2584d3a9b";
      };
      packageFor =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          src = import ./package.nix { inherit (pkgs) lib stdenv fetchurl autoPatchelfHook glibc; alsaLib = pkgs.alsa-lib; libgcc = pkgs.gcc-unwrapped.libgcc; wayland = pkgs.wayland; libxkbcommon = pkgs.libxkbcommon; libx11 = pkgs.libx11; libxext = pkgs.libxext; };
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
          pkg = self.packages.${system};
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