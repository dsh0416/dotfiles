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
- Program-level Home Manager modules are exported for CLI, Git, Hyper, mise, pi,
  Neovim, Rime, Starship, Zed, and Zsh.
- `nixosModules.maintenance` and `darwinModules.maintenance`: shared Nix
  feature, garbage-collection, and store-optimisation policy. Both `base`
  modules import it and retain their platform-specific schedules.
- `nixosModules.build-tools` and `darwinModules.build-tools`: shared Python,
  C/C++ compiler, GNU Make, and pkg-config toolchain. Both `base` modules import
  it so mise can compile runtimes and Rust projects can invoke a system linker.
  On NixOS it also exposes zlib, readline, OpenSSL, bzip2, libffi, gdbm, xz,
  zstd, Tcl/Tk, and SQLite headers and link metadata for mise-managed Python
  source builds, plus the GCC runtime and zlib search path needed by binary
  Python wheels such as NumPy. The NixOS base also enables `nix-ld` so
  mise-managed upstream Linux binaries such as uv can use the conventional
  dynamic-loader path.
- `homeModules.mise` declares a global stable Rust toolchain in mise and uses
  upstream rustup in dedicated user directories. Nix supplies the native
  compiler and libraries; the NixOS base supplies `nix-ld` for upstream binaries.

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

## Pi agent

`homeModules.base` installs Pi on macOS and Linux, including
the server profile when composed with `homeModules.linux`. The standalone
`homeModules.pi` module is also exported. The package in `packages/pi/` pins
official standalone release archives independently of nixpkgs. It includes its
runtime; no global npm install or separate Node installation is required.
The same package is exposed as `packages.<system>.pi` for Apple Silicon macOS
and x86_64/aarch64 Linux. Linux executables and native helpers are patched for
Nix's dynamic-loader and library paths; the macOS signed executable is preserved.
Consumers must update their `dotfiles` input and activate their NixOS,
nix-darwin, or Home Manager configuration to deploy the change.

From this repository, update to the latest stable release or an explicit version:

```sh
nix run .#update-pi
nix run .#update-pi -- 0.99.1
nix build .#pi
```

The updater downloads all three archives, verifies their SHA-256 hashes against
the upstream `SHA256SUMS` file and available GitHub asset digests, then updates
`packages/pi/sources.json`. Commit the manifest and update the consumer's
`dotfiles` input to deploy the new version. Builds use only the recorded version
and hashes; they never resolve `latest`. Use this update command for the Nix
package rather than Pi's self-updater.

Renovate tracks Pi releases and updates the version and SHA-256 digest for all
three platform archives together in a dedicated `Pi releases` PR. The custom
datasource reads GitHub release asset digests and only offers published stable
releases with all three archives and valid SHA-256 digests. No post-upgrade
command or extra GitHub Actions write token is required. Updates retain manual
merge approval and the normal Linux/macOS build checks.

The manifest records a version next to each platform's `sha256` so Renovate can
replace each version/checksum pair reliably. Nix rejects mismatched platform
versions. The manual updater remains available and additionally downloads every
archive to verify it against upstream `SHA256SUMS` before updating the manifest.

Recent Pi versions also refresh their model catalog separately from the program:

```sh
pi update --models
```

This can make newly cataloged models available without a package update; new API
features and provider implementations can still require a newer Pi release.
The refreshed catalog is runtime state and stays local to each machine. See
the upstream [model guide](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/models.md).

Keep shared preferences in `config/pi/settings.json`. It starts as `{}` because
there are no existing local preferences to migrate. For example:

```json
{
  "quietStartup": true,
  "defaultThinkingLevel": "high",
  "terminal": { "showImages": true }
}
```

Home Manager merges these preferences into the writable
`~/.pi/agent/settings.json` on every activation. Shared values take precedence;
unmanaged local keys and nested siblings survive. Removing a shared preference
also removes the previously managed value on the next activation. Pi can still
save `/settings`, `/model`, and package changes normally. To retain changes to
managed preferences across activations, edit the shared source and commit it.
Resource arrays in shared settings replace their corresponding local arrays.
Pi package declarations can live in `packages` (pin their versions for consistent
machines); downloaded package contents remain local and Pi manages their
installation. Nix activation does not fetch Pi packages.

Add any of these files or directories under `config/pi/` and the module links
them into `~/.pi/agent/` on the next activation:

| Shared source | Purpose |
| --- | --- |
| `keybindings.json` | Keyboard shortcuts |
| `AGENTS.md`, `AGENTS.override.md` | Global instructions |
| `SYSTEM.md`, `APPEND_SYSTEM.md` | System prompt replacement or additions |
| `skills/`, `prompts/` | Skills and slash-command templates |
| `extensions/`, `themes/` | Extension code and custom themes |
| `mcp.json` | MCP configuration for Pi versions/extensions that support it |

Directories use individual file links, so other local resources can coexist.
For example, add `config/pi/skills/my-skill/SKILL.md` or
`config/pi/prompts/review.md`. Commit actual files and their supporting assets;
links to machine-specific locations will not work on other machines. Existing
files at a managed destination must be moved aside or backed up before the
first activation; the module does not force-overwrite them. Linked resources
are read-only: edit their dotfiles sources.

Keep `auth.json`, `models.json`, `models-store.json`, sessions, caches, and
downloaded binaries/packages on each machine. They are excluded from management
and ignored under `config/pi/`. Set `defaultProvider`, `defaultModel`,
`enabledModels`, and per-model settings locally; provider/model selection keys
are rejected in shared settings. Use environment variable references for any
credentials needed by shared extension or MCP configuration. The module uses
Pi's default agent directory; keep `PI_CODING_AGENT_DIR` unset when using it.
See the upstream [configuration guide](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/configuration.md)
and the settings documentation shipped with the installed Pi version.

The deployment keeps a local `.dotfiles-settings.json` snapshot of previously
managed preferences, writes settings atomically, and respects Pi's settings lock.
Invalid existing JSON or a held lock stops deployment without overwriting the
settings. `settings.json` must be a regular writable file, not a store symlink.

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

## Rust toolchains

`homeModules.mise` gives mise ownership of Rust versions, components, and
targets through upstream rustup. Its global default is `stable`; project
`mise.toml` files can select a specific release or nightly. Both mise and
standalone rustup/Cargo commands use `~/.local/share/mise-rustup` and
`~/.local/share/mise-cargo`. The explicit homes prevent mise from selecting
nixpkgs' rustup bootstrap or reusing previously patched toolchains. The module
provides mise shims and the new Cargo bin directory on `PATH`.

On NixOS, also import `nixosModules.base` or enable `programs.nix-ld` with the
runtime libraries needed by upstream tools. Keep `nixosModules.build-tools`
for the native compiler and library development outputs. On Linux x86_64,
the managed Cargo configuration selects Nix's `cc` driver and disables Rust's
self-contained lld via `-C linker-features=-lld`. The compiler path is retained
by the Home Manager generation. Darwin and Linux aarch64 retain their default
linker selection. Project Cargo configurations can override these settings;
merge the linker feature flag into project-specific `rustflags` when needed.

After updating the consumer's dotfiles input and activating its configuration:

1. Start a fresh login session so the new `PATH`, `CARGO_HOME`, and
   `RUSTUP_HOME` replace the previous session's settings. Remove manual shell
   startup lines that prepend the old `~/.cargo/bin` or source `~/.cargo/env`.
2. Run `mise install` from a trusted project or your home directory. This
   downloads upstream rustup and the selected Rust toolchains into the new
   directories. Activation itself does not install mutable toolchains.
3. Check `mise exec -- rustup show` and `mise exec -- cargo --version`.
   Reinstall additional components, targets, and standalone Cargo tools in
   the new home as needed. Existing tool binaries under mise's own installs
   remain available.
4. Keep `~/.rustup` and `~/.cargo` as migration backups until your projects
   work. The module leaves them untouched; copying old toolchains into the
   new directories would reintroduce the broken linker wrappers.

Nixpkgs' rustup patches downloaded toolchains with concrete Nix store paths,
including an lld wrapper. Toolchains in a mutable user directory do not
automatically retain those dependencies as GC roots. Using upstream rustup
avoids that wrapper dependency. Locally compiled programs can still reference
Nix libraries: rebuild them after dependency changes, or package durable
tools with Nix so their runtime dependencies remain in the closure. Use a
project devShell for additional native dependencies.

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
