{ pkgs, ... }:

{
  imports = [
    ./nvim/init.nix
    ./nvim/config.nix
    ./nvim/plugin.nix
    ./nvim/runtime.nix
    ./nvim/sioyek.nix
  ];

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
