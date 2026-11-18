{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "operator-mono-ligature";
  version = "unstable-2026-11-16";

  src = fetchFromGitHub {
    owner = "sujon-co";
    repo = "operator-mono-ligature";
    rev = "main";
    hash = "sha256-oUfEpjTooUPOBIhQF3s746qWqBVwf+cIfqE3eIbbjEo=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 -t "$out/share/fonts/opentype" Fonts/*.otf
    runHook postInstall
  '';

  meta = {
    description = "Operator Mono fonts patched with programming ligatures";
    homepage = "https://github.com/sujon-co/operator-mono-ligature";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
}

