{
  description = "Reusable NixOS, nix-darwin, and Home Manager configuration modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comin.url = "github:nlewo/comin";
    lazy-nvim-nix.url = "github:josh/lazy-nvim-nix";
    rime-emoji = {
      url = "github:rime/rime-emoji";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    {
      nixosModules = {
        base = ./modules/nixos/base.nix;
        kernel-reboot-check = ./modules/nixos/kernel-reboot-check.nix;
        openssh-server = ./modules/nixos/openssh-server.nix;
        server = ./modules/nixos/profiles/server.nix;
        desktop = ./modules/nixos/profiles/desktop.nix;
        comin = ./modules/nixos/comin.nix;
        gnome = ./modules/nixos/gnome.nix;
        fcitx5 = ./modules/nixos/fcitx5.nix;
        fonts = ./modules/nixos/fonts.nix;
        hyper = ./modules/nixos/hyper.nix;
        maintenance = ./modules/nix/maintenance.nix;
        tuna = ./modules/nix/tuna.nix;
      };

      darwinModules = {
        base = ./modules/darwin/base.nix;
        homebrew = ./modules/darwin/homebrew.nix;
        desktop = ./modules/darwin/profiles/desktop.nix;
        development = ./modules/darwin/profiles/development.nix;
        multimedia = ./modules/darwin/profiles/multimedia.nix;
        operations = ./modules/darwin/profiles/operations.nix;
        mobile = ./modules/darwin/profiles/mobile.nix;
        maintenance = ./modules/nix/maintenance.nix;
        tuna = ./modules/nix/tuna.nix;
      };

      homeModules = {
        base = ./home/base.nix;
        linux = ./home/linux.nix;
        development-cli = ./home/profiles/development-cli.nix;
        editor = ./home/profiles/editor.nix;
        desktop = ./home/profiles/desktop.nix;
        linux-desktop = ./home/profiles/linux-desktop.nix;
        multimedia = ./home/profiles/multimedia.nix;
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # Small evaluation fixtures keep the public module API independently
      # checkable without importing a private host, inventory, or secret.
      checks = forAllSystems (
        system:
        import ./checks.nix {
          inherit
            system
            nixpkgs
            nix-darwin
            home-manager
            self
            inputs
            ;
        }
      );
    };
}
