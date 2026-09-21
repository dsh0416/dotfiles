{
  lib,
  pkgs,
  username,
  ...
}:

let
  kimpanel = pkgs.gnomeExtensions.kimpanel;
in
{
  imports = [ ./server.nix ];

  # Merge pure settings at the preset level to preserve list ordering
  # against consumer siblings, including host font and overlay additions.
  config = lib.mkMerge [
    (import ../hyper.nix)
    (import ../gnome.nix)
    (import ../fcitx5.nix { inherit pkgs; })
    (import ../fonts.nix { inherit pkgs; })
    {
      # Keep the remote-management and CLI environment from the server profile,
      # then layer the graphical workstation environment on top.
      home-manager.users.${username} = {
        imports = [ ../../../home/profiles/linux-desktop.nix ];
        dconf.settings."org/gnome/shell".enabled-extensions = [ kimpanel.extensionUuid ];
      };

      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "google-chrome" ];
      environment.systemPackages = [
        pkgs.google-chrome
        kimpanel
      ];
    }
  ];
}
