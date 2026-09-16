{ ... }:

{
  # vim.pack installs the plugins this config declares; home-manager only
  # deploys the config tree and the binaries it shells out to.
  programs.neovim.initLua = ''
  require('vim._core.ui2').enable({ enable = true })

  vim.filetype.add({
      filename = {
          ['compose.yaml']        = 'yaml.docker-compose',
          ['compose.yml']         = 'yaml.docker-compose',
          ['docker-compose.yaml'] = 'yaml.docker-compose',
          ['docker-compose.yml']  = 'yaml.docker-compose',
          ['.gitlab-ci.yml']      = 'yaml.gitlab',
      }
  })

  require('config.options')
  require('config.autocmds')
  require('config.keymaps')
  '';
}
