-- nvim-cmp supports additional completion capabilities
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Enable the following language servers
local servers = {
    'astro',
    'bashls',
    'cssls',
    'cssmodules_ls',
    'dockerls',
    'html',
    'jsonls',
    'tailwindcss',
    'tsserver',
    'lua_ls',
    'rust_analyzer',
    'sqlls',
    'svelte',
    'taplo',
    'volar',
    'yamlls',
    'stylelint_lsp',
    'eslint',
    'zls',
    'hls',
}

-- Ensure the servers above are installed
require('mason').setup({ ui = { border = 'rounded' } })
require('mason-lspconfig').setup({ ensure_installed = servers })
require('neodev').setup({})

-- This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
    local nmap = function(keys, func, desc)
        if desc then desc = 'LSP: ' .. desc end
        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    local telescope = require('telescope.builtin')

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

    nmap('gd', telescope.lsp_definitions, '[G]oto [D]efinition')
    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('gi', telescope.lsp_implementations, '[G]oto [I]mplementation')
    nmap('gr', telescope.lsp_references)
    nmap('<leader>ds', telescope.lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', telescope.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    nmap('gh', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('gH', vim.lsp.buf.signature_help, 'Signature Documentation')

    nmap('<leader>D', telescope.lsp_type_definitions, 'Type [D]efinition')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
        '[W]orkspace [L]ist Folders')
end

local function fix_all(opts)
    local util = require('lspconfig.util')
    opts = opts or { sync = true, bufnr = 0 }
    local bufnr = util.validate_bufnr(opts.bufnr or 0)

    local stylelint_lsp_client = util.get_active_client_by_name(bufnr, 'stylelint_lsp')
    if stylelint_lsp_client == nil then return end

    local request
    if opts.sync then
        request = function(buf, method, params)
            stylelint_lsp_client.request_sync(method, params, nil, buf)
        end
    else
        request = function(buf, method, params)
            stylelint_lsp_client.request(method, params, nil, buf)
        end
    end

    request(bufnr, 'workspace/executeCommand', {
        command = 'stylelint.applyAutoFixes',
        arguments = {
            {
                uri = vim.uri_from_bufnr(bufnr),
                version = vim.lsp.util.buf_versions[bufnr]
            }
        }
    })
end

vim.g.zig_fmt_autosave = false

for _, lsp in ipairs(servers) do
    local settings = {}
    local commands = {}
    if lsp == 'stylelint_lsp' then
        commands.StylelintFixAll = {
            function() fix_all { sync = true, bufnr = 0 } end,
            description = 'Fix all stylelint problems for this buffer'
        }
    end
    require('lspconfig')[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = settings,
        commands = commands
    }
end

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- Rounded borders for previews
local util_preview = vim.lsp.util.open_floating_preview
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or 'rounded'
    return util_preview(contents, syntax, opts, ...)
end
