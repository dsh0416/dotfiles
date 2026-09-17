{ username, ... }:

{
  imports = [ ./base.nix ];

  home.homeDirectory = "/home/${username}";
}
