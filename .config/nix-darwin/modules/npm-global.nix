{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.npmGlobal;
in
{
  options.npmGlobal = {
    enable = lib.mkEnableOption "declarative npm global package management";

    prefix = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${config.system.primaryUser}/.npm-global";
      description = "Directory prefix for global npm packages.";
    };

    nodejs = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nodejs;
      description = "Node.js package to use for npm.";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of npm packages to install globally.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.packages != [ ]) {
    system.activationScripts.postActivation.text = ''
      echo "Installing npm global packages..." >&2
      PATH="${lib.makeBinPath [ cfg.nodejs ]}:$PATH" \
      sudo --preserve-env=PATH --user=${lib.escapeShellArg config.system.primaryUser} --set-home ${pkgs.bash}/bin/bash -c '
        set -euo pipefail
        mkdir -p ${lib.escapeShellArg cfg.prefix}
        npm install -g --prefix ${lib.escapeShellArg cfg.prefix} ${lib.escapeShellArgs cfg.packages}
      '
    '';
  };
}
