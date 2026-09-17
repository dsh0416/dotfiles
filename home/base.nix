{
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./programs/git.nix
    ./programs/zsh.nix
  ];

  home.username = username;
  home.homeDirectory = lib.mkDefault "/Users/${username}";

  home.packages = with pkgs; [ coreutils ];

  home.sessionPath = [ "$HOME/.local/bin" ];
  home.sessionVariables.LANG = "en_US.UTF-8";

  programs.home-manager.enable = true;

  # Keep this at the version used for the initial Home Manager activation.
  home.stateVersion = "26.05";
}
