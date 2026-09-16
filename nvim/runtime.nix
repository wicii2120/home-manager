# Plain runtime files: lsp/ and after/lsp/ are read by vim.lsp.enable,
# after/ftplugin/ by the filetype plugin loader, snippets/ by LuaSnip.
{ pkgs, ... }:

let
  # vtsls resolves @vue/typescript-plugin from the @vue/language-server package
  # directory. The check fails the build if a nixpkgs change moves that layout,
  # instead of leaving an unusable path in the config.
  vueLanguageServer = pkgs.runCommand "vue-language-server-plugin-root" { } ''
    test -f ${pkgs.vue-language-server}/lib/language-tools/packages/language-server/node_modules/@vue/typescript-plugin/package.json
    ln -s ${pkgs.vue-language-server}/lib/language-tools/packages/language-server $out
  '';
in
{
  xdg.configFile."nvim/after/ftplugin/vue.lua".text = ''
    vim.cmd.set('formatoptions-=ro')
  '';

  xdg.configFile."nvim/after/lsp/denols.lua".text = ''
    return {
        root_markers = { 'deno.json', 'deno.jsonc' },
    }
  '';

  xdg.configFile."nvim/after/lsp/tailwindcss.lua".text = ''
    return {
      settings = {
        tailwindCSS = {
          classFunctions = { 'twMerge', 'cva', 'tv' },
          classAttributes = { 'class', 'className', 'ngClass', 'class:list', 'classList', 'ui' },
        },
      },
    }
  '';

  xdg.configFile."nvim/after/lsp/tsgo.lua".text = ''
    return {
        root_markers = false,
        settings = {
            typescript = {
                suggest = {
                    autoImports = true,
                    completeFunctionCalls = true,
                },
            },
            javascript = {
                suggest = {
                    autoImports = true,
                    completeFunctionCalls = true,
                },
            },
        },
    }
  '';

  xdg.configFile."nvim/after/lsp/vtsls.lua".text = ''
    local vue_language_server_path = '${vueLanguageServer}'

    local vue_plugin = {
        name = '@vue/typescript-plugin',
        location = vue_language_server_path,
        languages = { 'vue' },
        configNamespace = 'typescript',
    }

    ---@class config: vim.lsp.Config
    return {
        filetypes = {
            'vue',
            'typescript',
            'javascript',
            'typescriptreact',
            'javascriptreact',
        },
        settings = {
            vtsls = {
                tsserver = {
                    globalPlugins = {
                        vue_plugin,
                    },
                },
            },
            typescript = {
                suggest = {
                    autoImports = true,
                    completeFunctionCalls = false,
                },
            },
            javascript = {
                suggest = {
                    autoImports = true,
                    completeFunctionCalls = false,
                },
            },
        },
    }
  '';

  xdg.configFile."nvim/after/lsp/vue_ls.lua".text = ''
    return {
      settings = {
        format = {
          script = {
            initialIndent = true,
          },
          style = {
            initialIndent = true,
          },
        },
        inlayHints = {
          inlineHandlerLeading = true,
          missingProps = true,
        },
        suggest = {
          componentNameCasing = 'alwaysPascalCase',
          propNameCasing = 'alwaysCamelCase',
        },
      },
    }
  '';

  xdg.configFile."nvim/after/lsp/yamlls.lua".text = ''
    ---@type vim.lsp.Config
    return {
        cmd = { '${pkgs.yaml-language-server}/bin/yaml-language-server', '--stdio' },
    }
  '';

  xdg.configFile."nvim/lsp/jsonls.lua".text = ''
    ---@type vim.lsp.Config
    return {
        settings = {
            json = {
                validate = {
                    enable = true,
                },
            },
        },
        before_init = function(_, client_config)
            client_config.settings.json.schemas =
                require('schemastore').json.schemas()
        end,
    }
  '';

  xdg.configFile."nvim/lsp/yamlls.lua".text = ''
    ---@type vim.lsp.Config
    return {
        settings = {
            yaml = {
                schemaStore = {
                    enable = false,
                    url = ''',
                },
            },
        },
        before_init = function(_, client_config)
            client_config.settings.yaml.schemas =
                require('schemastore').yaml.schemas()
        end,
    }
  '';

  xdg.configFile."nvim/snippets/go.lua".text = ''
    return {
        s('if err', {
            t({
                'if err != nil {',
                '\t' }), i(0), t({ ''',
            '}'
        }),
        }),

        s('if assign err', {
            t('if '), i(1, 'err'), t(' := '), i(2, 'expr'), t({ '; err != nil {',
            '\t' }), i(0), t({ ''',
            '}'
        }),
        }),

        s('iife', {
            t('func() '), i(1), t({ ' {',
            '\t' }), i(0), t({ ''',
            '}()'
        }),
        })
    }
  '';

  xdg.configFile."nvim/snippets/javascript.lua".text = ''
    local function computeSetter(args)
        local name = args[1][1]
        return 'set' .. name:sub(1, 1):upper() .. name:sub(2)
    end

    return {
        s('iife', {
            t({
                '(() => {',
                '  ' }), i(0), t({ ''',
                '})()'
            }),
        }),

        s('import statement', {
            t('import '), i(2, 'placeholder'), t(" from '"), i(1), t("';"),
        }),

        s('unpack variable', {
            t('const { '), i(2), t(' } = '), i(1), t(';'),
        }),

        s('use state', {
            t('const ['), i(1, 'state'), t(', '), f(computeSetter, { 1 }), t('] = useState('), i(2, 'value'), t(')')
        }),

        s('jsdoc', {
            t({
                '/**',
                ' * ' }), i(1), t({ ''',
                ' */',
        }),
        }),

        s('jsdoc type cast', {
            t({ '/** @type {' }), i(1), t('} */ ('), i(2), t(')'),
        }),

        s('sql tag', {
            t({
                '//@ts-ignore',
                'const sql = (strings, ...values) => String.raw({raw: strings}, ...values)'
            })
        })
    }
  '';

  xdg.configFile."nvim/snippets/typescript.lua".text = ''
    return {
        --stylua: ignore
        s('unpack argument', {
            t('{ '), i(0), t(' }: '), i(1),
        }),
    }
  '';

  xdg.configFile."nvim/snippets/vue.lua".text = ''
    return {
        s('vtemp', {
            t({
                '<script setup lang="ts">',
                '  ', }), i(0), t({ ''',
            '</script>',
            ''',
            '<template>',
            '  <div>',
            '  </div>',
            '</template>',
        }),
        }),

        s('define props', {
            t('const '), i(0, 'props'), t(' = defineProps<'), i(1), t('>()'),
        })
    }
  '';
}
