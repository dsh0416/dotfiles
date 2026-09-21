{
  pkgs,
  username,
  ...
}:

{
  imports = [
    ../nix/maintenance.nix
    ./sharing.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = username;
  users.users.${username} = {
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  nix.gc.interval = {
    Weekday = 7;
    Hour = 3;
    Minute = 15;
  };

  nix.optimise.interval = {
    Weekday = 7;
    Hour = 4;
    Minute = 15;
  };

  programs.zsh.enable = true;

  # Do not change this after the first activation without reading the
  # nix-darwin changelog. It is a compatibility level, not a release version.
  system.stateVersion = 6;
}
