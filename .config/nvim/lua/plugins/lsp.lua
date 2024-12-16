-- nvim-cmp supports additional completion capabilities
local capabilities = require('cmp_nvim_lsp').default_capabilities()

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
    stylelint_lsp = {
        commands = {
            StylelintFixAll = {
                function() stylelint_fix_all({ sync = true, bufnr = 0 }) end,
                description = 'Fix all stylelint problems for this buffer'
            }
        }
    },
    eslint = {},
    biome = {},
    zls = {},
    hls = {},
}

-- Ensure the servers above are installed
require('mason').setup({ ui = { border = 'rounded' } })
require('mason-lspconfig').setup({ ensure_installed = vim.tbl_keys(servers) })

-- This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
    local nmap = function(keys, func, desc)
        if desc then desc = 'LSP: ' .. desc end
        vim.keymap.set({ 'n', 'v' }, keys, func, { buffer = bufnr, desc = desc })
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

function stylelint_fix_all(opts)
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

require('lspconfig.configs').vtsls = require('vtsls').lspconfig

for server_name in pairs(servers) do
    local server = servers[server_name] or {}
    server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
    server.on_attach = on_attach
    require('lspconfig')[server_name].setup(server)
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
