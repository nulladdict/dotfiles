return {
    {
        'saghen/blink.cmp',
        version = '1.*',
        dependencies = {
            {
                'L3MON4D3/LuaSnip',
                build = 'make install_jsregexp',
            },
        },
        config = function()
            require('blink.cmp').setup({
                keymap = { preset = 'enter' },
                completion = {
                    documentation = { auto_show = true },
                    accept = { auto_brackets = { enabled = false } },
                    menu = { max_height = 16 },
                },
                sources = { default = { 'lsp', 'snippets', 'path', 'buffer' } },
            })
        end,
    },

    {
        'github/copilot.vim',
        config = function()
            vim.g.copilot_settings = { selectedCompletionModel = 'gpt-4o-copilot' }
            vim.g.copilot_workspace_folders = { vim.fn.getcwd() }

            vim.keymap.set('i', '<D-j>', 'copilot#Accept("")', { expr = true, replace_keycodes = false })
            vim.keymap.set('i', '<D-о>', 'copilot#Accept("")', { expr = true, replace_keycodes = false })

            vim.api.nvim_create_autocmd('BufEnter', {
                pattern = { '*.env', '*.env.*' },
                callback = function() vim.b.copilot_enabled = false end
            })
        end
    },

}
