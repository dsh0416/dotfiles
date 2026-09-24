# dotfiles

Reusable NixOS, nix-darwin, and Home Manager modules extracted from a private
infrastructure repository.

This repository intentionally contains no hosts, inventory, domains, IPAM,
deployment credentials, or secrets. Private infrastructure composes these
modules and supplies its own `username`, host settings, repository URL, and
SSH host keys.

## Public module API

- `nixosModules.base`: common server base, system-wide Python and Unix build
  tools, garbage collection, optimisation, zram/swap, latest kernel, and
  login-time kernel reboot notification.
- `nixosModules.server` and `nixosModules.desktop`: SSH-only server/TUI and
  GNOME workstation layers.
- `nixosModules.gnome`, `fcitx5`, `fonts`, and `hyper`: individual desktop
  capabilities. `hyper` supplies the existing runtime-library overlay; it does
  not install the application on its own.
- `nixosModules.podman`: Podman, Docker CLI compatibility, container-name DNS,
  IPv6-capable default networking, and the declarative OCI backend. Consumers
  retain ownership of fleet-specific subnets and routed addresses.
- `nixosModules.bootstrap`: the cloud-init, serial-console, key-only SSH, and
  QEMU guest baseline used by bootstrap VM images.
- `nixosModules.caddy-cloudflare`: Caddy built with the Cloudflare DNS plugin;
  domains, credentials, ACME identity, firewall policy, and virtual hosts stay
  in the consuming infrastructure repository.
- `nixosModules.comin`: configurable automatic NixOS deployment; all private
  repository and host-key values are consumer options.
- `nixosModules.gitlab-nix-runner`: GitLab Docker-executor jobs backed by
  Podman and isolated, persistent local Nix stores. Each named trust domain has
  its own daemon socket, build users, store, and mutable cache; consumers
  provide runtime token paths and resource limits.
- `darwinModules.base`, `homebrew`, and capability profiles for desktop,
  development, multimedia, operations, mobile, and TUNA mirrors. The base also
  supplies system-wide Python and Unix build tools. Personal service applications
  belong in the consuming private host configuration.
- Darwin keyboard, pointer, sharing, Scroll Reverser, and Tinycast leaves are
  exported for consumers that need finer composition than the desktop profile.
- `homeModules.base`, `linux`, `development-cli`, `editor`, `desktop`,
  `linux-desktop`, and `multimedia`. The existing `desktop` name selects the
  macOS Home Manager profile; `linux` adds the Linux home-directory convention.
- Program-level Home Manager modules are exported for CLI, Git, Hyper, mise,
  Neovim, Rime, Starship, Zed, and Zsh.
- `nixosModules.maintenance` and `darwinModules.maintenance`: shared Nix
  feature, garbage-collection, and store-optimisation policy. Both `base`
  modules import it and retain their platform-specific schedules.
- `nixosModules.build-tools` and `darwinModules.build-tools`: shared Python,
  C/C++ compiler, GNU Make, and pkg-config toolchain. Both `base` modules import
  it so mise can compile runtimes and Rust projects can invoke a system linker.
  On NixOS it also exposes zlib, readline, OpenSSL, bzip2, libffi, gdbm, xz,
  zstd, Tcl/Tk, and SQLite headers and link metadata for mise-managed Python
  source builds.
- `homeModules.mise` supplies nixpkgs' Nix-aware `rustup` as mise's Rust
  bootstrap, avoiding the incompatible generic Linux `rustup-init` on NixOS.

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

The GitLab Nix runner module keeps the container executor separate from Nix
build execution. A consumer supplies one runtime authentication file per trust
domain:

```nix
{
  imports = [ dotfiles.nixosModules.gitlab-nix-runner ];

  services.dotfiles-gitlab-nix-runner = {
    enable = true;
    instances.private = {
      authenticationTokenConfigFile = "/run/secrets/gitlab-runner-token";
      maxJobs = 2;
      requestConcurrency = 2;
    };
  };
}
```

Each instance has a different store, daemon socket, build users, and `/cache`.
Jobs receive the store as a read-only mount and the daemon treats every client
as untrusted. `XDG_CACHE_HOME` points at `/cache/xdg`, which preserves Nix's
flake source metadata between fresh job containers. Do not place public/fork
jobs and private source in the same instance: every job in one instance can
read that instance's store. Store garbage collection is deliberately left to
the consumer so it cannot remove a path while a container is executing it.

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

## mise releases

`homeModules.mise` installs the package maintained in `packages/mise/`, also
available as `packages.<system>.mise`. It uses pinned upstream release archives
for Apple Silicon macOS and both x86_64 and aarch64 Linux (static musl builds).
Its release cycle is independent of the consumer's NixOS/nixpkgs version.
The upstream binary finds helper tools such as Git and Bash on `PATH`; direnv
integration also needs `direnv`. Provide those tools when using the package in
an isolated shell.

From this repository, update to the latest stable release or an explicit version:

```sh
nix run .#update-mise
nix run .#update-mise -- 2026.9.12
nix build .#mise
```

The updater downloads all three archives and verifies their SHA-256 checksums
against the release checksum file before replacing `packages/mise/sources.json`.
Review and commit that manifest, then update the consuming repository's
`dotfiles` input. Builds use only the committed version and hashes; they never
resolve `latest`. No additional nixpkgs input or consumer overlay is needed.

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

The `overlays.synergy3` overlay supplies a package for the vendor-provided
Synergy 3 Debian artifact. Because the download requires an authenticated
account, the consumer must add the named fixed-output source to the Nix store
before building.
