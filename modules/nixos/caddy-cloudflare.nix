{ pkgs, ... }:

let
  # withPlugins vendors Caddy together with the DNS plugin.
  vendorHashes = {
    "2.11.4" = "sha256-9tO1blZoDhfxBbHMYsJzEWejuAuzM36/56dBR68dVKk=";
    "2.11.7" = "sha256-weP1HzwGvPlLqiAViJus1GN74bps3bI179gomTCb6N4=";
  };
in
{
  services.caddy.package = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare@v0.2.3" ];
    hash = vendorHashes.${pkgs.caddy.version};
  };
}
