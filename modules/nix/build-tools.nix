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
  # Binary Python wheels commonly depend on the GNU C++ runtime and zlib even
  # when the interpreter itself was built against Nix store paths.
  pythonRuntimeDependencies = with pkgs; [
    stdenv.cc.cc
    zlib
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
  # those nor the library directories are searched globally. Expose the build
  # search paths so Python versions built by mise can enable their standard
  # compression, crypto, readline, ctypes, dbm, Tcl/Tk, and SQLite modules.
  # LD_LIBRARY_PATH is deliberately narrower: it only supplies libraries that
  # manylinux wheels such as NumPy load dynamically but do not bundle.
  environment.variables =
    lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      CPATH = lib.makeSearchPathOutput "dev" "include" pythonBuildDependencies;
      LD_LIBRARY_PATH = lib.makeLibraryPath pythonRuntimeDependencies;
      LIBRARY_PATH = lib.makeLibraryPath pythonBuildDependencies;
      PKG_CONFIG_PATH = lib.concatStringsSep ":" [
        (lib.makeSearchPathOutput "dev" "lib/pkgconfig" pythonBuildDependencies)
        (lib.makeSearchPathOutput "dev" "share/pkgconfig" pythonBuildDependencies)
      ];
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      # Rust tools installed by mise invoke the Nix cc wrapper outside a Nix
      # build. Its bundled macOS SDK has no libiconv stub, so expose nixpkgs'
      # compatible library to the linker for crates that request -liconv.
      LIBRARY_PATH = lib.mkDefault (lib.makeLibraryPath [ pkgs.libiconv ]);
    };
}
