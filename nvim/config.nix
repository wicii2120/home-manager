{ ... }:

let
  fishShell = "/opt/homebrew/bin/fish";
in
{
  xdg.configFile."nvim/lua/config/options.lua".text = ''
  vim.g.mapleader = ' '
  vim.g.maplocalleader = '\\'

  vim.o.shell = "${fishShell}"

  vim.o.wrap = true
  vim.o.spell = false
  vim.o.winborder = 'rounded'
  vim.o.colorcolumn = '80'
  vim.o.tabstop = 4
  vim.o.shiftwidth = 4
  vim.o.expandtab = true
  vim.o.shiftround = true -- Round indent

  vim.o.exrc = true
  vim.o.autowrite = true
  vim.o.conceallevel = 2  -- Hide * markup for bold and italic, but not markers with substitutions
  vim.o.confirm = true    -- Confirm to save changes before exiting modified buffer
  vim.o.cursorline = true -- Enable highlighting of the current line
  vim.o.foldlevel = 6
  vim.o.foldmethod = 'indent'
  vim.o.ignorecase = true     -- Ignore case
  vim.o.inccommand = 'split'  -- preview incremental substitute
  vim.o.laststatus = 3        -- global statusline
  vim.o.linebreak = true      -- Wrap lines at convenient points
  vim.o.list = true           -- Show some invisible characters (tabs...
  vim.o.mouse = 'a'           -- Enable mouse mode
  vim.o.number = true         -- Print line number
  vim.o.relativenumber = true -- Relative line numbers
  vim.o.pumheight = 20        -- Maximum number of entries in a popup
  vim.o.scrolloff = 4         -- Lines of context
  vim.o.smartcase = true      -- Don't ignore case with capitals
  vim.o.smoothscroll = true
  vim.o.splitright = true
  vim.o.splitkeep = 'screen'
  vim.o.splitbelow = true    -- Put new windows below current
  vim.o.termguicolors = true -- True color support
  vim.o.timeoutlen = 300     -- Lower than default (1000) to quickly trigger which-key
  vim.o.undofile = true
  vim.o.updatetime = 500
  vim.o.wildmode = 'longest:full,full' -- Command-line completion mode
  vim.o.winminwidth = 5                -- Minimum window width
  vim.o.signcolumn = 'yes'
  vim.o.showcmdloc = 'statusline'
  vim.o.cmdheight = 1
  vim.o.showbreak = '+++ '
  vim.opt.fillchars = {
    foldopen = '',
    foldclose = '',
    fold = ' ',
    diff = '╱',
    eob = '~',
  }
  vim.o.completeopt = 'fuzzy,menuone,noselect,popup'
  vim.opt.sessionoptions = {
    'buffers',
    'curdir',
    'tabpages',
    'winsize',
    'help',
    'globals',
    'skiprtp',
    'folds',
  }
  vim.cmd([[set shortmess+=a]])
  vim.cmd([[set formatoptions-=t]])
  vim.cmd([[set formatoptions+=n1pro]])
  vim.opt.rulerformat = '%=%l,%v  %p%% '

  -- cd to current file
  vim.cmd[[cabbrev cdd cd %:h]]
  vim.cmd[[cabbrev bb lua Snacks.bufdelete()]]

  -- vim.cmd[[hi link netrwMarkFile Visual]]

  vim.cmd[=[set isfname+=@-@,(,),[,]]=]
  vim.cmd[[packadd cfilter]]

  vim.g.netrw_liststyle = 3
  '';

  xdg.configFile."nvim/lua/config/autocmds.lua".text = ''
  ---@param name string
  local augroup = function(name)
      return vim.api.nvim_create_augroup('my.' .. name, { clear = true })
  end

  -- Check if we need to reload the file when it changed
  vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
      group = augroup('checktime'),
      callback = function()
          if vim.o.buftype ~= 'nofile' then
              vim.cmd('checktime')
          end
      end,
  })

  -- resize splits if window got resized
  vim.api.nvim_create_autocmd({ 'VimResized' }, {
      callback = function()
          local current_tab = vim.fn.tabpagenr()
          vim.cmd('tabdo wincmd =')
          vim.cmd('tabnext ' .. current_tab)
      end,
  })


  -- treeistter
  vim.api.nvim_create_autocmd({ 'FileType' }, {
      group = augroup('treesitter'),
      pattern = '*',
      callback = function()
          vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      end,
  })

  vim.api.nvim_create_autocmd('LspAttach', {
      group = augroup('tsc-make'),
      callback = function(args)
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

          local ts_cmd_map = {
              vue_ls = 'vue-tsc',
              vtsls = 'tsc',
              tsgo = 'tsgo',
          }

          local ts_cmd = ts_cmd_map[client.name]

          if not ts_cmd then
              return
          end

          local efm = [[%f\(%l\,%c\):\ error\ TS%n:\ %m]]
          local tsc_opts = ' --build --noEmit --pretty false '

          ---@param compiler 'vue-tsc' | 'tsc' | 'tsgo'
          local function defCommand(compiler)
              local cmd = require('textcase').api.to_pascal_case(compiler)
              vim.api.nvim_create_user_command(cmd, function()
                  local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
                  local res = vim.system(
                      { 'zsh', '-c', 'pnpm ' .. ts_cmd .. tsc_opts },
                      { cwd = cwd, text = true }
                  ):wait()
                  local out = (res.stdout or ''') .. '\n' .. (res.stderr or ''')
                  local lines = vim.split(out, '\n', { trimempty = true })
                  vim.schedule(function()
                      vim.fn.setqflist({}, ' ', {
                          title = compiler .. ' diagnostics',
                          lines = lines,
                          efm = efm,
                      })
                      vim.cmd('copen | stopi')
                  end)
              end, { bar = true })
          end

          defCommand(ts_cmd)
      end,
  })
  '';

  xdg.configFile."nvim/lua/config/keymaps.lua".text = ''
  vim.keymap.set('i', '<s-cr>', '<c-o>O')
  vim.keymap.set('i', '<d-cr>', '<c-o>o')
  vim.keymap.set('i', '<c-cr>', '<c-o>o')

  vim.keymap.set('v', '<m-c>', '"+y', { desc = 'Copy to system clipboard' })
  vim.keymap.set('n', '<m-c>', '"+yy', { desc = 'Copy line to system clipboard' })
  vim.keymap.set('v', '<d-c>', '"+y', { desc = 'Copy to system clipboard' })
  vim.keymap.set('n', '<d-c>', '"+yy', { desc = 'Copy line to system clipboard' })

  vim.keymap.set('c', '<c-a>', '<c-b>')

  -- Quit
  vim.cmd.cabbrev('Qa', 'qa')
  vim.cmd.cabbrev('QA', 'qa')
  vim.cmd.cabbrev('Q', 'q')

  vim.keymap.set({ 'n', 'i', 'x', 'v' }, '<m-s>', '<cmd>w<cr><esc>', { desc = 'Save file' })
  vim.keymap.set({ 'n', 'i', 'x', 'v' }, '<d-s>', '<cmd>w<cr><esc>', { desc = 'Save file' })

  -- Move Lines
  vim.keymap.set('n', '<A-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = 'Move Down' })
  vim.keymap.set('n', '<A-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = 'Move Up' })
  vim.keymap.set('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move Down' })
  vim.keymap.set('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move Up' })
  vim.keymap.set(
    'v',
    '<A-j>',
    ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv",
    { desc = 'Move Down' }
  )
  vim.keymap.set(
    'v',
    '<A-k>',
    ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv",
    { desc = 'Move Up' }
  )

  -- Add undo break-points
  vim.keymap.set('i', ',', ',<c-g>u')
  vim.keymap.set('i', '.', '.<c-g>u')
  vim.keymap.set('i', ';', ';<c-g>u')
  vim.keymap.set('i', ' ', ' <c-g>u')

  -- better indenting
  vim.keymap.set('x', '<', '<gv')
  vim.keymap.set('x', '>', '>gv')

  -- commenting
  vim.keymap.set(
    'n',
    'gco',
    'o<esc>ccx<esc><cmd>normal gcc<cr>fxa<bs>',
    { desc = 'Add Comment Below' }
  )
  vim.keymap.set(
    'n',
    'gcO',
    'O<esc>ccx<esc><cmd>normal gcc<cr>fxa<bs>',
    { desc = 'Add Comment Above' }
  )
  '';
}
