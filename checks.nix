{
  system,
  nixpkgs,
  nix-darwin,
  home-manager,
  self,
  inputs,
}:
let
  pkgs = import nixpkgs {
    inherit system;
    overlays = [ inputs.lazy-nvim-nix.overlays.default ];
  };
  isDarwin = builtins.match ".*-darwin" system != null;
  home = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [ self.homeModules.base ];
    extraSpecialArgs = {
      username = "example";
      inherit inputs;
    };
  };
  nixos = nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      username = "example";
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
in
{
  home-manager = home.activationPackage;
}
// (
  if isDarwin then
    { }
  else
    {
      nixos-module = nixos.config.system.build.toplevel;
    }
)
