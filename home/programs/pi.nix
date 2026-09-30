{
  config,
  lib,
  pkgs,
  ...
}:

let
  configDirectory = ../../config/pi;
  sharedSettings = builtins.fromJSON (builtins.readFile (configDirectory + "/settings.json"));
  providerSettings = [
    "defaultProvider"
    "defaultModel"
    "enabledModels"
    "modelThinkingLevels"
    "providers"
  ];
  resources = [
    "keybindings.json"
    "mcp.json"
    "AGENTS.md"
    "AGENTS.MD"
    "AGENTS.override.md"
    "CLAUDE.md"
    "CLAUDE.MD"
    "SYSTEM.md"
    "APPEND_SYSTEM.md"
    "extensions"
    "skills"
    "prompts"
    "themes"
  ];
  existingResources = builtins.filter (
    name: builtins.pathExists (configDirectory + "/${name}")
  ) resources;
in
{
  assertions = [
    {
      assertion =
        builtins.isAttrs sharedSettings
        && lib.all (name: !(builtins.hasAttr name sharedSettings)) providerSettings;
      message = "config/pi/settings.json must be an object without provider/model settings; keep those on each machine.";
    }
  ];

  home.packages = [ (pkgs.callPackage ../../packages/pi { }) ];

  # Link individual resources, never the whole agent directory: authentication,
  # provider catalogs, installed packages, and sessions must remain writable.
  home.file = lib.genAttrs (map (name: ".pi/agent/${name}") existingResources) (target: {
    source = configDirectory + "/${lib.removePrefix ".pi/agent/" target}";
    recursive = true;
  });

  # Pi saves model choices and /settings here. Keep this file writable, merging
  # only the shared preferences after each activation instead of store-linking it.
  home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.python3}/bin/python3 ${./pi/merge-settings.py} \
      ${configDirectory + "/settings.json"} \
      ${lib.escapeShellArg "${config.home.homeDirectory}/.pi/agent"}
  '';
}
