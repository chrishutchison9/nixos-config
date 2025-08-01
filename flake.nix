{
  description =
    "A collection of crap, hacks and copy-paste to make my localhosts boot";

  nixConfig.substituters = [ "https://cache.nixos.org" ];

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # For NUR
    nixpkgs-old = {
      url = "github:nixos/nixpkgs/nixos-19.09";
      flake = false;
    };
    # For aerc
    nixpkgs-24-05.url = "github:nixos/nixpkgs/nixos-24.05";

    lambda-launcher.url = "github:balsoft/lambda-launcher";
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    NUR = {
      url = "github:nix-community/NUR";
      flake = false;
    };
    base16-black-metal-scheme = {
      url = "github:metalelf0/base16-black-metal-scheme";
      flake = false;
    };
    home-manager.url = "github:rycee/home-manager";
    materia-theme = {
      url = "github:nana-4/materia-theme";
      flake = false;
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      flake = false;
    };
    nixpkgs-wayland = {
      url = "github:colemickens/nixpkgs-wayland";
      flake = false;
    };
    nixos-fhs-compat.url = "github:balsoft/nixos-fhs-compat";
    simple-osd-daemons.url = "github:balsoft/simple-osd-daemons";
    impermanence.url = "github:nix-community/impermanence";

    rycee = {
      url = "gitlab:rycee/nur-expressions";
      flake = false;
    };

    nix-direnv = { url = "github:nix-community/nix-direnv"; };

    flake-registry = {
      url = "github:nixos/flake-registry";
      flake = false;
    };

    remapper.url = "github:balsoft/remapper";

    helix.url = "github:helix-editor/helix";

    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { nixpkgs, self, nix, deploy-rs, ... }@inputs:
    let
      findModules = dir:
        builtins.concatLists (builtins.attrValues (builtins.mapAttrs
          (name: type:
            if type == "regular" then [{
              name = builtins.elemAt (builtins.match "(.*)\\.nix" name) 0;
              value = dir + "/${name}";
            }] else if (builtins.readDir (dir + "/${name}"))
            ? "default.nix" then [{
              inherit name;
              value = dir + "/${name}";
            }] else
              findModules (dir + "/${name}")) (builtins.readDir dir)));
      pkgsFor = system:
        import inputs.nixpkgs {
          overlays = [ self.overlay ];
          localSystem = { inherit system; };
          config = {
            android_sdk.accept_license = true;
            permittedInsecurePackages = [ "openssl-1.1.1v" "olm-3.2.16" ];
            allowUnfreePredicate = (pkg: pkg.pname or null == "firmware-imx");
            allowlistedLicenses = with inputs.nixpkgs.lib.licenses; [ epson ];
          };
        };
    in {
      nixosModules = builtins.listToAttrs (findModules ./modules);

      nixosProfiles = builtins.listToAttrs (findModules ./profiles);

      nixosRoles = import ./roles;

      nixosConfigurations = with nixpkgs.lib;
        let
          hosts = builtins.attrNames (builtins.readDir ./machines);

          mkHost = name:
            let
              system = builtins.readFile (./machines + "/${name}/system");
              pkgs = pkgsFor system;
            in nixosSystem {
              inherit system;
              modules = __attrValues self.nixosModules ++ [
                inputs.home-manager.nixosModules.home-manager

                {
                  disabledModules =
                    [ "services/x11/desktop-managers/plasma5.nix" ];
                }

                (import (./machines + "/${name}"))
                { nixpkgs.pkgs = pkgs; }
                { device = name; }
              ];
              specialArgs = { inherit inputs; };
            };
        in genAttrs hosts mkHost;

      legacyPackages.x86_64-linux = pkgsFor "x86_64-linux";

      apps.x86_64-linux.default = deploy-rs.apps.x86_64-linux.default;

      overlay = import ./overlay.nix inputs;

      lib = import ./lib.nix nixpkgs.lib;

      devShell.x86_64-linux = with nixpkgs.legacyPackages.x86_64-linux;
        mkShell {
          buildInputs = [
            nix.packages.x86_64-linux.default
            deploy-rs.packages.x86_64-linux.default
            nixfmt-rfc-style
            nil
            (writeShellScriptBin "link-file" ''
              source="$(nix build --print-out-paths "$1.source" || nix eval --raw "$1.source")"
              target="$(nix eval --raw "$1.target")"
              ln -fs "$source" "$HOME/$target"
            '')
            (writeShellScriptBin "link-hm-file" ''
              link-file ".#nixosConfigurations.$(hostname).config.home-manager.users.$(whoami).$1"
            '')
            (writeShellScriptBin "link-config-file" ''
              link-hm-file "xdg.configFile.\"$1\""
            '')
            (writeShellScriptBin "link-data-file" ''
              link-hm-file "xdg.dataFile.\"$1\""
            '')
            (writeShellScriptBin "link-home-file" ''
              link-hm-file "home.file.\"$1\""
            '')
          ];
        };

      deploy = {
        user = "root";
        nodes = (builtins.mapAttrs (name: machine:
          let activateable = name == "T420-Laptop" || name == "RasPi-Server";
          in {
            hostname = machine.config.networking.hostName;
            profiles.system = {
              user = if activateable then "root" else "balsoft";
              path = with deploy-rs.lib.${machine.pkgs.system}.activate;
                if activateable then
                  nixos machine
                else
                  noop machine.config.system.build.toplevel;
            };
          }) self.nixosConfigurations);
      };
    };
}
