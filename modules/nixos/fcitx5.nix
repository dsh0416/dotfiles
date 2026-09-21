{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [
        fcitx5-gtk
        fcitx5-rime
      ];
      # GNOME/Mutter does not expose the native Wayland input-method protocol
      # used by Fcitx5, so retain the GTK/Qt input-module compatibility path.
      waylandFrontend = false;
    };
  };
}
