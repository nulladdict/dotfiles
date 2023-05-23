local null_ls = require("null-ls")

null_ls.setup({
    sources = {
        null_ls.builtins.code_actions.eslint_d,

        null_ls.builtins.diagnostics.eslint_d,
        -- null_ls.builtins.diagnostics.markdownlint,
        null_ls.builtins.diagnostics.stylelint,
        null_ls.builtins.diagnostics.tsc,

        null_ls.builtins.formatting.lua_format,
        null_ls.builtins.formatting.prettierd,
        null_ls.builtins.formatting.sqlformat,
        null_ls.builtins.formatting.rustfmt
    },
    on_attach = function(_, bufnr)
        -- Create a command `:Format` local to the LSP buffer
        local function format()
            vim.lsp.buf.format({
                filter = function(client)
                    return client.name == 'null-ls'
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
})

vim.api.nvim_create_user_command('Eslint', '!npx eslint --fix %',
                                 {bang = true, nargs = 0})
vim.api.nvim_create_user_command('Stylelint', '!npx stylelint --fix %',
                                 {bang = true, nargs = 0})
