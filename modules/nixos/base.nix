{
  pkgs,
  username,
  ...
}:

{
  imports = [
    ../nix/build-tools.nix
    ../nix/maintenance.nix
    ./kernel-reboot-check.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  networking.enableIPv6 = true;

  # Make firmware inventory and updates available on every NixOS host. The
  # updater is only queried explicitly; enabling the service does not flash
  # firmware by itself.
  services.fwupd.enable = true;

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

  nix.gc.dates = "Sun 03:15";
  nix.optimise.dates = [ "Sun 04:15" ];

  programs.zsh.enable = true;

  # Keep this at the version used for the first NixOS activation. It is a
  # compatibility level, not the currently installed NixOS release.
  system.stateVersion = "26.05";
}
