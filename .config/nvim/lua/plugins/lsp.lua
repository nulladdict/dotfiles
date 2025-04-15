require('mason').setup()

vim.lsp.config('lua_ls', {
    on_init = function(client)
        if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if path ~= vim.fn.stdpath('config') and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then
                return
            end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
                version = 'LuaJIT'
            },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                    '${3rd}/luv/library',
                }
            }
        })
    end,
    settings = {
        Lua = {}
    }
})
vim.lsp.config('vtsls', {
    settings = {
        vtsls = { autoUseWorkspaceTsdk = true },
        typescript = { tsserver = { maxTsServerMemory = 8092 } }
    }
})

vim.lsp.enable({
    'astro',
    'bashls',
    'biome',
    'cssls',
    'cssmodules_ls',
    'dockerls',
    'eslint',
    'gopls',
    'html',
    'jsonls',
    'lua_ls',
    'rust_analyzer',
    'sqlls',
    'stylelint_lsp',
    'svelte',
    'tailwindcss',
    'taplo',
    'vtsls',
    'yamlls',
    'zls',
})

-- https://neovim.io/doc/user/lsp.html#lsp-defaults
-- "grn" is mapped in Normal mode to vim.lsp.buf.rename()
-- "gra" is mapped in Normal and Visual mode to vim.lsp.buf.code_action()
-- "grr" is mapped in Normal mode to vim.lsp.buf.references()
-- "gri" is mapped in Normal mode to vim.lsp.buf.implementation()
-- "gO" is mapped in Normal mode to vim.lsp.buf.document_symbol()
-- CTRL-S is mapped in Insert mode to vim.lsp.buf.signature_help()
vim.keymap.del('n', 'grn')
vim.keymap.del({ 'n', 'v' }, 'gra')
vim.keymap.del('n', 'grr')
vim.keymap.del('n', 'gri')
vim.keymap.del('n', 'gO')
vim.keymap.del('i', '<C-S>')

-- Keymaps
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(event)
        local nmap = function(keys, func, desc)
            if desc then desc = 'LSP: ' .. desc end
            vim.keymap.set({ 'n', 'v' }, keys, func, { buffer = event.buf, desc = desc })
        end

        local snacks = require('snacks')

        nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

        nmap('gd', snacks.picker.lsp_definitions, '[G]oto [D]efinition')
        nmap('gD', snacks.picker.lsp_declarations, '[G]oto [D]eclaration')
        nmap('gy', snacks.picker.lsp_type_definitions, 'Type [D]efinition')
        nmap('gi', snacks.picker.lsp_implementations, '[G]oto [I]mplementation')
        nmap('gr', snacks.picker.lsp_references, '[G]oto [R]eferences')

        nmap('gh', vim.lsp.buf.hover, 'Hover Documentation')
        nmap('gH', vim.lsp.buf.signature_help, 'Signature Documentation')
    end
})

-- Diagnostic
vim.diagnostic.config({ virtual_text = true })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)
