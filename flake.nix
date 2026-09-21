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
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lazy-nvim-nix = {
      url = "github:josh/lazy-nvim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        bootstrap = ./modules/nixos/bootstrap.nix;
        caddy-cloudflare = ./modules/nixos/caddy-cloudflare.nix;
        comin = ./modules/nixos/comin.nix;
        gnome = ./modules/nixos/gnome.nix;
        fcitx5 = ./modules/nixos/fcitx5.nix;
        fonts = ./modules/nixos/fonts.nix;
        hyper = ./modules/nixos/hyper.nix;
        gitlab-nix-runner = ./modules/nixos/gitlab-nix-runner.nix;
        build-tools = ./modules/nix/build-tools.nix;
        maintenance = ./modules/nix/maintenance.nix;
        podman = ./modules/nixos/podman.nix;
        tuna = ./modules/nix/tuna.nix;
      };

      darwinModules = {
        base = ./modules/darwin/base.nix;
        homebrew = ./modules/darwin/homebrew.nix;
        keyboard = ./modules/darwin/keyboard.nix;
        pointer = ./modules/darwin/pointer.nix;
        scroll-reverser = ./modules/darwin/scroll-reverser.nix;
        sharing = ./modules/darwin/sharing.nix;
        tinycast = ./modules/darwin/tinycast.nix;
        desktop = ./modules/darwin/profiles/desktop.nix;
        development = ./modules/darwin/profiles/development.nix;
        multimedia = ./modules/darwin/profiles/multimedia.nix;
        operations = ./modules/darwin/profiles/operations.nix;
        mobile = ./modules/darwin/profiles/mobile.nix;
        build-tools = ./modules/nix/build-tools.nix;
        maintenance = ./modules/nix/maintenance.nix;
        tuna = ./modules/nix/tuna.nix;
      };

      homeModules = {
        base = ./home/base.nix;
        linux = ./home/linux.nix;
        cli = ./home/programs/cli.nix;
        git = ./home/programs/git.nix;
        hyper = ./home/programs/hyper.nix;
        mise = ./home/programs/mise.nix;
        neovim = ./home/programs/neovim.nix;
        rime = ./home/programs/rime.nix;
        rime-linux = ./home/programs/rime-linux.nix;
        starship = ./home/programs/starship.nix;
        zed = ./home/programs/zed.nix;
        zsh = ./home/programs/zsh.nix;
        development-cli = ./home/profiles/development-cli.nix;
        editor = ./home/profiles/editor.nix;
        desktop = ./home/profiles/desktop.nix;
        linux-desktop = ./home/profiles/linux-desktop.nix;
        multimedia = ./home/profiles/multimedia.nix;
      };

      overlays.synergy3 = final: _: {
        synergy3 = final.callPackage ./packages/synergy3.nix { };
      };

      packages = forAllSystems (system: {
        mise = nixpkgs.legacyPackages.${system}.callPackage ./packages/mise { };
      });

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          updateMise = pkgs.writeShellApplication {
            name = "update-mise";
            runtimeInputs = [ pkgs.python3 ];
            text = ''
              exec python3 ${./packages/mise/update.py} \
                --manifest "$PWD/packages/mise/sources.json" "$@"
            '';
          };
        in
        {
          update-mise = {
            type = "app";
            program = "${updateMise}/bin/update-mise";
          };
        }
      );

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
