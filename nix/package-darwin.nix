{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:
let
  version = (builtins.fromTOML (builtins.readFile ../Cargo.toml)).package.version;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/anomalyco/hex/releases/download/v${finalAttrs.version}/hex-${finalAttrs.version}-macos-arm64.zip";
    hash = "sha256-HCjWoeeQMj7xmbSBvJIx5q2OcKF4W+hJE+Cnvwpuuzk=";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R Hex.app $out/Applications/
    mkdir -p $out/bin
    ln -s $out/Applications/Hex.app/Contents/MacOS/hex $out/bin/hex
    runHook postInstall
  '';

  meta = {
    description = "Local-first voice dictation";
    homepage = "https://anoma.ly/hex/";
    license = lib.licenses.mit;
    mainProgram = "hex";
    platforms = [ "aarch64-darwin" ];
  };
})
