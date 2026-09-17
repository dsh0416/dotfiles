{ ... }:

{
  home.sessionVariables = {
    EDITOR = "zed --wait";
    VISUAL = "zed --wait";
    GIT_EDITOR = "zed --wait";
  };

  xdg.configFile."zed/settings.json" = {
    source = ../../config/zed/settings.json;
    force = true;
  };
}
