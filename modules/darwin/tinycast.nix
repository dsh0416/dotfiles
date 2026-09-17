{
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys".AppleSymbolicHotKeys."64".enabled = false;

    "com.tinycast.app" = {
      "hotkey.togglePalette" = builtins.toJSON {
        combo._0 = {
          carbonKeyCode = 49;
          carbonModifiers = 256;
        };
      };
      launcherSearchScopes = [
        "/Applications"
        "/Applications/Utilities"
        "/System/Applications"
        "/System/Applications/Utilities"
        "/System/Library/CoreServices/Applications"
        "/System/Volumes/Preboot/Cryptexes/App/System/Applications"
        "/System/Library/CoreServices/Finder.app"
        "~/Applications"
      ];
    };
  };

  homebrew = {
    taps = [
      {
        name = "abue-ammar/tinycast";
        trusted = true;
      }
    ];
    casks = [ "tinycast" ];
  };

  launchd.user.agents.tinycast = {
    command = "/usr/bin/open -a Tinycast";
    serviceConfig = {
      RunAtLoad = true;
      LimitLoadToSessionType = "Aqua";
      ProcessType = "Interactive";
    };
  };
}
