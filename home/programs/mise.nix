{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = [
    (pkgs.callPackage ../../packages/mise { })
  ];
  home.sessionPath = [
    "$HOME/.local/share/mise/shims"
    "${config.home.profileDirectory}/bin"
    "$HOME/.local/share/mise-cargo/bin"
  ];

  # Standalone rustup/cargo commands and mise must use the same upstream
  # installation. Leave toolchains previously patched by nixpkgs untouched.
  home.sessionVariables = {
    CARGO_HOME = "${config.home.homeDirectory}/.local/share/mise-cargo";
    RUSTUP_HOME = "${config.home.homeDirectory}/.local/share/mise-rustup";
  };

  # Use Nix's compiler driver and binutils on Linux x86_64. The upstream
  # self-contained lld bypasses Nix's linker wrapper and library/rpath handling.
  # Referencing cc here keeps it in the Home Manager generation's closure.
  home.file.".local/share/mise-cargo/config.toml" =
    lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64)
      {
        text = ''
          [target.x86_64-unknown-linux-gnu]
          linker = "${pkgs.stdenv.cc}/bin/cc"
          rustflags = ["-C", "linker-features=-lld"]
        '';
      };

  xdg.configFile."mise/config.toml" = {
    source = ../../config/mise/config.toml;
    force = true;
  };
}
