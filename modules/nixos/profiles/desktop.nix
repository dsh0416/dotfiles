{
  pkgs,
  username,
  ...
}:

let
  # GNOME Shell has no built-in StatusNotifierItem host. This extension owns
  # org.kde.StatusNotifierWatcher, which tray clients such as Synergy need.
  appindicator = pkgs.gnomeExtensions.appindicator;
  kimpanel = pkgs.gnomeExtensions.kimpanel;
in
{
  imports = [
    ../fcitx5.nix
    ../fonts.nix
    ../gnome.nix
    ../gstreamer.nix
    ../hyper.nix
    ./server.nix
  ];

  # Keep the remote-management and CLI environment from the server profile,
  # then layer the graphical workstation environment on top.
  home-manager.users.${username} = {
    imports = [ ../../../home/profiles/linux-desktop.nix ];
    dconf.settings."org/gnome/shell".enabled-extensions = [
      appindicator.extensionUuid
      kimpanel.extensionUuid
    ];
  };

  # GNOME/Mutter does not expose the native Wayland input-method protocol used
  # by Fcitx5, so retain the compatibility path in this GNOME composition.
  i18n.inputMethod.fcitx5.waylandFrontend = false;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "google-chrome" ];
  environment.systemPackages = [
    appindicator
    pkgs.google-chrome
    kimpanel
  ];
}
