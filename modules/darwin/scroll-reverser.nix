{
  homebrew.casks = [ "scroll-reverser" ];

  system.defaults.CustomUserPreferences."com.pilotmoon.scroll-reverser" = {
    InvertScrollingOn = true;
    ReverseMouse = true;
    ReverseTrackpad = false;
    ReverseX = true;
    ReverseY = true;
  };
}
