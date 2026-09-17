{ pkgs, ... }:

{
  imports = [
    ../programs/cli.nix
    ../programs/mise.nix
    ../programs/neovim.nix
    ../programs/starship.nix
  ];

  home.packages = with pkgs; [
    fastfetch
    gh
    glab
    gnupg
    htop
    libpq
  ];
}
