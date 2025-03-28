-- Enable the following language servers
local servers = {
    astro = {},
    bashls = {},
    cssls = {},
    cssmodules_ls = {},
    dockerls = {},
    html = {},
    jsonls = {},
    tailwindcss = {},
    vtsls = {
        settings = {
            vtsls = { autoUseWorkspaceTsdk = true },
            typescript = { tsserver = { maxTsServerMemory = 8092 } }
        }
    },
    lua_ls = {},
    rust_analyzer = {},
    sqlls = {},
    svelte = {},
    taplo = {},
    volar = {},
    yamlls = {},
    stylelint_lsp = {},
    eslint = {},
    biome = {},
    zls = {},
    hls = {},
}

-- Ensure the servers above are installed
require('mason').setup({ ui = { border = 'rounded' } })
require('mason-lspconfig').setup({ ensure_installed = vim.tbl_keys(servers) })

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(event)
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

        local nmap = function(keys, func, desc)
            if desc then desc = 'LSP: ' .. desc end
            vim.keymap.set({ 'n', 'v' }, keys, func, { buffer = event.buf, desc = desc })
        end

        local telescope = require('telescope.builtin')

        nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

        nmap('gd', telescope.lsp_definitions, '[G]oto [D]efinition')
        nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        nmap('gy', telescope.lsp_type_definitions, 'Type [D]efinition')
        nmap('gi', telescope.lsp_implementations, '[G]oto [I]mplementation')
        nmap('gr', telescope.lsp_references)

        nmap('gh', vim.lsp.buf.hover, 'Hover Documentation')
        nmap('gH', vim.lsp.buf.signature_help, 'Signature Documentation')
    end
})

require('lspconfig.configs').vtsls = require('vtsls').lspconfig

for server_name in pairs(servers) do
    local server = servers[server_name] or {}
    server.capabilities =
        require('blink.cmp').get_lsp_capabilities(server.capabilities or {})
    require('lspconfig')[server_name].setup(server)
end

-- Diagnostic keymaps
vim.diagnostic.config({ virtual_text = true })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)
