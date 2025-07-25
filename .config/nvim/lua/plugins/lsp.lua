-- https://neovim.io/doc/user/lsp.html#lsp-defaults
-- "grn" is mapped in Normal mode to vim.lsp.buf.rename()
-- "gra" is mapped in Normal and Visual mode to vim.lsp.buf.code_action()
-- "grr" is mapped in Normal mode to vim.lsp.buf.references()
-- "gri" is mapped in Normal mode to vim.lsp.buf.implementation()
-- "grt" is mapped in Normal mode to vim.lsp.buf.type_definition()
-- "gO" is mapped in Normal mode to vim.lsp.buf.document_symbol()
-- CTRL-S is mapped in Insert mode to vim.lsp.buf.signature_help()
pcall(vim.keymap.del, 'n', 'grn')
pcall(vim.keymap.del, { 'n', 'v' }, 'gra')
pcall(vim.keymap.del, 'n', 'grr')
pcall(vim.keymap.del, 'n', 'gri')
pcall(vim.keymap.del, 'n', 'grt')
pcall(vim.keymap.del, 'n', 'gO')
pcall(vim.keymap.del, 'i', '<C-S>')

return {
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            {
                'mason-org/mason.nvim',
                opts = {
                    ui = {
                        border = 'rounded',
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
                -- 'eslint',
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

                    lsp_map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
                    lsp_map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

                    lsp_map('gd', snacks.picker.lsp_definitions, '[G]oto [D]efinition')
                    lsp_map('gD', snacks.picker.lsp_declarations, '[G]oto [D]eclaration')
                    lsp_map('gy', snacks.picker.lsp_type_definitions, 'Type [D]efinition')
                    lsp_map('gi', snacks.picker.lsp_implementations, '[G]oto [I]mplementation')
                    lsp_map('gr', snacks.picker.lsp_references, '[G]oto [R]eferences')

                    lsp_map('gh', vim.lsp.buf.hover, 'Hover Documentation')
                    lsp_map('gH', vim.lsp.buf.signature_help, 'Signature Documentation')
                end,
            })

            -- Diagnostic
            vim.diagnostic.config({ virtual_text = true })
            vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
            vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)
        end,
    },
}
