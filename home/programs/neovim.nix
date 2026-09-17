{ pkgs, ... }:

let
  neovim = pkgs.lazy-nvim-nix.LazyVim.override {
    globals = {
      autoformat = false;
      opt.relativenumber = false;
    };

    extras = [ "lazyvim.plugins.extras.editor.neo-tree" ];

    extraSpec = [
      (
        pkgs.lazy-nvim-nix.plugins."LazyVim".spec
        // {
          opts.news = {
            lazyvim = false;
            neovim = false;
          };
        }
      )
      (
        pkgs.lazy-nvim-nix.plugins."snacks.nvim".spec
        // {
          opts.scroll.enabled = false;
        }
      )
    ];
  };
in
{
  home.packages = [ neovim ];
}
