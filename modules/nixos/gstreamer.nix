{ lib, pkgs, ... }:

let
  packages = with pkgs.gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ];
in
{
  environment.systemPackages = packages;

  # Applications launched by the desktop need the plugin paths too, not just
  # the gst-* tools whose Nixpkgs wrappers search the installed profiles.
  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
    lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0"
      packages;
}
