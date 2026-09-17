{
  homebrew = {
    enable = true;

    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    # Remove formulae and casks that are not part of the declared Brewfile.
    onActivation.cleanup = "uninstall";
  };
}
