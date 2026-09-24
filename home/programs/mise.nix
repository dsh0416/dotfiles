{ config, pkgs, ... }:

{
  home.packages = [
    (pkgs.callPackage ../../packages/mise { })
    # Keep the default Rust toolchain declarative. Generic mise tasks should not
    # have to activate the Rust backend merely because Rust is globally useful.
    pkgs.cargo
    pkgs.rustc
  ];
  home.sessionPath = [
    "$HOME/.local/share/mise/shims"
    # Unconfigured Rust shims fall through to the declarative toolchain in the
    # Home Manager profile. Keep nixpkgs' Nix-aware rustup proxy directory later
    # on PATH so project-local Rust declarations can still use it as mise's
    # external provider without downloading the incompatible generic installer.
    "${config.home.profileDirectory}/bin"
    "${pkgs.rustup}/bin"
  ];

  xdg.configFile."mise/config.toml" = {
    source = ../../config/mise/config.toml;
    force = true;
  };
}
