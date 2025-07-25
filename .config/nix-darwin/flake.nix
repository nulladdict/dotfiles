{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
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
            nixfmt-rfc-style

            git
            git-lfs
            lazygit
            gh

            neovim
            vscode

            fzf
            ripgrep
            fd
            jq
            tmux
            curl
            wget
            htop

            nodejs_latest
            (yarn.override { withNode = false; })
          ];

          homebrew = {
            enable = true;
            taps = [
              "daipeihust/tap"
              "nikitabobko/tap"
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
              "figma"
            ];
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          system.primaryUser = "nulladdict";
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
          };

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#mini
      darwinConfigurations."mini" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
    };
}
