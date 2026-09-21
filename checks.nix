{
  system,
  nixpkgs,
  nix-darwin,
  home-manager,
  self,
  inputs,
}:
let
  lib = nixpkgs.lib;
  username = "example";
  pkgs = import nixpkgs {
    inherit system;
    overlays = [ inputs.lazy-nvim-nix.overlays.default ];
  };
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  home = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules =
      if isDarwin then
        [
          self.homeModules.base
          self.homeModules.desktop
        ]
      else
        [
          self.homeModules.linux
          self.homeModules.editor
        ];
    extraSpecialArgs = {
      inherit inputs username;
    };
  };
  nixos = nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs username;
    };
    modules = [
      self.nixosModules.base
      {
        fileSystems."/" = {
          device = "/dev/vda1";
          fsType = "ext4";
        };
        boot.loader.grub.devices = [ "/dev/vda" ];
      }
    ];
  };

  # Exercise the combinations used by consumers without building entire
  # workstations in CI. Forcing each toplevel drvPath still checks option
  # types, assertions, package availability, and Home Manager integration.
  darwin = nix-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs username; };
    modules = [
      self.darwinModules.base
      self.darwinModules.homebrew
      self.darwinModules.desktop
      self.darwinModules.development
      self.darwinModules.multimedia
      self.darwinModules.operations
      self.darwinModules.mobile
      home-manager.darwinModules.home-manager
      {
        nixpkgs.overlays = [ inputs.lazy-nvim-nix.overlays.default ];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs username; };
          users.${username}.imports = [
            self.homeModules.base
            self.homeModules.desktop
            self.homeModules.development-cli
            self.homeModules.multimedia
          ];
        };
      }
    ];
  };
  server = nixos.extendModules {
    modules = [
      self.nixosModules.server
      home-manager.nixosModules.home-manager
      {
        nixpkgs.overlays = [ inputs.lazy-nvim-nix.overlays.default ];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs username; };
          users.${username}.imports = [ self.homeModules.linux ];
        };
      }
    ];
  };
  desktop = server.extendModules {
    modules = [
      self.nixosModules.desktop
      {
        home-manager.users.${username}.imports = [ self.homeModules.multimedia ];
      }
    ];
  };
  comin = server.extendModules {
    modules = [
      self.nixosModules.comin
      {
        services.dotfiles-comin = {
          enable = true;
          hostname = "example";
          repository = "https://example.invalid/config.git";
          hostName = "example.invalid";
          sshHostKey = "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        };
      }
    ];
  };
  withTuna = (if isDarwin then darwin else server).extendModules {
    modules = [ (if isDarwin then self.darwinModules.tuna else self.nixosModules.tuna) ];
  };
  withHostFonts = desktop.extendModules {
    modules = [
      ({ pkgs, ... }: { fonts.packages = [ pkgs.dejavu_fonts ]; })
    ];
  };
  withHostFeatures = (if isDarwin then darwin else server).extendModules {
    modules = [ { nix.settings.experimental-features = [ "ca-derivations" ]; } ];
  };
  mirror = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store";
  compositionTargets =
    if isDarwin then
      {
        darwin = darwin.config.system.build.toplevel.drvPath;
        tuna = withTuna.config.system.build.toplevel.drvPath;
      }
    else
      {
        server = server.config.system.build.toplevel.drvPath;
        comin = comin.config.system.build.toplevel.drvPath;
        tuna = withTuna.config.system.build.toplevel.drvPath;
      }
      # Hyper and Chrome in the existing desktop profile target x86_64 Linux.
      // lib.optionalAttrs (system == "x86_64-linux") {
        desktop = desktop.config.system.build.toplevel.drvPath;
        # Host additions must keep their original precedence over the preset.
        desktop-host-fonts =
          assert
            lib.take 2 (
              lib.filter (
                name:
                builtins.elem name [
                  "dejavu-fonts"
                  "liberation-fonts"
                ]
              ) (map lib.getName withHostFonts.config.fonts.packages)
            ) == [
              "dejavu-fonts"
              "liberation-fonts"
            ];
          withHostFonts.config.system.build.toplevel.drvPath;
      };
in
{
  home-manager = home.activationPackage;
  module-composition =
    assert
      !(builtins.elem mirror (if isDarwin then darwin else server).config.nix.settings.substituters);
    assert builtins.head withTuna.config.nix.settings.substituters == mirror;
    assert
      withHostFeatures.config.nix.settings.experimental-features == (
        # These fixtures have different module orders; preserve each result.
        if isDarwin then
          [
            "nix-command"
            "flakes"
            "ca-derivations"
          ]
        else
          [
            "ca-derivations"
            "nix-command"
            "flakes"
          ]
      );
    pkgs.writeText "module-composition.json" (
      # Record evaluated derivations, not build dependencies on every desktop.
      builtins.unsafeDiscardStringContext (builtins.toJSON compositionTargets)
    );
}
// (
  if isDarwin then
    { }
  else
    {
      nixos-module = nixos.config.system.build.toplevel;
    }
)
