{ lib, ... }:

{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/xhtml+xml" = [ "google-chrome.desktop" ];
      "text/html" = [ "google-chrome.desktop" ];
      "x-scheme-handler/http" = [ "google-chrome.desktop" ];
      "x-scheme-handler/https" = [ "google-chrome.desktop" ];
    };
  };

  # GNOME's user dconf settings control suspend independently of the
  # systemd sleep targets. Keep unattended Linux desktop displays awake,
  # including when the lid or power button is used.
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-ac-timeout = 0;
      sleep-inactive-battery-type = "nothing";
      sleep-inactive-battery-timeout = 0;
      lid-close-ac-action = "nothing";
      lid-close-battery-action = "nothing";
      power-button-action = "nothing";
      idle-dim = false;
    };

    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 0;
    };

    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
    };
  };
}
