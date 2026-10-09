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

  # A locked install resolves every active config scope, including the global
  # one. Ship the global lockfile so `mise install --locked` in a project with
  # `lockfile = true` can resolve the global `rust` and `cargo:` tools instead
  # of failing with "not in the lockfile". Regenerate with `mise lock -g` after
  # changing global tools and commit the result; keep it read-only like the
  # global config.
  xdg.configFile."mise/mise.lock" = {
    source = ../../config/mise/mise.lock;
    force = true;
  };
}
