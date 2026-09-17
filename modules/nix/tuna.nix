{ lib, ... }:

{
  # Prefer TUNA's mirror while retaining the upstream binary cache as the
  # fallback automatically supplied by Nix.
  nix.settings.substituters = lib.mkBefore [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];

  environment.variables = {
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
  };
}
