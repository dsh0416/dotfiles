{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.dotfiles-gitlab-nix-runner;

  jobPackages = with pkgs; [
    bashInteractive
    cacert
    coreutils
    curl
    findutils
    gawk
    git
    gnugrep
    gnutar
    gzip
    jq
    nix
    openssh
    which
    xz
  ];

  jobImageName = "localhost/dotfiles-gitlab-nix-runner:${pkgs.nix.version}";
  jobPath = lib.makeBinPath jobPackages;
  fakeNss = pkgs.dockerTools.fakeNss;

  jobImage = pkgs.dockerTools.buildLayeredImage {
    name = "localhost/dotfiles-gitlab-nix-runner";
    tag = pkgs.nix.version;

    contents = jobPackages;
    # The same closures are copied into each isolated CI store by its seed
    # unit. Keep only root-level links in the image so the mounted store is the
    # single source of package contents at runtime.
    includeStorePaths = false;

    extraCommands = ''
      mkdir -p etc root tmp usr
      # Podman reads and may modify these files while preparing the container,
      # before runtime bind mounts such as /nix/store are active. They must be
      # regular image files rather than fakeNss symlinks into the Nix store.
      cp -L ${fakeNss}/etc/passwd etc/passwd
      cp -L ${fakeNss}/etc/group etc/group
      cp -L ${fakeNss}/etc/nsswitch.conf etc/nsswitch.conf
      chmod 1777 tmp
      ln -s ../bin usr/bin
    '';

    config = {
      Cmd = [ "${pkgs.bashInteractive}/bin/bash" ];
      Env = [
        "BASH_ENV=${pkgs.nix}/etc/profile.d/nix-daemon.sh"
        "ENV=${pkgs.nix}/etc/profile.d/nix-daemon.sh"
        "HOME=/root"
        "NIX_CONFIG=experimental-features = nix-command flakes"
        "NIX_REMOTE=daemon"
        "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "PATH=${jobPath}"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "USER=root"
      ];
      Labels = {
        "org.opencontainers.image.description" = "Nix client for an isolated GitLab Runner store";
        "org.opencontainers.image.source" = "https://github.com/dsh0416/dotfiles";
      };
      User = "0:0";
      WorkingDir = "/builds";
    };
  };

  instanceType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        authenticationTokenConfigFile = lib.mkOption {
          type = lib.types.str;
          description = ''
            Runtime path containing CI_SERVER_URL and CI_SERVER_TOKEN. The
            file must remain outside the Nix store.
          '';
        };

        description = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Description registered with GitLab.";
        };

        stateDirectory = lib.mkOption {
          type = lib.types.strMatching "[a-z][a-z0-9-]{0,30}";
          default = "gitlab-nix-${name}";
          description = ''
            Directory name below /var/lib containing this trust domain's Nix
            store and mutable GitLab cache.
          '';
        };

        limit = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1;
          description = "Maximum number of concurrent jobs for this runner.";
        };

        requestConcurrency = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1;
          description = "Number of concurrent GitLab job requests.";
        };

        maxJobs = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1;
          description = "Maximum number of builds run by this Nix daemon.";
        };

        cores = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 0;
          description = "CPU cores per Nix build; zero lets Nix use all available cores.";
        };

        nrBuildUsers = lib.mkOption {
          type = lib.types.ints.positive;
          default = 8;
          description = "Dedicated sandbox build users allocated to this store.";
        };

        memoryMax = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "12G";
          description = "Optional systemd MemoryMax for the daemon and its builds.";
        };

        cpuQuota = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "400%";
          description = "Optional systemd CPUQuota for the daemon and its builds.";
        };

        substituters = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "https://cache.nixos.org/" ];
          description = "Binary caches fixed by the daemon operator.";
        };

        trustedPublicKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
          description = "Signing keys fixed by the daemon operator.";
        };

        allowedImages = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ jobImageName ];
          description = "Container images jobs may select.";
        };

        registrationFlags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional arguments passed to gitlab-runner register.";
        };

        environmentVariables = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = ''
            Non-secret variables injected into jobs. Values are part of the
            generated system configuration.
          '';
        };
      };
    }
  );

  enabledInstances = cfg.instances;

  instanceData = lib.mapAttrs (
    name: instance:
    let
      unitName = "dotfiles-gitlab-nix-${name}";
      storeRoot = "/var/lib/${instance.stateDirectory}/store-root";
      cacheDirectory = "/var/lib/${instance.stateDirectory}/cache";
      socketDirectory = "/run/${unitName}/daemon-socket";
      socketPath = "${socketDirectory}/socket";
      buildGroup = "nixbld-${name}";
      buildUsers = map (number: "${buildGroup}-${toString number}") (lib.range 1 instance.nrBuildUsers);
      nixConfig = pkgs.writeTextDir "nix.conf" ''
        allowed-users = *
        build-dir = ${storeRoot}/builds
        build-users-group = ${buildGroup}
        cores = ${toString instance.cores}
        experimental-features = nix-command flakes cgroups daemon-trust-override mounted-ssh-store
        keep-derivations = false
        keep-outputs = false
        max-jobs = ${toString instance.maxJobs}
        require-sigs = true
        sandbox = true
        sandbox-fallback = false
        store = local?root=${storeRoot}
        substituters = ${lib.concatStringsSep " " instance.substituters}
        trusted-public-keys = ${lib.concatStringsSep " " instance.trustedPublicKeys}
        trusted-users = root
        use-cgroups = true
      '';
    in
    {
      inherit
        buildGroup
        buildUsers
        cacheDirectory
        nixConfig
        socketDirectory
        socketPath
        storeRoot
        unitName
        ;
      inherit instance;
    }
  ) enabledInstances;

  mkBuildUsers =
    data:
    lib.listToAttrs (
      map (user: {
        name = user;
        value = {
          description = "Nix build user for ${data.instance.description}";
          isSystemUser = true;
          group = data.buildGroup;
          extraGroups = [ data.buildGroup ];
        };
      }) data.buildUsers
    );

  seedServices = lib.mapAttrs' (
    _: data:
    lib.nameValuePair "${data.unitName}-seed" {
      description = "Seed the isolated Nix store for ${data.instance.description}";
      before = [ "${data.unitName}.service" ];
      requiredBy = [ "${data.unitName}.service" ];
      path = [
        pkgs.coreutils
        pkgs.nix
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        install -d -m 0755 ${data.storeRoot} ${data.storeRoot}/builds ${data.cacheDirectory}
        nix copy \
          --no-check-sigs \
          --to 'local?root=${data.storeRoot}&require-sigs=false' \
          ${lib.escapeShellArgs jobPackages}
      '';
    }
  ) instanceData;

  daemonSockets = lib.mapAttrs' (
    _: data:
    lib.nameValuePair data.unitName {
      description = "Untrusted Nix daemon socket for ${data.instance.description}";
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = data.socketPath;
        SocketGroup = "podman";
        SocketMode = "0660";
        RemoveOnStop = true;
      };
    }
  ) instanceData;

  daemonServices = lib.mapAttrs' (
    _: data:
    lib.nameValuePair data.unitName {
      description = "Isolated Nix daemon for ${data.instance.description}";
      requires = [
        "${data.unitName}-seed.service"
        "${data.unitName}.socket"
      ];
      after = [
        "${data.unitName}-seed.service"
        "${data.unitName}.socket"
      ];
      environment = {
        NIX_CONF_DIR = data.nixConfig;
      };
      path = [ pkgs.nix ];
      serviceConfig = {
        Delegate = true;
        ExecStart = "${pkgs.nix}/bin/nix daemon --force-untrusted --process-ops";
        KillMode = "mixed";
        LimitNOFILE = 1048576;
        TasksMax = "infinity";
      }
      // lib.optionalAttrs (data.instance.memoryMax != null) {
        MemoryMax = data.instance.memoryMax;
      }
      // lib.optionalAttrs (data.instance.cpuQuota != null) {
        CPUQuota = data.instance.cpuQuota;
      };
    }
  ) instanceData;

  runnerServices = lib.mapAttrs' (
    name: data:
    lib.nameValuePair "nix-${name}" {
      inherit (data.instance)
        authenticationTokenConfigFile
        description
        limit
        requestConcurrency
        ;
      executor = "docker";
      dockerImage = jobImageName;
      dockerAllowedImages = data.instance.allowedImages;
      dockerAllowedServices = [ "localhost/dotfiles-disabled-service:*" ];
      dockerPullPolicy = "if-not-present";
      dockerPrivileged = false;
      dockerVolumes = [
        "${data.storeRoot}/nix/store:/nix/store:ro"
        "${data.socketDirectory}:/nix/var/nix/daemon-socket:ro"
        "${data.cacheDirectory}:/cache"
      ];
      environmentVariables = {
        FF_NETWORK_PER_BUILD = "1";
        NIX_REMOTE = "daemon";
      }
      // data.instance.environmentVariables;
      registrationFlags = [
        "--docker-allowed-pull-policies"
        "if-not-present"
        "--docker-services-limit"
        "0"
      ]
      ++ data.instance.registrationFlags;
    }
  ) instanceData;

in
{
  options.services.dotfiles-gitlab-nix-runner = {
    enable = lib.mkEnableOption "isolated, cache-persistent Nix GitLab runners";

    instances = lib.mkOption {
      type = lib.types.attrsOf instanceType;
      default = { };
      description = ''
        Runner trust domains. Every instance receives a separate Nix store,
        build-user pool, daemon socket, and mutable GitLab cache.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = enabledInstances != { };
        message = "services.dotfiles-gitlab-nix-runner.instances must not be empty";
      }
      {
        assertion = lib.all (name: builtins.match "[a-z][a-z0-9-]{0,15}" name != null) (
          lib.attrNames enabledInstances
        );
        message = "GitLab Nix runner instance names must be short lowercase identifiers";
      }
      {
        assertion =
          let
            directories = map (instance: instance.stateDirectory) (lib.attrValues enabledInstances);
          in
          builtins.length directories == builtins.length (lib.unique directories);
        message = "GitLab Nix runner instances must use distinct stateDirectory values";
      }
      {
        assertion = lib.all (instance: builtins.elem jobImageName instance.allowedImages) (
          lib.attrValues enabledInstances
        );
        message = "GitLab Nix runner allowedImages must include the module's job image";
      }
      {
        assertion = lib.all (instance: instance.nrBuildUsers >= instance.maxJobs) (
          lib.attrValues enabledInstances
        );
        message = "GitLab Nix runner nrBuildUsers must be at least maxJobs";
      }
    ];

    virtualisation.docker.enable = false;
    virtualisation.podman = {
      enable = true;
      dockerSocket.enable = true;
    };

    users.groups = lib.mapAttrs' (_: data: lib.nameValuePair data.buildGroup { }) instanceData;
    users.users = lib.mkMerge (map mkBuildUsers (lib.attrValues instanceData));

    systemd.tmpfiles.rules = lib.concatMap (data: [
      "d /var/lib/${data.instance.stateDirectory} 0755 root root - -"
      "d ${data.storeRoot} 0755 root root - -"
      "d ${data.storeRoot}/builds 0755 root root - -"
      "d ${data.cacheDirectory} 0755 root root - -"
      "d /run/${data.unitName} 0755 root podman - -"
      "d ${data.socketDirectory} 0750 root podman - -"
    ]) (lib.attrValues instanceData);

    systemd.sockets = daemonSockets;
    systemd.services =
      seedServices
      // daemonServices
      // {
        dotfiles-gitlab-nix-runner-image = {
          description = "Load the GitLab Nix runner job image";
          wantedBy = [ "multi-user.target" ];
          after = [ "podman.service" ];
          requires = [ "podman.service" ];
          path = [ pkgs.podman ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            podman load --input ${jobImage}
          '';
        };
        gitlab-runner = {
          # The upstream module normally reloads config in place. A reload
          # cannot apply newly added SupplementaryGroups, so switching from a
          # shell runner to Podman would leave the old process unable to open
          # the Podman socket until the next reboot.
          reloadIfChanged = lib.mkForce false;
          after = [
            "dotfiles-gitlab-nix-runner-image.service"
          ]
          ++ map (data: "${data.unitName}.service") (lib.attrValues instanceData);
          requires = [
            "dotfiles-gitlab-nix-runner-image.service"
          ]
          ++ map (data: "${data.unitName}.service") (lib.attrValues instanceData);
        };
      };

    services.gitlab-runner = {
      enable = true;
      gracefulTermination = lib.mkDefault true;
      gracefulTimeout = lib.mkDefault "10min";
      settings.concurrent = lib.mkDefault (
        lib.foldl' (total: instance: total + instance.limit) 0 (lib.attrValues enabledInstances)
      );
      services = runnerServices;
    };

    system.build.dotfilesGitlabNixRunnerJobImage = jobImage;
  };
}
