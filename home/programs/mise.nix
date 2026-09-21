{ pkgs, ... }:

{
  home.packages = [
    (pkgs.callPackage ../../packages/mise { })
    # mise reuses this package-manager installation instead of downloading the
    # generic rustup-init binary, which cannot run unpatched on NixOS. nixpkgs'
    # rustup also patches the Rust toolchains it installs for the NixOS linker.
    pkgs.rustup
  ];
  home.sessionPath = [
    "$HOME/.local/share/mise/shims"
    # mise can reuse a package-manager rustup when its directory also contains
    # the Rust tool proxies. Expose the dedicated package bin directory before
    # the combined Home Manager profile so mise does not treat every program in
    # the profile as a Rust proxy and generate unrelated shims for it.
    "${pkgs.rustup}/bin"
  ];

  xdg.configFile."mise/config.toml" = {
    source = ../../config/mise/config.toml;
    force = true;
  };
}
