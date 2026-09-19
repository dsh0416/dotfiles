{ pkgs, inputs, ... }:

let
  # lazy-nvim-nix reads LazyVim's init.lua and NEWS.md while evaluating
  # the editor package. fetchTree uses the plugin lock already shipped
  # with that flake so those reads are ordinary store paths, not IFD.
  locked =
    (builtins.fromJSON (builtins.readFile (inputs.lazy-nvim-nix + "/plugins/flake.lock")))
    .nodes.LazyVim.locked;
  lazyvimSrc = builtins.fetchTree {
    inherit (locked)
      type
      owner
      repo
      rev
      narHash
      ;
  };
  lazy-nvim-nix = pkgs.lazy-nvim-nix // {
    plugins = pkgs.lazy-nvim-nix.plugins // {
      LazyVim = {
        inherit (pkgs.lazy-nvim-nix.plugins.LazyVim) spec extras meta;
        outPath = toString lazyvimSrc;
      };
    };
  };
  neovim = pkgs.lazy-nvim-nix.LazyVim.override {
    inherit lazy-nvim-nix;

    globals = {
      autoformat = false;
      opt.relativenumber = false;
    };

    extras = [ "lazyvim.plugins.extras.editor.neo-tree" ];

    extraSpec = [
      (
        lazy-nvim-nix.plugins."LazyVim".spec
        // {
          opts.news = {
            lazyvim = false;
            neovim = false;
          };
        }
      )
      (
        lazy-nvim-nix.plugins."snacks.nvim".spec
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
