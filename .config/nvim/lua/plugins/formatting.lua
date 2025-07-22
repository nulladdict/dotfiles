return {
    {
        'stevearc/conform.nvim',
        config = function()
            local conform = require('conform')

            conform.setup({
                formatters_by_ft = {
                    javascript = { 'biome' },
                    javascriptreact = { 'biome' },
                    typescript = { 'biome' },
                    typescriptreact = { 'biome' },
                    css = { 'prettier' },
                    scss = { 'prettier' },
                    less = { 'prettier' },
                    sass = { 'prettier' },
                    html = { 'prettier' },
                    json = { 'biome' },
                    markdown = { 'prettier' },
                    astro = { 'prettier' },
                    lua = { 'stylua' },
                    rust = { 'rustfmt' },
                    zig = { 'zigfmt' },
                    haskell = { 'fourmolu' },
                    yaml = { 'prettier' },
                    sql = { 'sql_formatter' },
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
            vim.api.nvim_create_user_command('Eslint', function()
                conform.format({ async = true, formatters = { 'eslint_d' } })
            end, { nargs = 0 })
            vim.api.nvim_create_user_command('Stylelint', function()
                conform.format({ async = true, formatters = { 'stylelint' } })
            end, { nargs = 0 })
        end
    }
}
