{ lib, ... }:

{
  programs.zsh = {
    oh-my-zsh.plugins = lib.mkAfter [
      "brew"
      "macos"
    ];

    initContent = lib.mkOrder 1400 ''
      source "$HOME/.orbstack/shell/init.zsh" 2>/dev/null || true
    '';
  };
}
