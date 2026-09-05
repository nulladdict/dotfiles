if vim.g.vscode then
    return
end

vim.pack.add({ 'https://github.com/nulladdict/blink-cmp-scss-vars' })

vim.pack.add({ { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') } })
do
    require('blink.cmp').setup({
        keymap = {
            preset = 'enter',
            ['<tab>'] = false,
        },
        completion = {
            documentation = { auto_show = true },
            accept = { auto_brackets = { enabled = false } },
            menu = { max_height = 16 },
        },
        sources = {
            default = {
                'lazydev',
                'lsp',
                'snippets',
                'path',
                'buffer',
                -- 'scss-vars',
                -- 'css-vars',
            },
            providers = {
                lazydev = {
                    name = 'LazyDev',
                    module = 'lazydev.integrations.blink',
                    score_offset = 100,
                },
                -- ['scss-vars'] = {
                --     name = 'scss-vars',
                --     module = 'scss-vars',
                --     opts = {
                --         include = {
                --             'node_modules/@skbkontur/colors/colors.scss',
                --             'packages/compass/src/styles/colors.scss',
                --             'packages/compass/src/styles/common.scss',
                --             'packages/compass/src/styles/mixins.scss',
                --         },
                --     },
                -- },
                -- ['css-vars'] = {
                --     name = 'css-vars',
                --     module = 'css-vars',
                --     opts = {
                --         include = {
                --             'node_modules/@skbkontur/colors/tokens/brand-blue_accent-gray.css',
                --         },
                --     },
                -- },
            },
        },
    })
end
