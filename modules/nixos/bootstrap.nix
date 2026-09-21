{
  lib,
  pkgs,
  ...
}:

{
  boot.kernelParams = [ "console=ttyS0" ];

  networking = {
    firewall.enable = true;
    useDHCP = lib.mkDefault false;
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # cloud-init may install a site-specific bootstrap cache policy here.
    # The missing include is intentionally accepted when no mirror is needed.
    extraOptions = "!include /etc/nix/nix.conf.d/*.conf";
  };

  systemd.tmpfiles.rules = [ "d /etc/nix/nix.conf.d 0755 root root - -" ];

  environment.systemPackages = with pkgs; [
    git
    jq
  ];

  services = {
    cloud-init = {
      enable = true;
      network.enable = true;
    };

    openssh = {
      enable = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };

    qemuGuest.enable = true;
  };

  system.stateVersion = "26.05";
}
