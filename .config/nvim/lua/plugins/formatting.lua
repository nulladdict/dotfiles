return {
    {
        'stevearc/conform.nvim',
        config = function()
            local conform = require('conform')

            conform.setup({
                formatters_by_ft = {
                    javascript = { 'oxfmt' },
                    javascriptreact = { 'oxfmt' },
                    typescript = { 'oxfmt' },
                    typescriptreact = { 'oxfmt' },
                    css = { 'oxfmt' },
                    scss = { 'oxfmt' },
                    less = { 'oxfmt' },
                    sass = { 'oxfmt' },
                    html = { 'oxfmt' },
                    json = { 'oxfmt' },
                    markdown = { 'oxfmt' },
                    astro = { 'oxfmt' },
                    lua = { 'stylua' },
                    yaml = { 'oxfmt' },
                    sql = { 'sql_formatter' },
                    nix = { 'nixfmt' },
                    toml = { 'taplo' },
                    go = { 'gofmt' },
                },
            })

            vim.keymap.set({ 'n', 'v' }, '==', function()
                conform.format({ async = true, lsp_fallback = true })
            end, { noremap = true, silent = true })

            vim.g.zig_fmt_autosave = false

            vim.api.nvim_create_user_command('Prettier', function()
                conform.format({ async = true, formatters = { 'prettier' } })
            end, { nargs = 0 })
            vim.api.nvim_create_user_command('Biome', function()
                conform.format({ async = true, formatters = { 'biome' } })
            end, { nargs = 0 })
            vim.api.nvim_create_user_command('OxcLint', function()
                conform.format({ async = true, formatters = { 'oxlint' } })
            end, { nargs = 0 })
            vim.api.nvim_create_user_command('OxcFmt', function()
                conform.format({ async = true, formatters = { 'oxfmt' } })
            end, { nargs = 0 })
            vim.api.nvim_create_user_command('Eslint', function()
                conform.format({ async = true, formatters = { 'eslint_d' } })
            end, { nargs = 0 })
            vim.api.nvim_create_user_command('Stylelint', function()
                conform.format({ async = true, formatters = { 'stylelint' } })
            end, { nargs = 0 })
        end,
    },
}
