{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  home-manager.users.nixos.imports = [
    ../../home/linux.nix
    ../../home/profiles/linux-desktop.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "kiosk";

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  networking.networkmanager.enable = true;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "google-chrome" ];
  environment.systemPackages = [ pkgs.google-chrome ];

  fonts.packages = with pkgs; [
    liberation_ttf
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "nixos";

  # This is a wall display, not a battery workstation: never lock or suspend
  # the GNOME session while Grafana is being displayed.
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.desktop.session]
    idle-delay=uint32 0

    [org.gnome.desktop.screensaver]
    lock-enabled=false

    [org.gnome.settings-daemon.plugins.power]
    sleep-inactive-ac-type='nothing'
    sleep-inactive-ac-timeout=0
    sleep-inactive-battery-type='nothing'
    sleep-inactive-battery-timeout=0
  '';

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    "hybrid-sleep".enable = false;
  };

  # Keep password SSH available during the initial bring-up.  Replace this
  # with an authorized key before exposing the host beyond the home LAN.
  services.openssh.enable = true;
  services.openssh.settings = {
    AuthenticationMethods = lib.mkForce "password";
    KbdInteractiveAuthentication = lib.mkForce false;
    PasswordAuthentication = lib.mkForce true;
    PermitRootLogin = lib.mkForce "no";
    PubkeyAuthentication = lib.mkForce false;
  };

  users.users.nixos = {
    initialPassword = "nixos";
    extraGroups = [ "networkmanager" ];
  };
  security.sudo.wheelNeedsPassword = false;

  networking.firewall.allowedTCPPorts = [ 22 ];

  # Use the existing Chrome choice on the op machine.  The URL is deliberately
  # a single obvious value to replace once the Grafana endpoint is confirmed.
  environment.etc."xdg/autostart/grafana-kiosk.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Grafana kiosk
    Exec=${pkgs.google-chrome}/bin/google-chrome-stable --no-first-run --disable-session-crashed-bubble --password-store=basic --kiosk http://grafana.home.delton.me/
    X-GNOME-Autostart-enabled=true
  '';

}
