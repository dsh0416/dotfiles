# dotfiles

Reusable NixOS, nix-darwin, and Home Manager modules extracted from a private
infrastructure repository.

This repository intentionally contains no hosts, inventory, domains, IPAM,
deployment credentials, or secrets. Private infrastructure composes these
modules and supplies its own `username`, host settings, repository URL, and
SSH host keys.

## Public module API

- `nixosModules.base`: common server base, garbage collection, optimisation,
  zram/swap, latest kernel, and login-time kernel reboot notification.
- `nixosModules.server` and `nixosModules.desktop`: SSH-only server/TUI and
  GNOME workstation layers.
- `nixosModules.comin`: configurable automatic NixOS deployment; all private
  repository and host-key values are consumer options.
- `darwinModules.base`, `homebrew`, and capability profiles for desktop,
  development, multimedia, operations, mobile, and TUNA mirrors. Personal service
  applications belong in the consuming private host configuration.
- `homeModules.base`, `development-cli`, `desktop`, and `linux-desktop`.

Compose only the capabilities needed by a host. For example:

```nix
modules = [
  dotfiles.nixosModules.base
  dotfiles.nixosModules.server
];

home-manager.users.example.imports = [
  dotfiles.homeModules.linux
  dotfiles.homeModules.development-cli
];
```

TUNA is opt-in. Import `dotfiles.darwinModules.tuna` or
`dotfiles.nixosModules.tuna` only where the mirror is wanted. The module is
kept separate so existing hosts do not change behavior implicitly.

## Checks

```sh
XDG_CACHE_HOME=/private/tmp/dotfiles-nix-cache nix flake check path:.
```
