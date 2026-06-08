{
  pkgs,
  config,
  lib,
  ...
}:
{
  services.nginx = {
    enable = true;
    appendHttpConfig = "charset utf-8;";
    virtualHosts =
      let
        default = {
          forceSSL = true;
          enableACME = true;
        };
      in
      {
        "balsoft.eu" = {
          default = true;
          locations."/" = {
            root = "/var/lib/balsoft.eu";
            index = "index.txt";
          };
          locations."/.well-known/matrix" = {
            proxyPass = "http://localhost:13748";
          };
          locations."/_matrix" = {
            proxyPass = "http://localhost:13748";
          };
          locations."/_conduwuit" = {
            proxyPass = "http://localhost:13748";
          };
          locations."/_continuwuity" = {
            proxyPass = "http://localhost:13748";
          };
          enableACME = true;
          forceSSL = true;
        };
        "matrix.balsoft.eu" = {
          locations."/" = {
            proxyPass = "http://localhost:13748";
          };
        }
        // default;
        "share.balsoft.eu" = {
          locations."/" = {
            root = "/var/lib/share";
          };
        }
        // default;
        "things.balsoft.eu" = {
          locations."/" = {
            root = "/nix/var/nix/profiles/per-user/nginx/random-things/www";
          };
        }
        // default;
      };
  };
  security.acme.defaults.email = "balsoft@balsoft.eu";
  security.acme.acceptTerms = true;
}
