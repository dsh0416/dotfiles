{ pkgs, username, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  imports = [ ./kernel-reboot-check.nix ];

  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.enableIPv6 = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 8 * 1024;
    }
  ];

  nix.gc = {
    automatic = true;
    dates = "Sun 03:15";
    options = "--delete-older-than 30d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "Sun 04:15" ];
  };

  programs.zsh.enable = true;

  # Keep this at the version used for the first NixOS activation. It is a
  # compatibility level, not the currently installed NixOS release.
  system.stateVersion = "26.05";
}
