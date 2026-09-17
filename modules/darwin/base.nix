{ pkgs, username, ... }:

{
  imports = [ ./sharing.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = username;
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 7;
      Hour = 3;
      Minute = 15;
    };
    options = "--delete-older-than 30d";
  };

  nix.optimise = {
    automatic = true;
    interval = {
      Weekday = 7;
      Hour = 4;
      Minute = 15;
    };
  };

  programs.zsh.enable = true;

  # Do not change this after the first activation without reading the
  # nix-darwin changelog. It is a compatibility level, not a release version.
  system.stateVersion = 6;
}
