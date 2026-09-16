{ config, ... }:

let
  # The inverse-search callback runs in a fresh headless neovim, so it must be
  # the wrapped build that carries vimtex on its runtimepath.
  nvim = "${config.programs.neovim.finalPackage}/bin/nvim";
in
{
  xdg.configFile."nvim/plugin/0-hooks-blink-cmp.lua".text = ''
  require('vim-pack-hooks').build('blink.cmp', function ()
      vim.cmd.packadd('blink.lib')
      vim.cmd.packadd('blink.cmp')
      require('blink.cmp').build():pwait()
  end)
  '';

  xdg.configFile."nvim/plugin/blink-cmp.lua".text = ''
  vim.pack.add({
      'https://github.com/saghen/blink.compat',
      'https://github.com/saghen/blink.lib',
      'https://github.com/bydlw98/blink-cmp-env',
      'https://github.com/saghen/blink.cmp',
  })

  local cmp = require('blink.cmp')
  cmp.setup({
      completion = {
          -- use mini.icons for menu icons
          menu = {
              draw = {
                  components = {
                      kind_icon = {
                          text = function(ctx)
                              local kind_icon, _, _ =
                                  require('mini.icons').get('lsp', ctx.kind)
                              return kind_icon
                          end,
                          -- (optional) use highlights from mini.icons
                          highlight = function(ctx)
                              local _, hl, _ =
                                  require('mini.icons').get('lsp', ctx.kind)
                              return hl
                          end,
                      },
                      kind = {
                          -- (optional) use highlights from mini.icons
                          highlight = function(ctx)
                              local _, hl, _ =
                                  require('mini.icons').get('lsp', ctx.kind)
                              return hl
                          end,
                      },
                  },
              },
          },
          trigger = {
              show_on_keyword = true,
          },
          accept = {
              auto_brackets = {
                  enabled = false,
              },
          },
          list = {
              selection = {
                  preselect = false,
                  auto_insert = true,
              },
          },
      },
      signature = {
          enabled = true,
      },
      snippets = {
          preset = 'luasnip',
      },
      sources = {
          default = { 'lsp', 'snippets', 'buffer', 'env', 'path' },

          per_filetype = {
              sql = { 'dadbod', 'snippets', 'buffer' },
              lua = { inherit_defaults = true, 'lazydev' },
          },

          providers = {
              lsp = {
                  fallbacks = {},
                  async = false,
                  timeout_ms = 2000,
              },

              env = {
                  name = 'Env',
                  module = 'blink-cmp-env',
                  --- @type blink-cmp-env.Options
                  opts = {
                      item_kind = require('blink.cmp.types').CompletionItemKind.Variable,
                      show_braces = false,
                      show_documentation_window = true,
                  },
              },
              dadbod = {
                  name = 'Dadbod',
                  module = 'vim_dadbod_completion.blink',
              },
              lazydev = {
                  name = 'LazyDev',
                  module = 'lazydev.integrations.blink',
                  -- make lazydev completions top priority (see `:h blink.cmp`)
                  score_offset = 100,
              },
          },
      },
  })

  vim.lsp.config('*', {
      capabilities = cmp.get_lsp_capabilities(),
  })
  '';

  xdg.configFile."nvim/plugin/catppuccin.lua".text = ''
  vim.pack.add({
      {
          src = 'https://github.com/catppuccin/nvim',
          name = 'catppuccin',
      },
  })

  require('catppuccin').setup({
      flavour = 'mocha',
      dim_inactive = {
          enabled = true,
      },
      term_colors = true,
      background = {
          light = 'mocha',
          dark = 'mocha',
      },
      lsp_styles = {
          underlines = {
              errors = { 'undercurl' },
              hints = { 'undercurl' },
              warnings = { 'undercurl' },
              information = { 'undercurl' },
          },
      },
      auto_integrations = true,
      custom_highlights = function(colors)
          return {
              ['@lsp.type.component.vue'] = { fg = colors.sapphire },
              ['@tag.tsx'] = { fg = colors.sapphire },
              WinSeparator = { fg = colors.overlay0 },
              SnacksIndentScope = { fg = colors.lavender },
          }
      end,
  })

  -- Load immediately (not at VimEnter) so plugins like lualine resolve their theme
  -- against an already-loaded flavour, and OS theme changes propagate from startup.
  vim.cmd.colorscheme('catppuccin-nvim')
  '';

  xdg.configFile."nvim/plugin/conform.lua".text = ''
  vim.pack.add({
      'https://github.com/stevearc/conform.nvim',
  })

  local oxfmt_ft = {
      'typescript',
      'javascript',
      'typescriptreact',
      'javascriptreact',
      'css',
      'html',
      'vue',
      'json',
      'jsonc',
      'json5',
      'yaml',
      'toml',
  }
  local formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'ruff' },
      go = { 'gofmt' },
      sh = { 'shfmt' },
      nginx = { 'nginxfmt' },
      nix = { 'nixfmt' },
  }

  for _, ft in ipairs(oxfmt_ft) do
      formatters_by_ft[ft] = { 'oxfmt' }
  end

  require('conform').setup({
      formatters_by_ft = formatters_by_ft,
  })

  vim.keymap.set({ 'n', 'x' }, '<leader>cF', function()
      require('conform').format({ formatters = { 'injected' } })
  end, { desc = 'Format Injected Langs' })
  vim.keymap.set({ 'n', 'x' }, '<leader>cf', function()
      require('conform').format()
  end, { desc = 'Format Buffer' })
  '';

  xdg.configFile."nvim/plugin/copy-location.lua".text = ''
  if _G.MY == nil then
      _G.MY = {}
  end

  local function copy_location(start_pos, end_pos, selection_type, absolute)
      -- Positions are { line, 0-based byte column }.
      if
          start_pos[1] > end_pos[1]
          or (start_pos[1] == end_pos[1] and start_pos[2] > end_pos[2])
      then
          start_pos, end_pos = end_pos, start_pos
      end

      local path = vim.api.nvim_buf_get_name(0)
      if path == ''' then
          path = '[No Name]'
      elseif not absolute then
          path = vim.fn.fnamemodify(path, ':.') -- relative to cwd
      end

      local location

      if selection_type == 'line' then
          location = ('%s:%d-%d'):format(path, start_pos[1], end_pos[1])
      else
          location = ('%s:%d:%d-%d:%d'):format(
              path,
              start_pos[1],
              start_pos[2] + 1,
              end_pos[1],
              end_pos[2] + 1
          )
      end

      vim.fn.setreg('+', location)
      vim.notify('Copied: ' .. location)
  end

  _G.MY.copy_location_operator = function(type)
      copy_location(
          vim.api.nvim_buf_get_mark(0, '['),
          vim.api.nvim_buf_get_mark(0, ']'),
          type,
          false
      )
  end

  _G.MY.copy_location_operator_absolute = function(type)
      copy_location(
          vim.api.nvim_buf_get_mark(0, '['),
          vim.api.nvim_buf_get_mark(0, ']'),
          type,
          true
      )
  end

  vim.keymap.set('n', '<leader>y', function()
      vim.go.operatorfunc = 'v:lua.MY.copy_location_operator'
      return 'g@'
  end, {
      expr = true,
      desc = 'Copy source range (relative)',
  })

  vim.keymap.set('n', '<leader>yy', function()
      vim.go.operatorfunc = 'v:lua.MY.copy_location_operator'
      return 'g@_'
  end, {
      expr = true,
      desc = 'Copy source range (relative)',
  })

  vim.keymap.set('n', '<leader>Y', function()
      vim.go.operatorfunc = 'v:lua.MY.copy_location_operator_absolute'
      return 'g@'
  end, {
      expr = true,
      desc = 'Copy source range (absolute)',
  })

  vim.keymap.set('n', '<leader>YY', function()
      vim.go.operatorfunc = 'v:lua.MY.copy_location_operator_absolute'
      return 'g@_'
  end, {
      expr = true,
      desc = 'Copy source range (absolute)',
  })

  local function visual_copy_location(absolute)
      local mode = vim.fn.mode()

      -- getpos() columns are 1-based, unlike nvim_buf_get_mark().
      local visual_start = vim.fn.getpos('v')
      local cursor = vim.fn.getpos('.')

      local start_pos = { visual_start[2], visual_start[3] - 1 }
      local end_pos = { cursor[2], cursor[3] - 1 }

      local selection_type = mode == 'V' and 'line'
          or mode == '\22' and 'block'
          or 'char'

      copy_location(start_pos, end_pos, selection_type, absolute)

      return '<esc>'
  end

  vim.keymap.set('x', '<leader>y', function()
      return visual_copy_location(false)
  end, {
      expr = true,
      desc = 'Copy selected source range (relative)',
  })

  vim.keymap.set('x', '<leader>Y', function()
      return visual_copy_location(true)
  end, {
      expr = true,
      desc = 'Copy selected source range (absolute)',
  })
  '';

  xdg.configFile."nvim/plugin/dadbod.lua".text = ''
  vim.pack.add({
      'https://github.com/tpope/vim-dadbod',
      'https://github.com/kristijanhusak/vim-dadbod-completion',
      'https://github.com/kristijanhusak/vim-dadbod-ui',
  })

  vim.g.db_ui_use_nerd_fonts = 1

  vim.keymap.set('n', '<leader>uD', '<cmd>DBUIToggle<cr>', { desc = 'Dadbod UI' })
  '';

  xdg.configFile."nvim/plugin/dotenv.lua".text = ''
  vim.pack.add({ 'https://github.com/tpope/vim-dotenv' })
  '';

  xdg.configFile."nvim/plugin/flash.lua".text = ''
  vim.pack.add({ 'https://github.com/folke/flash.nvim' })

  require('flash').setup({
      search = {
          incremental = false,
      },
      label = {
          uppercase = false,
      },
  })

  vim.keymap.set({ 'n', 'x', 'o' }, 's', function()
      require('flash').jump()
  end, { desc = 'Flash' })
  vim.keymap.set({ 'n', 'x', 'o' }, 'S', function()
      require('flash').treesitter()
  end, { desc = 'Flash Treesitter' })
  vim.keymap.set('o', 'r', function()
      require('flash').remote()
  end, { desc = 'Remote Flash' })
  vim.keymap.set({ 'o', 'x' }, 'R', function()
      require('flash').treesitter_search()
  end, { desc = 'Treesitter Search' })
  vim.keymap.set('c', '<c-s>', function()
      require('flash').toggle()
  end, { desc = 'Toggle Flash Search' })
  '';

  xdg.configFile."nvim/plugin/fugitive.lua".text = ''
  vim.pack.add({ 'https://github.com/tpope/vim-fugitive' })
  '';

  xdg.configFile."nvim/plugin/grug-far.lua".text = ''
  vim.pack.add({ 'https://github.com/MagicDuck/grug-far.nvim' })

  require('grug-far').setup()

  vim.keymap.set({ 'n', 'x' }, '<leader>sr', function()
      local grug = require('grug-far')
      local ext = vim.bo.buftype == ''' and vim.fn.expand('%:e')
      grug.open({
          transient = true,
          prefills = {
              filesFilter = ext and ext ~= ''' and '*.' .. ext or nil,
          },
      })
  end, { desc = 'Search and Replace' })
  '';

  xdg.configFile."nvim/plugin/lazydev.lua".text = ''
  vim.pack.add({ 'https://github.com/folke/lazydev.nvim' })

  require('lazydev').setup({
      library = {
          -- See the configuration section for more details
          -- Load luvit types when the `vim.uv` word is found
          { path = ${"'"}''${3rd}/luv/library', words = { 'vim%.uv' } },
          { path = 'snacks.nvim', words = { 'Snacks' } },
      },
  })
  '';

  xdg.configFile."nvim/plugin/loadview.lua".text = ''
  -- vim.opt.viewoptions:remove("options")  -- optional: skip restoring options
  local group = vim.api.nvim_create_augroup("remember_views", { clear = true })
  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = group,
    pattern = "*",
    callback = function() vim.cmd("silent! mkview") end,
  })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    pattern = "*",
    callback = function() vim.cmd("silent! loadview") end,
  })
  '';

  xdg.configFile."nvim/plugin/lsp.lua".text = ''
  vim.pack.add({ 'https://github.com/neovim/nvim-lspconfig' })
  vim.lsp.inlay_hint.enable(false)

  vim.diagnostic.config({
      signs = {
          text = {
              [vim.diagnostic.severity.ERROR] = '',
              [vim.diagnostic.severity.WARN] = '',
              [vim.diagnostic.severity.INFO] = '',
              [vim.diagnostic.severity.HINT] = '',
          },
      },
      virtual_text = {
          spacing = 4,
          source = 'if_many',
          prefix = '',
          -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
          -- prefix = "icons",
      },
      severity_sort = true,
  })

  local enabled_lsps = {
      'lua_ls',
      'bashls',
      'fish_lsp',
      'yamlls',
      'tombi',
      'ty',
      'tailwindcss',
      'cssls',
      'jsonls',
      'oxlint',
      'gopls',
      'vtsls',
      'vue_ls',
      'docker_language_server',
      'nginx_language_server',
      'texlab',
      'nixd'
  }

  for _, lsp in ipairs(enabled_lsps) do
      vim.lsp.enable(lsp)
  end
  '';

  xdg.configFile."nvim/plugin/lualine.lua".text = ''
  vim.pack.add({ 'https://github.com/nvim-lualine/lualine.nvim' })

  local get_recording_state = function()
      local reg = vim.fn.reg_recording()
      if reg ~= ''' then
          return 'recording @' .. reg
      end
      return nil
  end

  require('lualine').setup({
      options = {
          icons_enabled = true,
          theme = 'catppuccin-nvim',
          section_separators = { left = ''', right = ''' },
          component_separators = { left = ''', right = ''' },
          disabled_filetypes = {
              statusline = {},
              winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          always_show_tabline = false,
          globalstatus = true,
          refresh = {
              statusline = 150,
              tabline = 1000,
              winbar = 1000,
              refresh_time = 16, -- ~60fps
              events = {
                  'WinEnter',
                  'BufEnter',
                  'BufWritePost',
                  'SessionLoadPost',
                  'FileChangedShellPost',
                  'VimResized',
                  'Filetype',
                  'CursorMoved',
                  'CursorMovedI',
                  'ModeChanged',
              },
          },
      },
      sections = {
          lualine_a = { 'mode' },
          lualine_b = {
              { 'branch', separator = '|' },
              {
                  'filename',
                  newfile_status = true,
                  path = 4,
              },
              'diagnostics',
          },
          lualine_x = {
              {
                  get_recording_state,
                  cond = function()
                      return get_recording_state() ~= nil
                  end,
              },
              -- { noice.api.status.search.get, cond = noice.api.status.search.has },
              'filetype',
              'fileformat',
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
      },
      inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
      },
      tabline = {
          lualine_a = {
              {
                  'tabs',
                  mode = 2,
                  symbols = {
                      modified = ' ',
                  },
                  use_mode_colors = true,
              },
          },
      },
      winbar = {},
      inactive_winbar = {},
      extensions = { 'quickfix', 'fugitive', 'man' },
  })
  '';

  xdg.configFile."nvim/plugin/luasnip.lua".text = ''
  vim.pack.add({ 'https://github.com/L3MON4D3/LuaSnip' })
  local ls = require('luasnip')
  ls.setup()
  ls.filetype_extend('typescript', { 'javascript' })
  ls.filetype_extend('javascriptreact', { 'javascript' })
  ls.filetype_extend('typescriptreact', { 'javascript', 'javascriptreact' })
  ls.filetype_extend(
      'vue',
      { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' }
  )
  require('luasnip.loaders.from_lua').lazy_load({
      paths = { vim.fn.stdpath('config') .. '/snippets' },
  })

  vim.keymap.set({ 'i', 's', 'n' }, '<esc>', function()
      local ls = require('luasnip')
      if ls.get_active_snip() then
          ls.unlink_current()
      end
      return '<esc>'
  end, { expr = true })
  '';

  xdg.configFile."nvim/plugin/mini-ai.lua".text = ''
  vim.pack.add({
      { src = 'https://github.com/nvim-mini/mini.ai' }
  })

  local ai = require('mini.ai')
  ai.setup({
      n_lines = 200,
      custom_textobjects = {
          o = ai.gen_spec.treesitter({ -- code block
              a = { '@block.outer', '@conditional.outer', '@loop.outer' },
              i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          }),
          f = ai.gen_spec.treesitter({
              a = '@function.outer',
              i = '@function.inner',
          }), -- function
          c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }), -- class
          t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' }, -- tags
          d = { '%f[%d]%d+' }, -- digits
          e = { -- Word with case
              {
                  '%u[%l%d]+%f[^%l%d]',
                  '%f[%S][%l%d]+%f[^%l%d]',
                  '%f[%P][%l%d]+%f[^%l%d]',
                  '^[%l%d]+%f[^%l%d]',
              },
              '^().*()$',
          },
          u = ai.gen_spec.function_call(), -- u for "Usage"
          U = ai.gen_spec.function_call({ name_pattern = '[%w_]' }), -- without dot in function name
          G = function()
              local from = { line = 1, col = 1 }
              local to = {
                  line = vim.fn.line('$'),
                  col = math.max(vim.fn.getline('$'):len(), 1),
              }
              return { from = from, to = to }
          end,
      },
  })
  '';

  xdg.configFile."nvim/plugin/mini-align.lua".text = ''
  vim.pack.add({ 'https://github.com/nvim-mini/mini.align' })

  require('mini.align').setup({})
  '';

  xdg.configFile."nvim/plugin/mini-diff.lua".text = ''
  vim.pack.add({ 'https://github.com/nvim-mini/mini.diff' })

  require('mini.diff').setup({})

  vim.keymap.set('n', '<leader>go', function()
      require('mini.diff').toggle_overlay(0)
  end, { desc = 'Toggle MiniDiff Overlay' })
  '';

  xdg.configFile."nvim/plugin/mini-icons.lua".text = ''
  vim.pack.add({ 'https://github.com/nvim-mini/mini.icons' })

  package.preload['nvim-web-devicons'] = function()
      require('mini.icons').mock_nvim_web_devicons()
      return package.loaded['nvim-web-devicons']
  end

  local prettier =
      { '.prettierrc', '.prettierrc.json', '.prettierrc.yaml', '.prettierrc.yml' }
  local tsconfig = { 'tsconfig.json', 'tsconfig.app.json', 'tsconfig.node.json' }

  local file = {
      ['package.json'] = { glyph = '', hl = 'MiniIconsGreen' },
      ['vite.config.ts'] = { glyph = '', hl = 'MiniIconsPurple' },
      ['nuxt.config.ts'] = { glyph = '', hl = 'MiniIconsGreen' },
      ['favicon.ico'] = { glyph = '', hl = 'MiniIconsYellow' },
      ['.keep'] = { glyph = '󰊢', hl = 'MiniIconsGrey' },
      ['devcontainer.json'] = { glyph = '', hl = 'MiniIconsAzure' },
      ['vitest.config.ts'] = { glyph = '', hl = 'MiniIconsGreen' },
      ['tsdown.config.ts'] = { glyph = '', hl = 'MiniIconsYellow' },
      ['drizzle.config.ts'] = { glyph = '', hl = 'MiniIconsGreen' },
      ['.oxlintrc.json'] = { glyph = '', hl = 'MiniIconsOrange' },
      ['README.md'] = { glyph = '', hl = 'MiniIconsGray' },
      ['deno.json'] = { glyph = '', hl = 'MiniIconsGreen' },
  }

  for _, name in ipairs(prettier) do
      file[name] = { glyph = '', hl = 'MiniIconsPurple' }
  end

  for _, name in ipairs(tsconfig) do
      file[name] = { glyph = '', hl = 'MiniIconsBlue' }
  end

  require('mini.icons').setup({
      file = file,
      filetype = {
          dotenv = { glyph = '', hl = 'MiniIconsYellow' },
          vue = { glyph = '' },
      },
  })
  '';

  xdg.configFile."nvim/plugin/mini-operators.lua".text = ''
  vim.pack.add({
      { src = 'https://github.com/nvim-mini/mini.operators' },
  })

  require('mini.operators').setup(
      -- No need to copy this inside `setup()`. Will be used automatically.
      {
          -- Each entry configures one operator.
          -- `prefix` defines keys mapped during `setup()`: in Normal mode
          -- to operate on textobject and line, in Visual - on selection.

          -- Evaluate text and replace with output
          evaluate = {
              prefix = 'g=',

              -- Function which does the evaluation
              func = nil,
          },

          -- Exchange text regions
          exchange = {
              prefix = 'gX',

              -- Whether to reindent new text to match previous indent
              reindent_linewise = true,
          },

          -- Multiply (duplicate) text
          multiply = {
              prefix = 'gm',

              -- Function which can modify text before multiplying
              func = nil,
          },

          -- Replace text with register
          replace = {
              prefix = 'gR',

              -- Whether to reindent new text to match previous indent
              reindent_linewise = true,
          },

          -- Sort text
          sort = {
              prefix = 'gS',

              -- Function which does the sort
              func = nil,
          },
      }
  )
  '';

  xdg.configFile."nvim/plugin/mini-pairs.lua".text = ''
  vim.pack.add({ 'https://github.com/nvim-mini/mini.pairs' })

  require('mini.pairs').setup({
      modes = { insert = true, command = true, terminal = false },
      -- skip autopair when next character is one of these
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- skip autopair when the cursor is inside these treesitter nodes
      skip_ts = { 'string' },
      -- skip autopair when next character is closing pair
      -- and there are more closing pairs than opening pairs
      skip_unbalanced = true,
      -- better deal with markdown code blocks
      markdown = true,
  })
  '';

  xdg.configFile."nvim/plugin/mini-splitjoin.lua".text = ''
  vim.pack.add({ 'https://github.com/nvim-mini/mini.splitjoin' })

  require('mini.splitjoin').setup({
      mappings = {
          toggle = 'gS',
          split = ''',
          join = ''',
      },

      -- Detection options: where split/join should be done
      detect = {
          -- Array of Lua patterns to detect region with arguments.
          -- Default: { '%b()', '%b[]', '%b{}' }
          brackets = nil,

          -- String Lua pattern defining argument separator
          separator = ', ',

          -- Array of Lua patterns for sub-regions to exclude separators from.
          -- Enables correct detection in presence of nested brackets and quotes.
          -- Default: { '%b()', '%b[]', '%b{}', '%b""', "%b'''" }
          exclude_regions = nil,
      },

      -- Split options
      split = {
          hooks_pre = {},
          hooks_post = {},
      },

      -- Join options
      join = {
          hooks_pre = {},
          hooks_post = {},
      },
  })
  '';

  xdg.configFile."nvim/plugin/mini-surround.lua".text = ''
  vim.pack.add({ 'https://github.com/nvim-mini/mini.surround' })

  require('mini.surround').setup({
      n_lines = 100,
      mappings = {
          add = 'gsa', -- Add surrounding in Normal and Visual modes
          delete = 'gsd', -- Delete surrounding
          find = 'gsf', -- Find surrounding (to the right)
          find_left = 'gsF', -- Find surrounding (to the left)
          highlight = 'gsh', -- Highlight surrounding
          replace = 'gsr', -- Replace surrounding
          update_n_lines = 'gsn', -- Update `n_lines`
      },
      search_method = 'cover_or_next',
  })
  '';

  xdg.configFile."nvim/plugin/nvim-lint.lua".text = ''
  vim.pack.add({ 'https://github.com/mfussenegger/nvim-lint' })

  local lint = require('lint')
  lint.linters_by_ft = {
      javascript = { 'oxlint', 'eslint' },
      typescript = { 'oxlint', 'eslint' },
      javascriptreact = { 'oxlint', 'eslint' },
      typescriptreact = { 'oxlint', 'eslint' },
  }

  local fts = vim.tbl_keys(lint)
  vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
      pattern = fts,
      callback = function()
          require('lint').try_lint()
      end,
  })
  '';

  xdg.configFile."nvim/plugin/persistence.lua".text = ''
  vim.pack.add({ 'https://github.com/folke/persistence.nvim' })

  require('persistence').setup({
      need = 2,
  })

  vim.keymap.set('n', '<leader>qs', function()
      require('persistence').save()
  end, { desc = 'Save Session' })
  vim.keymap.set('n', '<leader>qS', function()
      require('persistence').select()
  end, { desc = 'Select Session' })
  vim.keymap.set('n', '<leader>ql', function()
      require('persistence').load({ last = true })
  end, { desc = 'Restore Last Session' })
  vim.keymap.set('n', '<leader>qd', function()
      require('persistence').stop()
  end, { desc = "Don't Save Current Session" })
  '';

  xdg.configFile."nvim/plugin/render-markdown.lua".text = ''
  vim.pack.add({ 'https://github.com/MeanderingProgrammer/render-markdown.nvim' })

  require('render-markdown').setup({
      preset = 'obsidian',
  })
  '';

  xdg.configFile."nvim/plugin/schemastore.lua".text = ''
  vim.pack.add({ 'https://github.com/b0o/schemastore.nvim' })
  '';

  xdg.configFile."nvim/plugin/snacks.lua".text = ''
  vim.pack.add({ 'https://github.com/folke/snacks.nvim' })

  require('snacks').setup({
      picker = {
          sources = {
              files = {
                  hidden = true,
              },
              explorer = {
                  hidden = true,
                  win = {
                      list = {
                          keys = {
                              ['.'] = 'tcd',
                              ['<c-c>'] = 'cd',
                          },
                      },
                  },
              },
              git_diff = {},
          },
          previewers = {
              diff = {
                  builtin = false,
                  cmd = { 'delta' },
              },
              git = {
                  builtin = false,
              },
          },
          win = {
              input = {
                  keys = {
                      ['<c-l>'] = {
                          'loclist',
                          mode = { 'n', 'i' },
                      },
                  },
              },
              list = {
                  keys = {
                      ['<c-l>'] = {
                          'loclist',
                      },
                  },
              },
          },
      },
      explorer = {
          enabled = false,
          replace_netrw = false,
          trash = true,
      },
      lazygit = {
          configure = true,
      },
      scope = { enabled = false },
      terminal = {
          enabled = false,
      },
      toggle = { enabled = true },
      words = { enabled = true },
      bufdelete = { enabled = true },
      indent = {
          enabled = true,
          animate = {
              enabled = false,
          },
      },
      image = {
          enabled = true,
          doc = {
              max_height = 3,
          },
          convert = {
              notify = false, -- show a notification on error
              ---@type snacks.image.args
              mermaid = function()
                  local theme = vim.o.background == 'light' and 'neutral'
                      or 'dark'
                  return {
                      '-i',
                      '{src}',
                      '-o',
                      '{file}',
                      '-b',
                      'transparent',
                      '-t',
                      theme,
                      '-s',
                      '{scale}',
                  }
              end,
              ---@type table<string,snacks.image.args>
              magick = {
                  default = { '{src}[0]', '-scale', '1920x1080>' }, -- default for rater images
                  vector = { '-density', 192, '{src}[{page}]' }, -- used by vector images like svg
                  math = { '-density', 192, '{src}[{page}]', '-trim' },
                  pdf = {
                      '-density',
                      192,
                      '{src}[{page}]',
                      '-background',
                      'white',
                      '-alpha',
                      'remove',
                      '-trim',
                  },
              },
          },
          math = {
              enabled = true,
          },
          icons = {
              math = '󰪚 ',
              chart = '󰄧 ',
              image = ' ',
          },
      },
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      input = { enabled = true },
      debug = { enabled = true },
  })

  -- Top Pickers & Explorer
  vim.keymap.set('n', '<leader><space>', function()
      Snacks.picker.smart()
  end, { desc = 'Smart Find Files' })
  vim.keymap.set('n', '<leader>fb', function()
      Snacks.picker.buffers()
  end, { desc = 'Listed Buffers' })
  vim.keymap.set('n', '<leader>fB', function()
      Snacks.picker.buffers({ hidden = true })
  end, { desc = 'Hidden Buffers' })
  vim.keymap.set('n', '<leader>fc', function()
      Snacks.picker.files({ cwd = vim.fn.stdpath('config') })
  end, { desc = 'Find Config File' })
  vim.keymap.set('n', '<leader>ff', function()
      Snacks.picker.files()
  end, { desc = 'Find Files' })
  vim.keymap.set('n', '<leader>fg', function()
      Snacks.picker.git_files()
  end, { desc = 'Find Git Files' })
  vim.keymap.set('n', '<leader>fp', function()
      Snacks.picker.projects()
  end, { desc = 'Projects' })
  vim.keymap.set('n', '<leader>fr', function()
      Snacks.picker.recent()
  end, { desc = 'Recent' })
  -- git
  vim.keymap.set('n', '<leader>gl', function()
      Snacks.picker.git_log()
  end, { desc = 'Git Log' })
  vim.keymap.set('n', '<leader>gL', function()
      Snacks.picker.git_log_line()
  end, { desc = 'Git Log Line' })
  vim.keymap.set('n', '<leader>gs', function()
      Snacks.picker.git_status()
  end, { desc = 'Git Status' })
  vim.keymap.set('n', '<leader>gS', function()
      Snacks.picker.git_stash()
  end, { desc = 'Git Stash' })
  vim.keymap.set('n', '<leader>gd', function()
      Snacks.picker.git_diff()
  end, { desc = 'Git Diff (Hunks)' })
  vim.keymap.set('n', '<leader>gf', function()
      Snacks.picker.git_log_file()
  end, { desc = 'Git Log File' })
  vim.keymap.set('n', '<leader>gb', function()
      Snacks.git.blame_line()
  end, { desc = 'Git Blame Line' })
  -- gh
  vim.keymap.set('n', '<leader>gi', function()
      Snacks.picker.gh_issue()
  end, { desc = 'GitHub Issues (open)' })
  vim.keymap.set('n', '<leader>gI', function()
      Snacks.picker.gh_issue({ state = 'all' })
  end, { desc = 'GitHub Issues (all)' })
  vim.keymap.set('n', '<leader>gp', function()
      Snacks.picker.gh_pr()
  end, { desc = 'GitHub Pull Requests (open)' })
  vim.keymap.set('n', '<leader>gP', function()
      Snacks.picker.gh_pr({ state = 'all' })
  end, { desc = 'GitHub Pull Requests (all)' })
  -- Grep
  vim.keymap.set('n', '<leader>sb', function()
      Snacks.picker.lines()
  end, { desc = 'Buffer Lines' })
  vim.keymap.set('n', '<leader>sB', function()
      Snacks.picker.grep_buffers()
  end, { desc = 'Grep Open Buffers' })
  vim.keymap.set('n', '<leader>sg', function()
      Snacks.picker.grep()
  end, { desc = 'Grep' })
  vim.keymap.set({ 'n', 'x' }, '<leader>sw', function()
      Snacks.picker.grep_word()
  end, { desc = 'Visual selection or word' })
  -- search
  vim.keymap.set('n', '<leader>n', function()
      Snacks.picker.notifications()
  end, { desc = 'Notifications' })
  vim.keymap.set('n', '<leader>sa', function()
      Snacks.picker.autocmds()
  end, { desc = 'Autocmds' })
  vim.keymap.set('n', '<leader>sC', function()
      Snacks.picker.commands()
  end, { desc = 'Commands' })
  vim.keymap.set('n', '<leader>sD', function()
      Snacks.picker.diagnostics()
  end, { desc = 'Diagnostics' })
  vim.keymap.set('n', '<leader>sd', function()
      Snacks.picker.diagnostics_buffer()
  end, { desc = 'Buffer Diagnostics' })
  vim.keymap.set('n', '<leader>sh', function()
      Snacks.picker.help()
  end, { desc = 'Help Pages' })
  vim.keymap.set('n', '<leader>sH', function()
      Snacks.picker.highlights()
  end, { desc = 'Highlights' })
  vim.keymap.set('n', '<leader>si', function()
      Snacks.picker.icons()
  end, { desc = 'Icons' })
  vim.keymap.set('n', '<leader>sj', function()
      Snacks.picker.jumps()
  end, { desc = 'Jumps' })
  vim.keymap.set('n', '<leader>sk', function()
      Snacks.picker.keymaps()
  end, { desc = 'Keymaps' })
  vim.keymap.set('n', '<leader>sm', function()
      Snacks.picker.marks()
  end, { desc = 'Marks' })
  vim.keymap.set('n', '<leader>sM', function()
      Snacks.picker.man()
  end, { desc = 'Man Pages' })
  vim.keymap.set('n', '<leader>sR', function()
      Snacks.picker.resume()
  end, { desc = 'Resume' })
  vim.keymap.set('n', '<leader>su', function()
      Snacks.picker.undo()
  end, { desc = 'Undo History' })
  -- todo picker (folded from todo-comments `specs` injection into snacks)
  vim.keymap.set('n', '<leader>sT', function()
      Snacks.picker.todo_comments()
  end, { desc = 'Todo' })
  -- LSP
  vim.keymap.set('n', '<leader>ss', function()
      Snacks.picker.lsp_workspace_symbols()
  end, { desc = 'LSP Workspace Symbols' })

  vim.keymap.set('n', '<leader>.', function()
      Snacks.scratch()
  end, { desc = 'Toggle Scratch Buffer' })
  vim.keymap.set('n', '<leader>S', function()
      Snacks.scratch.select()
  end, { desc = 'Select Scratch Buffer' })

  vim.keymap.set('n', '[w', function()
      Snacks.words.jump(-vim.v.count1, true)
  end, { desc = 'Previous Word' })
  vim.keymap.set('n', ']w', function()
      Snacks.words.jump(vim.v.count1, true)
  end, { desc = 'Next Word' })

  vim.keymap.set('n', '<leader>z', function()
      Snacks.picker.zoxide()
  end, { desc = 'Zoxide' })

  -- toggles and LSP-aware keymaps (from lazy `config` body)
  Snacks.toggle.diagnostics():map('<leader>ud')
  Snacks.toggle.treesitter():map('<leader>ut')
  if vim.lsp.inlay_hint then
      Snacks.toggle.inlay_hints():map('<leader>uh')
  end

  if vim.fn.executable('lazygit') == 1 then
      vim.keymap.set('n', '<leader>gg', function()
          Snacks.lazygit()
      end, { desc = 'Lazygit' })
  end

  Snacks.toggle.zoom():map('<leader>uz')
  Snacks.toggle.zen():map('<leader>uZ')

  -- Set keymap for buffers with a specific LSP client
  Snacks.keymap.set('n', '<leader>co', function()
      vim.lsp.buf.code_action({
          apply = true,
          context = {
              only = { 'source.organizeImports' },
              diagnostics = {},
          },
      })
  end, {
      lsp = { name = 'vtsls' },
      desc = 'Organize Imports',
  })

  Snacks.keymap.set('n', '<leader>co', function()
      vim.lsp.buf.code_action({
          apply = true,
          context = {
              only = { 'source.organizeImports' },
              diagnostics = {},
          },
      })
  end, {
      lsp = { name = 'tsgo' },
      desc = 'Organize Imports',
  })
  '';

  xdg.configFile."nvim/plugin/text-case.lua".text = ''
  vim.pack.add({ 'https://github.com/johmsalas/text-case.nvim' })

  require('textcase').setup({
      -- Set `default_keymappings_enabled` to false if you don't want automatic keymappings to be registered.
      default_keymappings_enabled = true,
      -- `prefix` is only considered if `default_keymappings_enabled` is true. It configures the prefix
      -- of the keymappings, e.g. `gau ` executes the `current_word` method with `to_upper_case`
      -- and `gaou` executes the `operator` method with `to_upper_case`.
      prefix = '<leader>t',
      -- If `substitude_command_name` is not nil, an additional command with the passed in name
      -- will be created that does the same thing as "Subs" does.
      substitude_command_name = nil,
      -- By default, all methods are enabled. If you set this option with some methods omitted,
      -- these methods will not be registered in the default keymappings. The methods will still
      -- be accessible when calling the exact lua function e.g.:
      -- "<CMD>lua require('textcase').current_word('to_snake_case')<CR>"
      enabled_methods = {
          'to_upper_case',
          'to_lower_case',
          'to_snake_case',
          'to_dash_case',
          'to_title_dash_case',
          'to_constant_case',
          'to_dot_case',
          'to_comma_case',
          'to_phrase_case',
          'to_camel_case',
          'to_pascal_case',
          'to_title_case',
          'to_path_case',
          'to_upper_phrase_case',
          'to_lower_phrase_case',
      },
  })
  '';

  xdg.configFile."nvim/plugin/todo-comments.lua".text = ''
  vim.pack.add({
      'https://github.com/nvim-lua/plenary.nvim',
      'https://github.com/folke/todo-comments.nvim',
  })

  require('todo-comments').setup()

  vim.keymap.set('n', ']t', function()
      require('todo-comments').jump_next()
  end, { desc = 'Next todo comment' })

  vim.keymap.set('n', '[t', function()
      require('todo-comments').jump_prev()
  end, { desc = 'Previous todo comment' })
  '';

  xdg.configFile."nvim/plugin/treesitter.lua".text = ''
  vim.pack.add({
      'https://github.com/romus204/tree-sitter-manager.nvim',
      'https://github.com/nvim-treesitter/nvim-treesitter-context',
      {
          src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
          version = 'main',
      },
  })

  require('tree-sitter-manager').setup({
      -- Default Options
      -- ensure_installed = {}, -- list of parsers to install at the start of a neovim session
      -- border = nil, -- border style for the window (e.g. "rounded", "single"), if nil, use the default border style defined by 'vim.o.winborder'. See :h 'winborder' for more info.
      -- auto_install = false, -- if enabled, install missing parsers when editing a new file
      -- highlight = true, -- treesitter highlighting is enabled by default
      -- languages = {}, -- override or add new parser sources
      -- parser_dir = vim.fn.stdpath("data") .. "/site/parser",
      -- query_dir = vim.fn.stdpath("data") .. "/site/queries",
  })
  vim.treesitter.language.register('tsx', 'javascriptreact')

  require('treesitter-context').setup({
      multiwindow = true,
      max_lines = '10%',
  })

  require('nvim-treesitter-textobjects').setup({
      lookahead = true,
  })
  '';

  xdg.configFile."nvim/plugin/ts-autotag.lua".text = ''
  vim.pack.add({ 'https://github.com/windwp/nvim-ts-autotag' })

  require('nvim-ts-autotag').setup({
      opts = {
          enable_close = true, -- Auto close tags
          enable_rename = true, -- Auto rename pairs of tags
          enable_close_on_slash = true, -- Auto close on trailing </
      },
  })
  '';

  xdg.configFile."nvim/plugin/ts-comments.lua".text = ''
  vim.pack.add({ 'https://github.com/folke/ts-comments.nvim' })

  require('ts-comments').setup({})
  '';

  xdg.configFile."nvim/plugin/vimtex.lua".text = ''
  vim.pack.add { "https://github.com/lervag/vimtex" }

  -- Sioyek is a first-class macOS build; it does its own SyncTeX parsing, and
  -- vimtex hands it the forward/inverse search coordinates itself.
  vim.g.vimtex_view_method = 'sioyek'
  vim.g.vimtex_callback_progpath = '${nvim}'
  '';

  xdg.configFile."nvim/plugin/which-key.lua".text = ''
  vim.pack.add({ 'https://github.com/folke/which-key.nvim' })

  require('which-key').setup({
      preset = 'helix',
      spec = {
          {
              mode = { 'n', 'v' },
              { '<leader>a', group = 'AI', icon = '󱚠' },
          },
          {
              mode = { 'n' },
              { '<leader>g', group = 'Git' },
              { '<leader>c', group = 'Code' },
              { '<leader>q', group = 'Session' },
              { '<leader>R', group = 'HTTP', icon = ''' },
          },
      },
  })

  vim.keymap.set('i', '<C-_>', function()
      require('which-key').show({ global = false })
  end, { desc = 'Buffer Local Keymaps (which-key)' })
  vim.keymap.set('i', '<C-/>', function()
      require('which-key').show({ global = false })
  end, { desc = 'Buffer Local Keymaps (which-key)' })
  vim.keymap.set('n', '<leader>?', function()
      require('which-key').show({ global = false })
  end, { desc = 'Buffer Keymaps (which-key)' })
  vim.keymap.set('n', '<c-w><space>', function()
      require('which-key').show({ keys = '<c-w>', loop = true })
  end, { desc = 'Window Hydra Mode (which-key)' })
  '';

  xdg.configFile."nvim/plugin/yanky.lua".text = ''
  vim.pack.add({ 'https://github.com/gbprod/yanky.nvim' })

  require('yanky').setup({
      ring = { storage = 'shada' },
      highlight = { timer = 150 },
  })

  -- stylua: ignore start
  vim.keymap.set({ 'n', 'x' }, '<leader>p', function() Snacks.picker.yanky() end, { desc = 'Open Yank History' })
  vim.keymap.set({ 'n', 'x' }, 'y', '<Plug>(YankyYank)', { desc = 'Yank text' })
  vim.keymap.set({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)', { desc = 'Put yanked text after cursor' })
  vim.keymap.set({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)', { desc = 'Put yanked text before cursor' })
  vim.keymap.set({ 'n', 'x' }, 'gp', '<Plug>(YankyGPutAfter)', { desc = 'Put yanked text after selection' })
  vim.keymap.set({ 'n', 'x' }, 'gP', '<Plug>(YankyGPutBefore)', { desc = 'Put yanked text before selection' })
  vim.keymap.set('n', '<c-p>', '<Plug>(YankyPreviousEntry)', { desc = 'Select previous entry through yank history' })
  vim.keymap.set('n', '<c-n>', '<Plug>(YankyNextEntry)', { desc = 'Select next entry through yank history' })
  -- stylua: ignore end
  '';

  xdg.configFile."nvim/plugin/yazi.lua".text = ''
  vim.pack.add({
      'https://github.com/nvim-lua/plenary.nvim',
      'https://github.com/mikavilpas/yazi.nvim',
  })

  vim.g.loaded_netrwPlugin = 1

  require('yazi').setup({
      open_for_directories = true,
      keymaps = {
          show_help = '<f2>',
          cycle_open_buffers = '<c-tab>'
      },
  })

  vim.keymap.set('n', '<leader>ee', function()
      vim.cmd.Yazi()
  end, { desc = 'Open Yazi at the current file' })

  vim.keymap.set('n', '<leader>ew', function()
      vim.cmd.Yazi('cwd')
  end, { desc = 'Open Yazi in the current working directory' })
  '';

  xdg.configFile."nvim/lua/vim-pack-hooks.lua".text = ''
  local M = {}

  ---@param name string
  ---@param func fun(): nil
  M.build = function(name, func)
      vim.api.nvim_create_autocmd('PackChanged', {
          callback = function(ev)
              local kind = ev.data.kind
              if
                  ev.data.spec.name == name
                  and (kind == 'update' or kind == 'install')
              then
                  func()
              end
          end,
      })
  end

  return M
  '';
}
