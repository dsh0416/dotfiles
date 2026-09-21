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
- `nixosModules.gnome`, `fcitx5`, `fonts`, and `hyper`: individual desktop
  capabilities. `hyper` supplies the existing runtime-library overlay; it does
  not install the application on its own.
- `nixosModules.comin`: configurable automatic NixOS deployment; all private
  repository and host-key values are consumer options.
- `darwinModules.base`, `homebrew`, and capability profiles for desktop,
  development, multimedia, operations, mobile, and TUNA mirrors. Personal service
  applications belong in the consuming private host configuration.
- `homeModules.base`, `linux`, `development-cli`, `editor`, `desktop`,
  `linux-desktop`, and `multimedia`. The existing `desktop` name selects the
  macOS Home Manager profile; `linux` adds the Linux home-directory convention.
- `nixosModules.maintenance` and `darwinModules.maintenance`: shared Nix
  feature, garbage-collection, and store-optimisation policy. Both `base`
  modules import it and retain their platform-specific schedules.

## Composition

Use ordinary Nix module `imports` to select capabilities. Profiles assemble
related settings, while leaf modules own each capability. Where list ordering
matters, existing presets use `lib.mkMerge` to combine settings at their original
definition level so a host's additions retain their precedence. Existing public
names and file entry points remain available.

| Layer | Responsibility |
| --- | --- |
| `modules/nix/` | Policy shared by NixOS and nix-darwin |
| `modules/nixos/`, `modules/darwin/` | Platform capabilities and base settings |
| `modules/*/profiles/` | System capability combinations |
| `home/programs/` | User program settings and shared Rime source manifest |
| `home/darwin/`, `home/linux/` | Platform-specific user settings |
| `home/profiles/` | User capability combinations |
| `config/` | Configuration assets consumed by modules |

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

`nixosModules.desktop` continues to include `server`, its SSH/firewall/sudo
policy, and the development CLI environment. It composes GNOME, Fcitx5, fonts,
the Hyper overlay, Chrome, Kimpanel, and the Linux Home Manager desktop. For a
custom workstation, import the individual capabilities instead of this preset:

```nix
modules = [
  dotfiles.nixosModules.base
  dotfiles.nixosModules.gnome
  dotfiles.nixosModules.fonts
];
```

System profiles that configure a user environment (`server` and `desktop`)
require the consumer's Home Manager integration. Keep supplying `username`
through `specialArgs` and Home Manager's `extraSpecialArgs`. Rime needs
`inputs.rime-emoji`; Neovim needs `inputs.lazy-nvim-nix` and the
`lazy-nvim-nix.overlays.default` overlay, as before. Darwin Homebrew
profiles retain the separate `darwinModules.homebrew` activation policy.

Rime's portable file list is shared across platforms. macOS retains its
versioned copy/reload hook; Linux retains its XDG-managed files. Generated
Rime state and user dictionaries remain outside these modules.

TUNA is opt-in. Import `dotfiles.darwinModules.tuna` or
`dotfiles.nixosModules.tuna` only where the mirror is wanted. The module is
kept separate so existing hosts do not change behavior implicitly.

## Checks

```sh
XDG_CACHE_HOME=/private/tmp/dotfiles-nix-cache nix fmt
XDG_CACHE_HOME=/private/tmp/dotfiles-nix-cache nix flake check --all-systems --no-build path:.
XDG_CACHE_HOME=/private/tmp/dotfiles-nix-cache nix flake check path:.
```

Checks build the existing native Home Manager/base-system fixtures and
evaluate complete Darwin, NixOS server, comin, and opt-in TUNA combinations.
The complete Linux desktop is evaluated on x86_64, matching its Hyper/Chrome
package support, including a host that adds its own fonts to the preset.
`module-composition` records the evaluated derivations without
building entire workstations. No check activates a host.
