{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fd
    jq
    ripgrep
    shellcheck
    shfmt
    tree
    watch
    yq-go
  ];

  programs.bat.enable = true;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

}
