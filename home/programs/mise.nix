{ pkgs, ... }:

{
  home.packages = [ pkgs.mise ];
  home.sessionPath = [ "$HOME/.local/share/mise/shims" ];

  xdg.configFile."mise/config.toml" = {
    source = ../../config/mise/config.toml;
    force = true;
  };
}
