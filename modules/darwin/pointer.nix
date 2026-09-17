{
  system.defaults = {
    NSGlobalDomain = {
      "com.apple.swipescrolldirection" = true;
      "com.apple.trackpad.enableSecondaryClick" = true;
      "com.apple.trackpad.forceClick" = true;
      "com.apple.trackpad.scaling" = 1.0;
    };

    ".GlobalPreferences"."com.apple.mouse.scaling" = 1.0;

    trackpad = {
      Clicking = false;
      Dragging = false;
      DragLock = false;
      ActuateDetents = true;
      FirstClickThreshold = 1;
      ForceSuppressed = false;
      SecondClickThreshold = 1;
      TrackpadCornerSecondaryClick = 0;
      TrackpadFourFingerHorizSwipeGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
      TrackpadFourFingerVertSwipeGesture = 2;
      TrackpadMomentumScroll = true;
      TrackpadPinch = true;
      TrackpadRightClick = true;
      TrackpadRotate = true;
      TrackpadThreeFingerDrag = false;
      TrackpadThreeFingerHorizSwipeGesture = 2;
      TrackpadThreeFingerTapGesture = 2;
      TrackpadThreeFingerVertSwipeGesture = 2;
      TrackpadTwoFingerDoubleTapGesture = true;
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
    };

    magicmouse.MouseButtonMode = "OneButton";

    CustomUserPreferences = {
      "com.apple.AppleMultitouchTrackpad" = {
        TrackpadFiveFingerPinchGesture = 2;
        TrackpadHandResting = true;
        TrackpadHorizScroll = true;
        TrackpadScroll = true;
      };
      "com.apple.driver.AppleBluetoothMultitouch.trackpad" = {
        TrackpadFiveFingerPinchGesture = 2;
        TrackpadHandResting = true;
        TrackpadHorizScroll = true;
        TrackpadScroll = true;
      };
      "com.apple.AppleMultitouchMouse" = {
        MouseHorizontalScroll = true;
        MouseMomentumScroll = true;
        MouseOneFingerDoubleTapGesture = 0;
        MouseTwoFingerDoubleTapGesture = 3;
        MouseTwoFingerHorizSwipeGesture = 2;
        MouseVerticalScroll = true;
      };
      "com.apple.driver.AppleBluetoothMultitouch.mouse" = {
        MouseHorizontalScroll = true;
        MouseMomentumScroll = true;
        MouseOneFingerDoubleTapGesture = 0;
        MouseTwoFingerDoubleTapGesture = 3;
        MouseTwoFingerHorizSwipeGesture = 2;
        MouseVerticalScroll = true;
      };
      "com.apple.driver.AppleHIDMouse" = {
        Button1 = true;
        Button2 = true;
        Button3 = false;
        Button4 = false;
        Button4Click = false;
        Button4Force = false;
        ButtonDominance = true;
        ScrollH = true;
        ScrollS = 4;
        ScrollSSize = 30;
        ScrollV = true;
      };
    };
  };
}
