return {
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            {
                'mason-org/mason.nvim',
                opts = {},
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
                        'html-lsp',
                        'json-lsp',
                        'lua-language-server',
                        'sqlls',
                        'stylelint-lsp',
                        'tailwindcss-language-server',
                        'vtsls',
                        'yaml-language-server',

                        'stylua',
                        'sql-formatter',
                        'prettier',
                        -- 'nixfmt', managed by nix
                        'taplo',
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
                settings = {
                    vtsls = { autoUseWorkspaceTsdk = true },
                    typescript = { tsserver = { maxTsServerMemory = 8092 } },
                },
            })

            vim.lsp.enable({
                'astro',
                'bashls',
                'biome',
                'cssls',
                'cssmodules_ls',
                'dockerls',
                'eslint',
                'html',
                'jsonls',
                'lua_ls',
                'sqlls',
                'stylelint_lsp',
                'tailwindcss',
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
