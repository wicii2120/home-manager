{ config, ... }:

let
  # vimtex passes its own callback when it launches the viewer, but instances the
  # user opens directly need one too; either way it has to be the wrapped
  # neovim, whose runtimepath carries vimtex.
  nvim = "${config.programs.neovim.finalPackage}/bin/nvim";
in
{
  programs.sioyek = {
    enable = true;

    config = {
      # Sioyek substitutes %1 (file), %2 (line) and %3 (column), then splits the
      # result with QProcess::splitCommand, which honours the double quotes.
      inverse_search_command = ''${nvim} --headless -c "VimtexInverseSearch %2:%3 '%1'"'';
    };

    # SyncTeX mode is what makes a click in the PDF perform the inverse search,
    # and it is left on its default key (<f4>) rather than in startup_commands,
    # because that mode also disables click-based marks/overview for other PDFs.
  };
}
