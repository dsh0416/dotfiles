{ config, lib, inputs, ... }:
let
  cfg = config.services.dotfiles-comin;
in
{
  options.services.dotfiles-comin = {
    enable = lib.mkEnableOption "automatic NixOS deployment with comin";
    hostname = lib.mkOption { type = lib.types.str; description = "NixOS configuration name to build."; };
    repository = lib.mkOption { type = lib.types.str; description = "Git repository containing the flake."; };
    hostName = lib.mkOption { type = lib.types.str; description = "Git server hostname for SSH host-key pinning."; };
    branch = lib.mkOption { type = lib.types.str; default = "main"; };
    deployKey = lib.mkOption { type = lib.types.str; default = "/var/lib/comin/credentials/git-deploy-key"; };
    sshHostKey = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; description = "Optional Git server host key."; };
  };

  imports = [ inputs.comin.nixosModules.comin ];

  config = lib.mkIf cfg.enable {
    assertions = [{ assertion = cfg.sshHostKey != null; message = "services.dotfiles-comin.sshHostKey must be set"; }];
    programs.ssh.knownHosts.dotfiles-comin = {
      hostNames = [ cfg.hostName ];
      publicKey = cfg.sshHostKey;
    };
    services.comin = {
      enable = true;
      hostname = cfg.hostname;
      repositoryType = "flake";
      remotes = [{
        name = "origin";
        url = cfg.repository;
        auth = {
          username = "git";
          ssh_deploy_key_path = cfg.deployKey;
          ssh_known_hosts_path = "/etc/ssh/ssh_known_hosts";
        };
        branches.main = { name = cfg.branch; operation = "switch"; };
      }];
    };
    systemd.tmpfiles.rules = [ "d ${builtins.dirOf cfg.deployKey} 0700 root root - -" ];
    systemd.services.comin.unitConfig.ConditionPathExists = cfg.deployKey;
  };
}
