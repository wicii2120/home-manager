{  pkgs, ... }:

{
  imports = [
    ./qol/bat.nix
    ./qol/yt-dlp.nix
  ];

  programs.btop.enable = true;

  programs.fastfetch.enable = true;
}
