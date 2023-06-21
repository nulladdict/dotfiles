-- nvim-cmp supports additional completion capabilities
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Enable the following language servers
local servers = {
    'astro', 'bashls', 'cssls', 'cssmodules_ls', 'dockerls', 'html', 'jsonls',
    'tailwindcss', 'tsserver', 'lua_ls', 'rust_analyzer', 'sqlls', 'svelte',
    'taplo', 'volar', 'yamlls', 'stylelint_lsp', 'eslint', 'zls'
}

-- Ensure the servers above are installed
require('mason').setup()
require('mason-lspconfig').setup {ensure_installed = servers}

-- This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
    local nmap = function(keys, func, desc)
        if desc then desc = 'LSP: ' .. desc end

        vim.keymap.set('n', keys, func, {buffer = bufnr, desc = desc})
    end

    local telescope = require('telescope.builtin')

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

    nmap('gd', telescope.lsp_definitions, '[G]oto [D]efinition')
    nmap('gi', telescope.lsp_implementations, '[G]oto [I]mplementation')
    nmap('gr', telescope.lsp_references)
    nmap('<leader>ds', telescope.lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', telescope.lsp_dynamic_workspace_symbols,
         '[W]orkspace [S]ymbols')

    nmap('gh', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('gH', vim.lsp.buf.signature_help, 'Signature Documentation')

    -- Lesser used LSP functionality
    nmap('<leader>D', telescope.lsp_type_definitions, 'Type [D]efinition')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder,
         '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder,
         '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')
end

for _, lsp in ipairs(servers) do
    local settings = {}
    if lsp == 'lua_ls' then
        settings.Lua = {diagnostics = {globals = {'vim'}}}
    end
    require('lspconfig')[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = settings
    }
end

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)
