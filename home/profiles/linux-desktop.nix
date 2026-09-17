{ pkgs, ... }:

{
  imports = [
    ../programs/hyper.nix
    ../programs/rime-linux.nix
  ];

  home.packages = [ pkgs.hyper ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/xhtml+xml" = [ "google-chrome.desktop" ];
      "text/html" = [ "google-chrome.desktop" ];
      "x-scheme-handler/http" = [ "google-chrome.desktop" ];
      "x-scheme-handler/https" = [ "google-chrome.desktop" ];
    };
  };
}
