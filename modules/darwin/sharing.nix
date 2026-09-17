{ config, lib, ... }:

let
  cfg = config.services.localSharing;
in
{
  options.services.localSharing = {
    contentCaching.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable macOS Content Caching.";
    };

    remoteLogin.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable macOS Remote Login over SSH.";
    };

    screenSharing.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable macOS Screen Sharing.";
    };
  };

  config = {
    services.openssh.enable = cfg.remoteLogin.enable;

    system.activationScripts.sharing.text = lib.concatStrings [
      (
        if cfg.contentCaching.enable then
          ''
            if ! /usr/bin/AssetCacheManagerUtil isActivated >/dev/null 2>&1; then
              /usr/bin/AssetCacheManagerUtil activate
            fi
          ''
        else
          ''
            if /usr/bin/AssetCacheManagerUtil isActivated >/dev/null 2>&1; then
              /usr/bin/AssetCacheManagerUtil deactivate
            fi
          ''
      )
      (
        if cfg.screenSharing.enable then
          ''
            /bin/launchctl enable system/com.apple.screensharing
            if ! /bin/launchctl print system/com.apple.screensharing >/dev/null 2>&1; then
              /bin/launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist
            fi
          ''
        else
          ''
            if /bin/launchctl print system/com.apple.screensharing >/dev/null 2>&1; then
              /bin/launchctl bootout system/com.apple.screensharing
            fi
            /bin/launchctl disable system/com.apple.screensharing
          ''
      )
    ];
  };
}
