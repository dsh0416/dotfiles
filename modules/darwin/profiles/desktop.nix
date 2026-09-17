{
  imports = [
    ../keyboard.nix
    ../pointer.nix
    ../scroll-reverser.nix
    ../tinycast.nix
  ];

  homebrew = {
    casks = [
      "1password"
      "betterdisplay"
      "chatgpt"
      "font-iosevka"
      "font-iosevka-nerd-font"
      "font-sarasa-gothic"
      "google-chrome"
      "hyper"
      "keka"
      "windows-app"
    ];

    masApps = {
      "DaisyDisk 2" = 411643860;
      Keynote = 361285480;
      Speedtest = 1153157709;
    };
  };
}
