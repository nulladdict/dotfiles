{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      neovim-nightly-overlay,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          # Using Determinate Nix
          nix.enable = false;

          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = with pkgs; [
            nixfmt

            git
            git-lfs
            lazygit
            gh
            delta

            neovim-nightly-overlay.packages.${stdenv.hostPlatform.system}.default

            fzf
            ripgrep
            ast-grep
            fd
            jq
            zellij
            curl
            wget
            htop
            ffmpeg

            vault

            nodejs_24
            (yarn.override { withNode = false; })

            go

            uv
          ];

          npmGlobal = {
            enable = true;
            nodejs = pkgs.nodejs_24;
            packages = [
              "@github/copilot"
              "@openai/codex"
              "agent-browser"
            ];
          };

          homebrew = {
            enable = true;
            taps = [
              "daipeihust/tap"
              "nikitabobko/tap"
              "iina/homebrew-mpv-iina"
            ];
            brews = [
              "im-select"
            ];
            casks = [
              "brave-browser"
              "betterdisplay"
              "aerospace"
              "ghostty"
              "telegram"
              "mattermost"
              "zoom"
              "figma"
              "transmission"
              "iina"
              "opencode-desktop"
              "visual-studio-code"
            ];
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          fonts.packages = with pkgs; [
            iosevka-bin
          ];

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          system.primaryUser = "nulladdict";

          # Use apple watch for sudo
          security.pam.services.sudo_local.watchIdAuth = true;

          # Raise maxfiles limit
          launchd.daemons.maxfiles = {
            command = "/bin/launchctl limit maxfiles 65536 65536";
            serviceConfig = {
              Label = "limit.maxfiles";
              RunAtLoad = true;
            };
          };

          system.defaults = {
            dock.autohide = true;
            dock.show-recents = false;
            dock.persistent-apps = [
              "/Applications/Brave Browser.app"
              "/Applications/Ghostty.app"
              "/System/Applications/Mail.app"
              "/Applications/Telegram.app"
            ];
            loginwindow.GuestEnabled = false;
            NSGlobalDomain.ApplePressAndHoldEnabled = false;
            finder.FXPreferredViewStyle = "Nlsv";
          };

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mini
      darwinConfigurations."mini" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          ./modules/npm-global.nix
        ];
      };
    };
}
