{ pkgs, lib, config, ... }:
{
  home.packages = with pkgs; [
    lazyrsync
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man! -";
    HTTP_PROXY = "http://127.0.0.1:6152";
    HTTPS_PROXY = config.home.sessionVariables.HTTP_PROXY;
    NODE_USE_ENV_PROXY=1;
    MCAT_THEME="catppuccin";
    # Tools that only read the lowercase names (curl) lose these when the
    # terminal no longer starts from a login zsh.
    http_proxy = config.home.sessionVariables.HTTP_PROXY;
    https_proxy = config.home.sessionVariables.HTTPS_PROXY;
    no_proxy = "localhost,127.0.0.1,::1";
  };

  home.sessionPath = [
    "/usr/local/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/Library/pnpm/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];

  home.shellAliases = {
      pn = "pnpm";
      px = "pnpx";
      lzr = "lazyrsync";
      py = "python3";
      ev = "envchain";
  };

  programs.fish = {
    enable = true;
    # Fish resolves NIX_PROFILES before it reads any user config, so nix's
    # profile snippet has to run in pre-init or the profile completions and
    # vendor dirs never load.
    package = pkgs.fish.override {
      fishEnvPreInit = "source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish";
    };
    interactiveShellInit = ''
      if type -q fnm
        fnm env --use-on-cd --shell fish | source
      end

      if test -n "$GHOSTTY_RESOURCES_DIR" 
        builtin source "$GHOSTTY_RESOURCES_DIR"/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish
      end
    '';
    preferAbbrs = true;
  };

  # Homebrew has to be detected at shell start: pure flake evaluation cannot
  # see /opt/homebrew, so an eval-time check would never fire.
  xdg.configFile."fish/conf.d/homebrew.fish" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    text = ''
      if test -x /opt/homebrew/bin/brew
        /opt/homebrew/bin/brew shellenv fish | source
      else if test -x /usr/local/bin/brew
        /usr/local/bin/brew shellenv fish | source
      end
    '';
  };

  programs.fzf.enable = true;
  programs.zoxide.enable = true;

  programs.starship = {
    enable = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      command_timeout = 3000;

      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$localip"
        "$shlvl"
        "$singularity"
        "$kubernetes"
        "$directory"
        "$vcsh"
        "$fossil_branch"
        "$fossil_metrics"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
        "$hg_branch"
        "$hg_state"
        "$pijul_channel"
        "$docker_context"
        "$package"
        "$c"
        "$cmake"
        "$cobol"
        "$daml"
        "$dart"
        "$deno"
        "$dotnet"
        "$elixir"
        "$elm"
        "$erlang"
        "$fennel"
        "$fortran"
        "$gleam"
        "$golang"
        "$guix_shell"
        "$haskell"
        "$haxe"
        "$helm"
        "$java"
        "$julia"
        "$kotlin"
        "$gradle"
        "$lua"
        "$nim"
        "$nodejs"
        "$ocaml"
        "$opa"
        "$perl"
        "$php"
        "$pulumi"
        "$purescript"
        "$python"
        "$quarto"
        "$raku"
        "$rlang"
        "$red"
        "$ruby"
        "$rust"
        "$scala"
        "$solidity"
        "$swift"
        "$terraform"
        "$typst"
        "$vlang"
        "$vagrant"
        "$zig"
        "$buf"
        "$nix_shell"
        "$conda"
        "$meson"
        "$spack"
        "$memory_usage"
        "$aws"
        "$gcloud"
        "$openstack"
        "$azure"
        "$nats"
        "$direnv"
        "$env_var"
        "$mise"
        "$crystal"
        "$custom"
        "$sudo"
        "$cmd_duration"
        "$fill"
        "$time"
        "$line_break"
        "$jobs"
        "$battery"
        "$status"
        "$os"
        "$container"
        "$netns"
        "$shell"
        "$character"
      ];

      fill.symbol = "-";

      time = {
        disabled = false;
        time_format = "%T";
        format = " at [$time]($style) ";
      };

      character.error_symbol = "[✘](bold red)";

      git_branch.symbol = " ";

      git_status = {
        deleted = "D";
        modified = "M";
        renamed = "R";
        conflicted = " ";
        untracked = "U";
      };

      nodejs = {
        symbol = " ";
        detect_extensions = [ ];
      };

      python.symbol = " ";
      swift.symbol = "󰛥 ";
      golang.symbol = " ";
      rust.symbol = " ";
      cmake.symbol = " ";
      deno.symbol = " ";
      bun.symbol = " ";
      conda.symbol = " ";
      cpp.symbol = " ";
      c.symbol = " ";
      elixir.symbol = " ";
      lua.symbol = " ";
      kubernetes.symbol = " ";
      package.symbol = " ";
      zig.symbol = " ";
      container.symbol = " ";
      docker_context.symbol = " ";
    };
  };

  programs.yazi = {
    enable = true;
    package = pkgs.yazi-unwrapped;

    # catppuccin-mocha is not packaged in nixpkgs, so it is linked out of the
    # upstream flavor repo (pinned, since Nix has no updater for it).
    flavors.catppuccin-mocha = "${
      pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "flavors";
        rev = "20b47bfd78880c2674899597fd26bc01b21ff48c";
        hash = "sha256-NGnfrQdsnQITKCZ0oh6DCxeCR2ozJoPAZetsi3ghHAI=";
      }
    }/catppuccin-mocha.yazi";

    theme.flavor.dark = "catppuccin-mocha";
    theme.flavor.light = "catppuccin-mocha";

    plugins = with pkgs.yaziPlugins; {
      full-border = {
        package = full-border;
        setup = true;
      };
      mactag = {
        package = mactag;
        setup = true;
        settings = {
          keys = {
            r = "Red";
            o = "Orange";
            y = "Yellow";
            g = "Green";
            b = "Blue";
            p = "Purple";
          };
          # Colors used to display tags
          colors = {
            Red = "#ee7b70";
            Orange = "#f5bd5c";
            Yellow = "#fbe764";
            Green = "#91fc87";
            Blue = "#5fa3f8";
            Purple = "#cb88f8";
          };
          # Order of the color circle showing in the line mode
          order = 500;
        };
      };
      git = {
        package = git;
        setup = true;
      };
      zoom = zoom;
      piper = piper;
      diff = diff;
      chmod = chmod;
      mount = mount;
      smart-paste = smart-paste;
      sshfs = sshfs;
    };
  };

  programs.direnv = {
    enable = true;
    enableGitIntegration = true;
  };
}
