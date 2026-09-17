{ lib, pkgs, ... }:

let
  checkKernel = pkgs.writeShellApplication {
    name = "nixos-kernel-reboot-check";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      set -u

      current_system=/run/current-system
      booted_system=/run/booted-system

      # A system may be evaluated before the booted-system link exists (for
      # example during early boot). In that case, do not make login noisy.
      if [ ! -e "$current_system" ] || [ ! -e "$booted_system" ]; then
        exit 0
      fi

      current_kernel=$(readlink -f "$current_system/kernel" 2>/dev/null || true)
      booted_kernel=$(readlink -f "$booted_system/kernel" 2>/dev/null || true)
      current_modules=$(readlink -f "$current_system/kernel-modules" 2>/dev/null || true)
      booted_modules=$(readlink -f "$booted_system/kernel-modules" 2>/dev/null || true)

      # Each NixOS kernel-modules output contains one release directory.
      module_release() {
        local modules_root=$1
        local module_dir

        for module_dir in "$modules_root"/lib/modules/*; do
          if [ -d "$module_dir" ]; then
            basename "$module_dir"
            return 0
          fi
        done

        return 1
      }

      current_release=$(module_release "$current_modules" 2>/dev/null || true)
      booted_release=$(module_release "$booted_modules" 2>/dev/null || true)
      running_release=$(uname -r 2>/dev/null || true)

      needs_reboot=0

      if [ -z "$current_kernel" ] || [ -z "$booted_kernel" ] || [ "$current_kernel" != "$booted_kernel" ]; then
        needs_reboot=1
      fi

      if [ -z "$current_modules" ] || [ -z "$booted_modules" ] || [ "$current_modules" != "$booted_modules" ]; then
        needs_reboot=1
      fi

      if [ -z "$current_release" ] || [ -z "$booted_release" ] || [ "$current_release" != "$booted_release" ]; then
        needs_reboot=1
      fi

      if [ -z "$running_release" ] || [ "$running_release" != "$booted_release" ]; then
        needs_reboot=1
      fi

      if [ "$needs_reboot" -eq 1 ]; then
        printf '\n'
        printf '\033[1;33mNixOS has a pending kernel update. Please reboot this machine.\033[0m\n'
        printf '  running kernel: %s\n' "''${running_release:-unknown}"
        printf '  booted modules: %s\n' "''${booted_release:-unknown}"
        printf '  built modules:  %s\n' "''${current_release:-unknown}"
        printf '\n'
      fi
    '';
  };
in
{
  environment.systemPackages = [ checkKernel ];

  # This is evaluated by NixOS' system-wide login-shell setup and is kept
  # shell-independent so it also works for zsh, the default shell here.
  environment.loginShellInit = lib.mkAfter ''
    ${checkKernel}/bin/nixos-kernel-reboot-check
  '';
}
