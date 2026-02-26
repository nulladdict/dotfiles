return {
    {
        'folke/lazydev.nvim',
        ft = 'lua',
        opts = {
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
            },
        },
    },
    {
        'seblyng/roslyn.nvim',
        opts = { filewatching = 'roslyn' },
    },
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            {
                'mason-org/mason.nvim',
                opts = {
                    registries = {
                        'github:mason-org/mason-registry',
                        'github:Crashdummyy/mason-registry',
                    },
                },
            },
            {
                'WhoIsSethDaniel/mason-tool-installer.nvim',
                opts = {
                    ensure_installed = {
                        'astro-language-server',
                        'bash-language-server',
                        'biome',
                        'css-lsp',
                        'cssmodules-language-server',
                        'dockerfile-language-server',
                        'eslint-lsp',
                        'gopls',
                        'html-lsp',
                        'json-lsp',
                        'lua-language-server',
                        'oxfmt',
                        'oxlint',
                        'prettier',
                        'sql-formatter',
                        'sqlls',
                        'stylelint-lsp',
                        'stylua',
                        'tailwindcss-language-server',
                        'taplo',
                        'tsgo',
                        'vtsls',
                        'yaml-language-server',
                    },
                },
            },
            { 'j-hui/fidget.nvim', opts = {} },
        },
        config = function()
            vim.lsp.config('lua_ls', {
                on_init = function(client)
                    if client.workspace_folders then
                        local path = client.workspace_folders[1].name
                        if
                            path ~= vim.fn.stdpath('config')
                            and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
                        then
                            return
                        end
                    end

                    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
                        runtime = {
                            version = 'LuaJIT',
                        },
                        workspace = {
                            checkThirdParty = false,
                            library = {
                                vim.env.VIMRUNTIME,
                                '${3rd}/luv/library',
                            },
                        },
                    })
                end,
                settings = {
                    Lua = {},
                },
            })

            vim.lsp.config('vtsls', {
                root_markers = { '.git' },
                settings = {
                    vtsls = { autoUseWorkspaceTsdk = true },
                    typescript = { tsserver = { maxTsServerMemory = 8092 } },
                },
            })

            vim.lsp.enable({
                'astro',
                'bashls',
                'biome',
                'css_variables',
                'cssls',
                'cssmodules_ls',
                'dockerls',
                'eslint',
                'gopls',
                'html',
                'jsonls',
                'lua_ls',
                'oxlint',
                'sqlls',
                'stylelint_lsp',
                'tailwindcss',
                -- 'tsgo',
                'vtsls',
                'yamlls',
            })

            -- Keymaps
            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(event)
                    if vim.bo[event.buf].filetype == 'copilot-chat' then
                        return
                    end

                    local snacks = require('snacks')
                    local lsp_map = function(keys, action, desc)
                        vim.keymap.set('n', keys, action, { buffer = event.buf, desc = desc })
                    end

                    -- https://neovim.io/doc/user/lsp.html#lsp-defaults
                    lsp_map('grr', snacks.picker.lsp_references, '[G]oto [R]eferences')
                    lsp_map('gri', snacks.picker.lsp_implementations, '[G]oto [I]mplementation')
                    lsp_map('grt', snacks.picker.lsp_type_definitions, 'Type [D]efinition')
                    lsp_map('gd', snacks.picker.lsp_definitions, '[G]oto [D]efinition')
                    lsp_map('gO', snacks.picker.lsp_symbols, '[G]oto [O]bjects')
                    lsp_map('gh', vim.lsp.buf.hover, '[H]over Documentation')
                end,
            })

            -- Diagnostic
            vim.diagnostic.config({ virtual_text = true })
            vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
            vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)
        end,
    },
}
