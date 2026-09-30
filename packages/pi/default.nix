{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  ripgrep,
  fd,
  libxcb,
}:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  asset = sources.assets.${stdenvNoCC.hostPlatform.system};
  canExecute = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
in
assert lib.assertMsg (lib.all (candidate: candidate.version == asset.version) (
  builtins.attrValues sources.assets
)) "Pi release versions must match across all supported platforms";
stdenvNoCC.mkDerivation {
  pname = "pi-coding-agent";
  inherit (asset) version;

  src = fetchurl {
    url = "https://github.com/earendil-works/pi/releases/download/v${asset.version}/pi-${asset.platform}.tar.gz";
    inherit (asset) sha256;
  };

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [
    autoPatchelfHook
  ];
  # The bundled native X11 module links against libxcb even when Pi runs
  # without a graphical session.
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    libxcb
  ];
  sourceRoot = "pi";
  dontConfigure = true;
  dontBuild = true;
  # Keep Bun's embedded program and macOS code signature intact.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/pi" "$out/bin"
    cp -R . "$out/lib/pi/"
    makeWrapper "$out/lib/pi/pi" "$out/bin/pi" \
      --prefix PATH : ${
        lib.makeBinPath [
          ripgrep
          fd
        ]
      }

    runHook postInstall
  '';

  doInstallCheck = canExecute;
  installCheckPhase = ''
    runHook preInstallCheck
    export PI_CODING_AGENT_DIR="$TMPDIR/pi-agent"
    test "$("$out/bin/pi" --version)" = "${asset.version}"
    "$out/bin/pi" --help > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Coding agent CLI with independently pinned upstream releases";
    homepage = "https://pi.dev";
    changelog = "https://github.com/earendil-works/pi/releases/tag/v${asset.version}";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = builtins.attrNames sources.assets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
