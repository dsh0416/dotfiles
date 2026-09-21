{
  config,
  inputs,
  lib,
  ...
}:

let
  managedFiles = lib.mapAttrs' (name: source: lib.nameValuePair "Library/Rime/${name}" source) (
    (import ./rime-files.nix { inherit inputs; })
    // {
      "squirrel.custom.yaml" = ../../config/rime/squirrel.custom.yaml;
    }
  );

  managedConfigVersion =
    "deploy-hook-version 3\n"
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList (target: source: "${builtins.hashFile "sha256" source}  ${target}") managedFiles
    );

  installManagedFiles = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      target: source:
      let
        destination = "${config.home.homeDirectory}/${target}";
        temporary = "${destination}.home-manager-new";
      in
      ''
        /bin/mkdir -p ${lib.escapeShellArg (builtins.dirOf destination)}
        /usr/bin/install -m 0644 ${lib.escapeShellArg source} ${lib.escapeShellArg temporary}
        /bin/mv -f ${lib.escapeShellArg temporary} ${lib.escapeShellArg destination}
      ''
    ) managedFiles
  );
in
{
  home.file."Library/Rime/.dotfiles-config-version" = {
    text = managedConfigVersion + "\n";
    onChange = ''
      ${installManagedFiles}

      squirrel="/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel"
      if [[ -x "$squirrel" ]]; then
        "$squirrel" --reload
      else
        echo "Squirrel is not installed; skipping Rime deployment." >&2
      fi
    '';
  };
}
