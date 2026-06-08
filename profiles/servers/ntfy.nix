{ config, ... }:
{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.balsoft.eu";
      listen-http = "localhost:8111";
      behind-proxy = true;
      enable-login = true;
      auth-default-access = "read-write";
    };
  };

  secrets.ntfy_password = { owner = "nginx:nginx"; };

  services.nginx.virtualHosts."ntfy.balsoft.eu" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:8111";
      proxyWebsockets = true;
      # basicAuthFile = config.secrets.ntfy_password.decrypted;
    };
  };
}
