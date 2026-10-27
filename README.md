# FilmCraft Nix Flake

[Nix flake](https://nixos.wiki/wiki/Flakes) providing [FilmCraft](https://github.com/storytold/filmcraft) — an open-source, nonlinear video editor written in pure Rust.

> **Auto-updates** from upstream releases via GitHub Actions.

## Usage

### In your NixOS / home-manager config

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    filmcraft.url = "github:mistaquame/filmcraft-flake";
  };

  outputs = { self, nixpkgs, filmcraft, ... }:
    let system = "x86_64-linux"; in
    {
      homeConfigurations.your-user = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          ({ pkgs, ... }: {
            home.packages = [
              filmcraft.packages.${system}.default
            ];
          })
        ];
      };
    };
}
```

Or with `nixpkgs.config.allowUnfree = true` if needed:

```nix
home.packages = [ filmcraft.packages.${system}.default ];
```

### Run directly (no config changes)

```bash
# Run the GUI
nix run github:mistaquame/filmcraft-flake

# Run the CLI
nix run github:mistaquame/filmcraft-flake -- filmcraft-cli --help
```

### Development shell

```bash
nix develop github:mistaquame/filmcraft-flake
```

## Supported Platforms

| Platform | Status |
|----------|--------|
| `x86_64-linux` | ✅ |
| `aarch64-linux` | ✅ |

## Auto-Update

This flake is automatically updated via GitHub Actions when a new [FilmCraft release](https://github.com/storytold/filmcraft/releases) is published. The workflow:

1. Detects new release via scheduled check (every 6 hours)
2. Fetches `x86_64` and `aarch64` Linux tarballs
3. Computes SHA256 hashes
4. Opens a PR with updated `flake.nix` and `flake.lock`
5. Merges automatically after CI passes

## License

MIT OR Apache-2.0 (matching upstream [FilmCraft](https://github.com/storytold/filmcraft/blob/main/Cargo.toml))

---

*This is an unofficial community-maintained flake. Not affiliated with the FilmCraft project.*