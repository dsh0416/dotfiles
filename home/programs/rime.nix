{
  config,
  inputs,
  lib,
  ...
}:

let
  managedFiles = {
    "Library/Rime/default.custom.yaml" = ../../config/rime/default.custom.yaml;
    "Library/Rime/double_pinyin_flypy.schema.yaml" = ../../config/rime/double_pinyin_flypy.schema.yaml;
    "Library/Rime/double_pinyin_flypy.custom.yaml" = ../../config/rime/double_pinyin_flypy.custom.yaml;
    "Library/Rime/squirrel.custom.yaml" = ../../config/rime/squirrel.custom.yaml;
    "Library/Rime/emoji_suggestion.yaml" = "${inputs.rime-emoji}/emoji_suggestion.yaml";
    "Library/Rime/opencc/emoji.json" = "${inputs.rime-emoji}/opencc/emoji.json";
    "Library/Rime/opencc/emoji_category.txt" = "${inputs.rime-emoji}/opencc/emoji_category.txt";
    "Library/Rime/opencc/emoji_word.txt" = "${inputs.rime-emoji}/opencc/emoji_word.txt";
  };

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
