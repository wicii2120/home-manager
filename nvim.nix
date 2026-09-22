{ pkgs, config, lib, ... }:

let
  # The deployed config tree as one store path, so a scratch copy can be taken
  # without walking the individual xdg.configFile symlinks.
  nvimConfig = pkgs.linkFarm "nvim-config" (
    lib.mapAttrsToList (name: entry: {
      name = lib.removePrefix "nvim/" name;
      path = entry.source;
    }) (
      lib.filterAttrs (name: entry: entry.enable && lib.hasPrefix "nvim/" name) config.xdg.configFile
    )
  );

  nvim-scratch = pkgs.writeShellApplication {
    name = "nvim-scratch";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.fish
    ];
    text = ''
      config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
      data_home="''${XDG_DATA_HOME:-$HOME/.local/share}"
      state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
      cache_home="''${XDG_CACHE_HOME:-$HOME/.cache}"

      # NVIM_APPNAME must name a directory inside the config home, so the scratch
      # tree sits next to the real config instead of in TMPDIR.
      config="$config_home/nvim-scratch.$(date +%Y%m%d-%H%M%S)"
      mkdir "$config"
      appname="$(basename "$config")"

      # NVIM_APPNAME redirects the data dir too; pointing it at the real one
      # reuses the installed plugins instead of cloning them again.
      mkdir -p "$data_home/nvim"
      ln -s "$data_home/nvim" "$data_home/$appname"

      trap 'rm -rf "$config" "$data_home/$appname" "$state_home/$appname" "$cache_home/$appname"' EXIT

      cp -RL ${nvimConfig}/. "$config/"
      chmod -R u+w "$config"

      # vim.pack keeps its lock next to the config rather than in the store;
      # copying it stops the scratch session from refetching every plugin.
      if [ -f "$config_home/nvim/nvim-pack-lock.json" ]; then
        cp "$config_home/nvim/nvim-pack-lock.json" "$config/"
      fi

      NVIM_APPNAME="$appname" fish
    '';
  };
in
{
  imports = [
    ./nvim/init.nix
    ./nvim/config.nix
    ./nvim/plugin.nix
    ./nvim/runtime.nix
    ./nvim/sioyek.nix
  ];

  home.shellAliases = {
      v = "nvim";
  };

  home.packages = [ nvim-scratch ];

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;

    # Binaries the config shells out to: the LSP servers enabled through
    # nvim-lspconfig, the formatters/linters used by conform.nvim, nvim-lint and
    # vimtex, the pickers, and git/tree-sitter for vim.pack and parser installs.
    # blink.cmp's build hook needs a Rust toolchain on PATH as well.
    extraPackages = with pkgs; [
      git

      lua-language-server
      bash-language-server
      fish-lsp
      yaml-language-server
      tombi
      ty
      tailwindcss-language-server
      vscode-langservers-extracted
      oxlint
      gopls
      vtsls
      vue-language-server
      docker-language-server
      nginx-language-server
      texlab
      nixd
      tex-fmt

      stylua
      ruff
      go
      shfmt
      nixfmt
      oxfmt
      eslint

      ripgrep
      fd
      yazi
      tree-sitter
      gcc

      # vimtex compiles through latexmk and needs the engines, biber/biblatex
      # and the packages the documents use; texliveFull covers scheme-full
      # without documentation (texliveFullWithDocs adds it).
      texliveFull
    ];
  };
}
