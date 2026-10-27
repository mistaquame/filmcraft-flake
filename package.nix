{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  alsa-lib,
  dbus,
  libGL,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  libxrandr,
  vulkan-loader,
  wayland,
  libva,
  addDriverRunpath,
  version,
  hash,
}:

let
  arch = if stdenv.hostPlatform.isx86_64 then "x86_64" else "aarch64";

  # Libraries the binary loads with dlopen() at runtime (winit, wgpu, ...).
  # They do not show up in DT_NEEDED, so autoPatchelfHook can't find them on
  # its own; runtimeDependencies puts them into the RPATH instead.
  runtimeLibs = [
    dbus
    libGL
    libx11
    libxcb
    libxcursor
    libxi
    libxkbcommon
    libxrandr
    vulkan-loader
    wayland
    libva
  ];
in
stdenv.mkDerivation {
  pname = "filmcraft";
  inherit version;

  src = fetchurl {
    url = "https://github.com/storytold/filmcraft/releases/download/v${version}/filmcraft-${version}-linux-${arch}.tar.gz";
    inherit hash;
  };
  sourceRoot = "filmcraft-${version}-linux-${arch}";

  nativeBuildInputs = [ autoPatchelfHook ];

  # Link-time deps (DT_NEEDED): libasound, libgcc_s. libc comes from stdenv.
  buildInputs = [
    alsa-lib
    stdenv.cc.cc.lib
  ];

  runtimeDependencies = map lib.getLib runtimeLibs;

  appendRunpaths = [ "${addDriverRunpath.driverLink}/lib" ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/filmcraft     $out/bin/filmcraft
    install -Dm755 bin/filmcraft-cli $out/bin/filmcraft-cli
    mkdir -p $out/share
    cp -r share/. $out/share/
    runHook postInstall
  '';

  meta = {
    description = "Open-source, nonlinear video editor written in pure Rust";
    homepage = "https://github.com/storytold/filmcraft";
    license = with lib.licenses; [ mit asl20 ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "filmcraft";
    platforms = [ "x86_64-linux" ];
  };
}
