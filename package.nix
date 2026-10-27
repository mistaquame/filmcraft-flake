{ stdenv, lib, fetchurl, autoPatchelfHook, glibc, alsaLib, libgcc }:

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
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ glibc alsaLib libgcc ];
  dontBuild = true;
  dontConfigure = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 bin/filmcraft       $out/bin/filmcraft
    install -Dm755 bin/filmcraft-cli   $out/bin/filmcraft-cli
    cp -r share $out/share
    runHook postInstall
  '';
  autoPatchelfAllowlist = [ "bin/filmcraft" "bin/filmcraft-cli" ];
  meta = with lib; {
    description = "An open-source, nonlinear video editor written in pure Rust";
    homepage = "https://github.com/storytold/filmcraft";
    license = licenses.mit;
    mainProgram = "filmcraft";
    platforms = [ "x86_64-linux" ];
  };
}