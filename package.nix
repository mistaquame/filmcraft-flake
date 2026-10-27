{ stdenv, lib, fetchurl, autoPatchelfHook, glibc, alsaLib, libgcc, wayland, libxkbcommon, libx11, libxext }:

{ version
, sha256
}:
let
  arch = if stdenv.hostPlatform.isx86_64 then "x86_64" else "aarch64";
in
stdenv.mkDerivation {
  name = "filmcraft-${version}";
  src = fetchurl {
    url = "https://github.com/storytold/filmcraft/releases/download/v${version}/filmcraft-${version}-linux-${arch}.tar.gz";
    inherit sha256;
  };
  sourceRoot = "filmcraft-${version}-linux-${arch}";
  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [ glibc alsaLib libgcc wayland libxkbcommon libx11 libxext ];
  dontBuild = true;
  dontConfigure = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 bin/filmcraft.raw       $out/bin/filmcraft.raw
    install -Dm755 bin/filmcraft-cli.raw   $out/bin/filmcraft-cli.raw
    cp -r share $out/share
    runHook postInstall
  '';

  # Wrap the GUI binary so it uses the X11 backend and can find system libraries
  postInstall = ''
    makeWrapper $out/bin/filmcraft.raw $out/bin/filmcraft \
      --set-env 'GDK_BACKEND=x11' \
      --set-env 'LD_LIBRARY_PATH=${out}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}'
    makeWrapper $out/bin/filmcraft-cli.raw $out/bin/filmcraft-cli \
      --set-env 'GDK_BACKEND=x11' \
      --set-env 'LD_LIBRARY_PATH=${out}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}'
  '';

  autoPatchelfAllowlist = [ "bin/filmcraft.raw" "bin/filmcraft-cli.raw" ];
  meta = with lib; {
    description = "An open-source, nonlinear video editor written in pure Rust";
    homepage = "https://github.com/storytold/filmcraft";
    license = licenses.mit;
    mainProgram = "filmcraft";
    platforms = [ "x86_64-linux" ];
  };
}