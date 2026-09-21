{ inputs, lib, ... }:

{
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    Name=Default
    Default Layout=us
    DefaultIM=rime

    [Groups/0/Items/0]
    Name=keyboard-us
    Layout=

    [Groups/0/Items/1]
    Name=rime
    Layout=

    [GroupOrder]
    0=Default
  '';

  # Keep generated state and user dictionaries unmanaged. Home Manager owns
  # only the portable schema and Emoji support files used by Fcitx5 Rime.
  xdg.dataFile = lib.mapAttrs' (
    name: source: lib.nameValuePair "fcitx5/rime/${name}" { inherit source; }
  ) (import ./rime-files.nix { inherit inputs; });
}
