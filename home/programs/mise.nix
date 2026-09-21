{ pkgs, ... }:

{
  home.packages = [
    (pkgs.callPackage ../../packages/mise { })
    # mise reuses this package-manager installation instead of downloading the
    # generic rustup-init binary, which cannot run unpatched on NixOS. nixpkgs'
    # rustup also patches the Rust toolchains it installs for the NixOS linker.
    pkgs.rustup
  ];
  home.sessionPath = [ "$HOME/.local/share/mise/shims" ];

  xdg.configFile."mise/config.toml" = {
    source = ../../config/mise/config.toml;
    force = true;
  };
}
