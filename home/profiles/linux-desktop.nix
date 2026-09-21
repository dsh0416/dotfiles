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
  ];
}
