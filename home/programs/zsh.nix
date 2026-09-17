{ config, lib, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      path = "$HOME/.zsh_history";
      size = 50000;
      save = 10000;
      ignoreAllDups = true;
      share = true;
    };

    setOptions = [ "HIST_REDUCE_BLANKS" ];

    shellAliases = {
      reload = "exec zsh";
      vi = "nvim";
      vim = "nvim";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "colored-man-pages"
        "docker"
        "docker-compose"
        "gh"
        "git"
        "git-lfs"
        "gpg-agent"
        "mise"
        "sudo"
      ];
      theme = "";
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 750 ''
        # The Oh My Zsh Docker plugin refreshes this completion on every
        # shell start. Files copied from the Nix store retain read-only mode,
        # so make an existing cache entry writable before the plugin runs.
        if [[ -f "$HOME/.cache/oh-my-zsh/completions/_docker" && ! -w "$HOME/.cache/oh-my-zsh/completions/_docker" ]]; then
          chmod u+w "$HOME/.cache/oh-my-zsh/completions/_docker"
        fi
      '')
      (lib.mkOrder 1500 ''
        [[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
      '')
    ];
  };
}
