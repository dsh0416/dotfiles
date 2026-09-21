{ pkgs, ... }:

{
  # mise falls back to source builds when an upstream binary is unavailable.
  # Keep the interpreter and the conventional Unix build toolchain available
  # to every user instead of relying on an interactive Home Manager profile.
  environment.systemPackages = with pkgs; [
    python3
    stdenv.cc
    gnumake
    pkg-config
  ];
}
