{ pkgs, ... }:

{
  imports = [
    ./desktop-common.nix
    ../programs/rime-linux.nix
    ../linux/desktop.nix
  ];

  home.packages = [
    pkgs.hyper
    pkgs.zed-editor
    # Nixpkgs exposes the Linux binary as `zeditor`, while the shared editor
    # configuration and Zed's macOS CLI use `zed`. Keep that command stable
    # across platforms so EDITOR="zed --wait" always resolves.
    (pkgs.writeShellScriptBin "zed" ''
      exec ${pkgs.lib.getExe pkgs.zed-editor} "$@"
    '')
  ];
}
