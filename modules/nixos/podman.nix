{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings = {
        dns_enabled = true;
        ipv6_enabled = true;
      };
    };

    oci-containers.backend = "podman";
  };

  # Do not enable virtualisation.podman.dockerSocket by default. Membership in
  # its socket group grants root-equivalent access, like the Docker group.
}
