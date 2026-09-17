{ pkgs, username, ... }:

{
  imports = [ ./server.nix ];

  nixpkgs.overlays = [
    (final: prev: {
      hyper = prev.hyper.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];

        installPhase = old.installPhase + ''
          hyperRuntimePath=${
            final.lib.makeLibraryPath [
              final.libglvnd
              final.stdenv.cc.cc
            ]
          }

          patchelf --add-rpath "$hyperRuntimePath" "$out/opt/Hyper/hyper"

          for nativeModule in \
            "$out/opt/Hyper/resources/app.asar.unpacked/node_modules/node-pty/build/Release/pty.node" \
            "$out/opt/Hyper/resources/app.asar.unpacked/node_modules/node-pty/bin/linux-x64-107/node-pty.node"
          do
            patchelf --add-rpath "$hyperRuntimePath" "$nativeModule"
          done

          rm "$out/bin/hyper"
          makeWrapper "$out/opt/Hyper/hyper" "$out/bin/hyper" \
            --prefix LD_LIBRARY_PATH : "$hyperRuntimePath"
        '';

        meta = old.meta // {
          broken = false;
        };
      });
    })
  ];

  # Keep the remote-management and CLI environment from the server profile,
  # then layer the graphical workstation environment on top.
  home-manager.users.${username}.imports = [ ../../../home/profiles/linux-desktop.nix ];

  services = {
    xserver.enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

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

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "google-chrome" ];
  environment.systemPackages = with pkgs; [ google-chrome ];

  fonts = {
    packages = with pkgs; [
      liberation_ttf
      nerd-fonts.iosevka
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      sarasa-gothic
    ];

    fontconfig.defaultFonts = {
      sansSerif = [ "Noto Sans CJK SC" ];
      serif = [ "Noto Serif CJK SC" ];
      monospace = [ "Noto Sans Mono CJK SC" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
