{ pkgs, ... }:

{

  imports = [
    ./essential/git.nix
    ./essential/shell.nix
    ./essential/editorconfig.nix
  ];

  programs.go = {
    enable = true;
  };

  programs.jq.enable = true;
  programs.less.enable = true;

  programs.pnpm = {
    enable = true;
    package = pkgs.pnpm_12;
  };
  programs.bun.enable = true;

  programs.fd.enable = true;
  programs.ripgrep.enable = true;

  programs.eza = {
    enable = true;
    icons = "auto";
  };
}
