{ lib, pkgs, ... }:

{
  fonts = {
    # Host-specific fonts keep their natural precedence over this preset.
    packages = lib.mkAfter (
      with pkgs;
      [
        liberation_ttf
        nerd-fonts.iosevka
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        sarasa-gothic
      ]
    );

    fontconfig.defaultFonts = {
      sansSerif = [ "Noto Sans CJK SC" ];
      serif = [ "Noto Serif CJK SC" ];
      monospace = [ "Noto Sans Mono CJK SC" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
