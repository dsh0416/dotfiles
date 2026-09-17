{ username, ... }:

{
  imports = [ ../openssh-server.nix ];

  # Servers get the same shell, editor, prompt, and CLI/TUI environment as
  # development hosts, without pulling in desktop-only applications.
  home-manager.users.${username}.imports = [ ../../../home/profiles/development-cli.nix ];

  networking.firewall.enable = true;

  # Server users authenticate with SSH keys and do not have login passwords.
  security.sudo.wheelNeedsPassword = false;
}
