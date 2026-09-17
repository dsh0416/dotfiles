{ config, lib, ... }:

{
  options.dotfiles.git = {
    name = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    email = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = {
    programs.git = {
      enable = true;
      lfs.enable = true;

      settings = {
        user = lib.mkIf (config.dotfiles.git.name != null && config.dotfiles.git.email != null) {
          name = config.dotfiles.git.name;
          email = config.dotfiles.git.email;
        };

        init.defaultBranch = "main";
        pull.rebase = true;
        rebase.autoStash = true;
        fetch.prune = true;
        rerere.enabled = true;
        push.autoSetupRemote = true;
        core.whitespace = "trailing-space,space-before-tab";
      };

      # Keep credentials, signing keys, and repository-specific identities out of
      # this public configuration.
      includes = [ { path = "~/.config/git/config.local"; } ];
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        line-numbers = true;
        navigate = true;
        side-by-side = false;
      };
    };
  };
}
