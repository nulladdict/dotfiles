-- nvim-cmp supports additional completion capabilities
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Enable the following language servers
local servers = {
    'astro',
    'bashls',
    'csharp_ls',
    'cssls',
    'cssmodules_ls',
    -- 'denols',
    'dockerls',
    'html',
    'jsonls',
    'tsserver',
    'sumneko_lua',
    'marksman',
    -- 'remark_ls',
    'rust_analyzer',
    'sqlls',
    'svelte',
    'taplo',
    'volar',
    'yamlls'
}

-- Ensure the servers above are installed
require('mason').setup()
require('mason-lspconfig').setup {
    ensure_installed = servers,
}

-- This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
    local nmap = function(keys, func, desc)
        if desc then
            desc = 'LSP: ' .. desc
        end

        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    local telescope = require('telescope.builtin')

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

    nmap('gd', telescope.lsp_definitions, '[G]oto [D]efinition')
    nmap('gi', telescope.lsp_implementations, '[G]oto [I]mplementation')
    nmap('gr', telescope.lsp_references)
    nmap('<leader>ds', telescope.lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', telescope.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    nmap('gh', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('gH', vim.lsp.buf.signature_help, 'Signature Documentation')

    -- Lesser used LSP functionality
    nmap('<leader>D', telescope.lsp_type_definitions, 'Type [D]efinition')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

    -- Create a command `:Format` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Format', vim.lsp.buf.format or vim.lsp.buf.formatting,
        { desc = 'Format current buffer with LSP' })
end

for _, lsp in ipairs(servers) do
    require('lspconfig')[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
    }
end
