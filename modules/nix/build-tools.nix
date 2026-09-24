{ lib, pkgs, ... }:

let
  pythonBuildDependencies = with pkgs; [
    zlib
    readline
    openssl
    bzip2
    libffi
    gdbm
    xz
    zstd
    tcl
    tk
    sqlite
  ];
in
{
  # mise falls back to source builds when an upstream binary is unavailable.
  # Keep the interpreter and the conventional Unix build toolchain available
  # to every user instead of relying on an interactive Home Manager profile.
  environment.systemPackages =
    (with pkgs; [
      python3
      stdenv.cc
      gnumake
      pkg-config
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
      pythonBuildDependencies ++ map lib.getDev pythonBuildDependencies
    );

  # Installing a library's runtime output is insufficient on NixOS: headers
  # and pkg-config metadata live in separate development outputs, and neither
  # those nor the library directories are searched globally. Expose all three
  # search paths so Python versions built by mise can enable their standard
  # compression, crypto, readline, ctypes, dbm, Tcl/Tk, and SQLite modules.
  environment.variables = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    CPATH = lib.makeSearchPathOutput "dev" "include" pythonBuildDependencies;
    LIBRARY_PATH = lib.makeLibraryPath pythonBuildDependencies;
    PKG_CONFIG_PATH = lib.concatStringsSep ":" [
      (lib.makeSearchPathOutput "dev" "lib/pkgconfig" pythonBuildDependencies)
      (lib.makeSearchPathOutput "dev" "share/pkgconfig" pythonBuildDependencies)
    ];
  };
}
