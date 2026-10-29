{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  asset = sources.assets.${stdenvNoCC.hostPlatform.system};
  canExecute = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
in
assert lib.assertMsg (lib.all (candidate: candidate.version == asset.version) (
  builtins.attrValues sources.assets
)) "mise release versions must match across all supported platforms";
stdenvNoCC.mkDerivation {
  pname = "mise";
  inherit (asset) version;

  src = fetchurl {
    url = "https://github.com/jdx/mise/releases/download/v${asset.version}/mise-v${asset.version}-${asset.platform}.tar.gz";
    inherit (asset) sha256;
  };

  nativeBuildInputs = [ installShellFiles ];
  sourceRoot = "mise";
  dontConfigure = true;
  dontBuild = true;
  # Preserve upstream's signed macOS binary and static Linux executables.
  dontStrip = true;
  dontPatchELF = true;

  env.MISE_OFFLINE = "true";

  installPhase = ''
    runHook preInstall

    export MISE_DATA_DIR="$TMPDIR/mise-data"

    install -Dm755 bin/mise "$out/bin/mise"
    installManPage man/man1/mise.1

    mkdir -p "$out/lib/mise"
    touch "$out/lib/mise/.disable-self-update"
  ''
  + lib.optionalString canExecute ''
    # Current mise embeds usage completion support in its own executable.
    installShellCompletion --cmd mise \
      --bash <("$out/bin/mise" completion bash) \
      --fish <("$out/bin/mise" completion fish) \
      --zsh <("$out/bin/mise" completion zsh)
  ''
  + ''
    runHook postInstall
  '';

  doInstallCheck = canExecute;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/mise" --version | grep -F "${asset.version} "
    runHook postInstallCheck
  '';

  meta = {
    description = "Development environment and task manager";
    homepage = "https://mise.jdx.dev";
    changelog = "https://github.com/jdx/mise/releases/tag/v${asset.version}";
    license = lib.licenses.mit;
    mainProgram = "mise";
    platforms = builtins.attrNames sources.assets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
