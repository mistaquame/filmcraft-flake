# FilmCraft Nix Flake

A [Nix flake](https://nixos.wiki/wiki/Flakes) for [FilmCraft](https://github.com/storytold/filmcraft), an open-source, nonlinear video editor written in pure Rust.

This flake repackages the **official prebuilt Linux release** (it does not build FilmCraft from source). The binary is patched with `autoPatchelfHook` and given the runtime libraries it needs for windowing, graphics and hardware video decoding.

> **Auto-updates:** a GitHub Actions workflow checks for new upstream releases every 6 hours and updates this flake automatically. See [Auto-update](#auto-update).

This is an unofficial, community-maintained flake and is not affiliated with the FilmCraft project.

## Quick start

Run it without installing anything:

```sh
nix run github:mistaquame/filmcraft-flake
```

Install it into your user profile:

```sh
nix profile install github:mistaquame/filmcraft-flake
```

The package provides two programs, `filmcraft` (the editor) and `filmcraft-cli`. To use the CLI without installing:

```sh
nix shell github:mistaquame/filmcraft-flake -c filmcraft-cli --help
```

## Installing on NixOS

Add the flake as an input and reuse your own `nixpkgs`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    filmcraft = {
      url = "github:mistaquame/filmcraft-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [ ./configuration.nix ];
    };
  };
}
```

Then add the package, either system-wide:

```nix
# configuration.nix
{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    inputs.filmcraft.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

or per user with Home Manager (make sure `inputs` is passed via `extraSpecialArgs`):

```nix
{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.filmcraft.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

Apply it with `sudo nixos-rebuild switch --flake .#myhost`. If your config lives in a git repository, remember that flakes only see files git tracks, so `git add` new files (including `flake.lock`) first.

## Graphics and hardware decoding

FilmCraft renders with wgpu (Vulkan, with OpenGL as a fallback) and can use hardware video decoding. These libraries are loaded at runtime from the host's GPU driver, so one build works for AMD, Intel and NVIDIA. Which GPU libraries are found depends on your system configuration.

### NixOS (all GPUs)

```nix
hardware.graphics.enable = true;
```

This is required. Without it there is no Vulkan or OpenGL driver for FilmCraft to load (see [Troubleshooting](#troubleshooting)).

### AMD

Nothing more is needed. Mesa provides both Vulkan (RADV) and VA-API hardware decoding.

### Intel

```nix
hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
```

### NVIDIA

```nix
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia.open = true; # set to false for older cards that need the proprietary kernel module
```

The flake adds `/run/opengl-driver/lib` to the binary's library search path, which is where NixOS exposes the NVIDIA driver's `libnvcuvid` for NVDEC decoding.

### Not on NixOS

On other distributions the Nix-built graphics loader cannot see your host GPU drivers. Run FilmCraft through [nixGL](https://github.com/nix-community/nixGL):

```sh
nix run --impure github:nix-community/nixGL -- filmcraft
```

## Troubleshooting

FilmCraft writes its log to `~/.local/share/filmcraft/Logs/filmcraft.log` and also prints it to the terminal when started from one.

**"WGPU error: Failed to create surface for any enabled backend: {}"**
No graphics backend could be loaded. On NixOS, check that `hardware.graphics.enable = true;` is set and rebuild. You can force a backend to see the real error:

```sh
WGPU_BACKEND=vulkan VK_LOADER_DEBUG=error,warn filmcraft
WGPU_BACKEND=gl filmcraft
```

**Log says "graphics mode software after earlier failed starts" and `llvmpipe` appears**
FilmCraft remembers failed starts and falls back to CPU rendering. Once the underlying problem is fixed, go back to normal mode:

```sh
filmcraft --graphics default
```

If it keeps falling back, delete `~/.local/share/filmcraft/graphics-start.json` and start again.

**Log says "no VA-API hardware decoding" or "no NVDEC hardware decoding"**
Hardware decoding is optional; FilmCraft falls back to the CPU. To enable it, set up your GPU as described under [Graphics and hardware decoding](#graphics-and-hardware-decoding).

**`zbus ... ServiceUnknown` warning**
Harmless. It is a failed desktop-portal property lookup and does not affect anything.

## Supported platforms

| Platform       | Status |
|----------------|--------|
| `x86_64-linux` | ✅     |

The upstream release also exists for other platforms, but only `x86_64-linux` is packaged here.

## Auto-update

The workflow in [`.github/workflows/auto-update.yml`](.github/workflows/auto-update.yml) runs every 6 hours and can also be started manually from the **Actions** tab ("Run workflow"). It:

1. Reads the latest release tag from [storytold/filmcraft](https://github.com/storytold/filmcraft/releases) and compares it with `version` in `flake.nix`.
2. If there is a newer release, downloads the `x86_64` Linux tarball and computes its hash.
3. Updates `version` and the hash in `flake.nix`.
4. Builds `.#default` and only commits and pushes to `main` if the build succeeds.

Updating this repository does **not** update your system by itself. To pick up a new FilmCraft release, update the input in your own config and rebuild:

```sh
nix flake update filmcraft
sudo nixos-rebuild switch --flake .#myhost
```

## Development

```sh
nix build .#default      # build the package
nix run .                # run FilmCraft
nix develop              # development shell
```

Updating by hand: change `version` in `flake.nix`, set the hash to an empty string (`""`), run `nix build`, and copy the correct `sha256-…` hash from the error message.

## License

MIT OR Apache-2.0, matching upstream [FilmCraft](https://github.com/storytold/filmcraft/blob/main/Cargo.toml).
