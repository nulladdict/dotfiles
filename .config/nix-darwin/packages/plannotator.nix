{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation rec {
  pname = "plannotator";
  version = "0.19.3";

  src = fetchurl {
    url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/plannotator-darwin-arm64";
    hash = "sha256-vqV08L8fIbRmZKGLjorbAScIRSUEYyP1HfcGGLAIQ98=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp $src $out/bin/plannotator
    chmod 0755 $out/bin/plannotator

    runHook postInstall
  '';

  meta = {
    description = "Interactive plan and code review annotator for AI coding agents";
    homepage = "https://plannotator.ai";
    downloadPage = "https://github.com/backnotprop/plannotator/releases";
    license = lib.licenses.asl20;
    mainProgram = "plannotator";
    platforms = [ "aarch64-darwin" ];
  };
}
