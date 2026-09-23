{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ast-grep
    bash
    cloc
    croc
    firecrawl-cli
    ffmpeg
    fnm
    fswatch
    imagemagick
    kubectl
    lazyrsync
    mcat
    pandoc
    pkgconf
    postgresql
    rsync
    socat
    sqlite
    tmux
    uv
    yq-go
    maple-mono.NF-CN
    source-han-sans
    source-han-serif
  ];

  imports = [
    ./essential/git.nix
    ./essential/shell.nix
    ./essential/editorconfig.nix
    ./essential/ghostty.nix
  ];

  home.shellAliases = {
    e = "eza";
    ea = "eza -a";
    el = "eza -l";
  };

  programs.go = {
    enable = true;
  };

  programs.jq.enable = true;
  programs.less.enable = true;

  programs.bun.enable = true;

  programs.fd.enable = true;
  programs.ripgrep.enable = true;

  programs.eza = {
    enable = true;
    icons = "auto";
  };
}
