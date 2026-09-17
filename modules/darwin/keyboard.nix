{
  system.defaults = {
    NSGlobalDomain = {
      InitialKeyRepeat = 30;
      KeyRepeat = 5;
    };

    CustomUserPreferences."com.apple.HIToolbox" = {
      AppleCapsLockPressAndHoldToggleOff = false;
      AppleCurrentKeyboardLayoutInputSourceID = "com.apple.keylayout.ABC";

      AppleEnabledInputSources = [
        {
          InputSourceKind = "Keyboard Layout";
          "KeyboardLayout ID" = 252;
          "KeyboardLayout Name" = "ABC";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.SCIM";
          "Input Mode" = "com.apple.inputmethod.SCIM.ITABC";
          InputSourceKind = "Input Mode";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.SCIM";
          InputSourceKind = "Keyboard Input Method";
        }
        {
          "Bundle ID" = "com.apple.CharacterPaletteIM";
          InputSourceKind = "Non Keyboard Input Method";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.Kotoeri.RomajiTyping";
          "Input Mode" = "com.apple.inputmethod.Japanese";
          InputSourceKind = "Input Mode";
        }
        {
          "Bundle ID" = "com.apple.inputmethod.Kotoeri.RomajiTyping";
          InputSourceKind = "Keyboard Input Method";
        }
        {
          "Bundle ID" = "com.apple.50onPaletteIM";
          InputSourceKind = "Non Keyboard Input Method";
        }
        {
          "Bundle ID" = "com.apple.PressAndHold";
          InputSourceKind = "Non Keyboard Input Method";
        }
      ];

      AppleSelectedInputSources = [
        {
          "Bundle ID" = "com.apple.PressAndHold";
          InputSourceKind = "Non Keyboard Input Method";
        }
        {
          "Bundle ID" = "im.rime.inputmethod.Squirrel";
          "Input Mode" = "im.rime.inputmethod.Squirrel.Hans";
          InputSourceKind = "Input Mode";
        }
      ];
    };
  };

  # Squirrel provides the Rime input source configured by Home Manager.
  homebrew.casks = [ "squirrel-app" ];
}
