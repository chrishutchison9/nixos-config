{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{

  environment.sessionVariables =
    builtins.mapAttrs (_: toString) (
      lib.removeAttrs config.home-manager.users.balsoft.home.sessionVariables [ "GIO_EXTRA_MODULES" ]
    )
    // rec {
      LESS = "MR";
      LESSCHARSET = "utf-8";
      LESSHISTFILE = "~/.local/share/lesshist";

      CARGO_HOME = "${config.home-manager.users.balsoft.xdg.dataHome}/cargo";

      SYSTEMD_LESS = LESS;
    };

  home-manager.users.balsoft = {
    news.display = "silent";

    systemd.user.startServices = true;

    home.stateVersion = lib.mkDefault "20.09";
    home.preferXdgDirectories = true;
  };

  home-manager.useGlobalPkgs = true;

  persist.cache.directories = [
    "/home/balsoft/.cache"
    "/home/balsoft/.local/share/cargo"
    "/var/cache"
  ];

  persist.state.directories = [
    "/var/lib/nixos"
    "/var/lib/systemd"
  ];

  system.stateVersion = lib.mkDefault "18.03";

  systemd.services.systemd-timesyncd.wantedBy = [ "multi-user.target" ];

  systemd.timers.systemd-timesyncd = {
    timerConfig.OnCalendar = "hourly";
  };

  services.avahi.enable = true;

  environment.systemPackages = [ pkgs.ntfs3g ];
}
