{
  services = {
    xserver.enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    gnome.gnome-keyring.enable = true;
  };

  # Password-based GDM logins should unlock the user's existing keyring
  # instead of prompting to create another one.
  security.pam.services.gdm-password.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
}
