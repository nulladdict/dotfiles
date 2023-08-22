-- local eslint_d = require('efmls-configs.linters.eslint_d')
-- local stylelint = require('efmls-configs.linters.stylelint')
local prettier_d = require('efmls-configs.formatters.prettier_d')
local lua_format = require('efmls-configs.formatters.lua_format')
local rustfmt = require('efmls-configs.formatters.rustfmt')

local languages = {
    javascript = {prettier_d},
    javascriptreact = {prettier_d},
    typescript = {prettier_d},
    typescriptreact = {prettier_d},

    css = {prettier_d},
    scss = {prettier_d},
    less = {prettier_d},
    sass = {prettier_d},

    html = {prettier_d},

    lua = {lua_format},

    rust = {rustfmt}
}

local efmls_config = {
    filetypes = vim.tbl_keys(languages),
    settings = {rootMarkers = {'.git/', 'package.json'}, languages = languages},
    init_options = {documentFormatting = true, documentRangeFormatting = true}
}

require('lspconfig').efm.setup(vim.tbl_extend('force', efmls_config, {
    on_attach = function(_, bufnr)
        -- Create a command `:Format` local to the LSP buffer
        local function format()
            vim.lsp.buf.format({
                filter = function(client)
                    return client.name == 'efm'
                end,
                bufnr = bufnr
            })
        end
        for _, fmt_command in ipairs({'Format', 'Fmt'}) do
            vim.api.nvim_buf_create_user_command(bufnr, fmt_command, format, {
                desc = 'Format current buffer with LSP'
            })
        end
        vim.keymap.set({'n', 'v'}, '<leader>f', '<cmd>Fmt<CR>',
                       {noremap = true, silent = true})
    end
}))

vim.api.nvim_create_user_command('LuaFormat', '!lua-format -i %',
                                 {bang = true, nargs = 0})
vim.api.nvim_create_user_command('Prettier', '!npx prettier -w -u %',
                                 {bang = true, nargs = 0})
vim.api.nvim_create_user_command('Eslint', '!npx eslint --fix %',
                                 {bang = true, nargs = 0})
vim.api.nvim_create_user_command('Stylelint', '!npx stylelint --fix %',
                                 {bang = true, nargs = 0})
