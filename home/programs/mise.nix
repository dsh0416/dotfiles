{ pkgs, ... }:

{
  home.packages = [ (pkgs.callPackage ../../packages/mise { }) ];
  home.sessionPath = [ "$HOME/.local/share/mise/shims" ];

  xdg.configFile."mise/config.toml" = {
    source = ../../config/mise/config.toml;
    force = true;
  };
}
