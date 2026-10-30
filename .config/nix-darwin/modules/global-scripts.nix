{
  config,
  lib,
  pkgs,
  ...
}:
{
  system.activationScripts.postActivation.text = ''
    echo "Installing global scripts..." >&2
    /usr/bin/sudo -H -u ${lib.escapeShellArg config.system.primaryUser} ${pkgs.bash}/bin/bash -c '
      set -euo pipefail
      export PATH="${lib.makeBinPath [ pkgs.nodejs_26 ]}:$PATH"
      cd "$HOME"
      export PATH="$HOME/.pi/agent/bin:$PATH"
      ${pkgs.curl}/bin/curl -fsSL https://plannotator.ai/install.sh | ${pkgs.bash}/bin/bash
      ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | ${pkgs.bash}/bin/bash
      ${pkgs.curl}/bin/curl -fsSL https://opencode.ai/v2/install | ${pkgs.bash}/bin/bash -s -- --no-modify-path
      if command -v pi >/dev/null 2>&1; then
        pi update --all
      else
        ${pkgs.curl}/bin/curl -fsSL https://pi.dev/install.sh | ${pkgs.bash}/bin/bash
      fi
    '
  '';
}
