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
                    default = { 'lsp', 'snippets', 'path', 'buffer' },
                },
            })
        end,
    },

    {
        'github/copilot.vim',
        config = function()
            vim.g.copilot_workspace_folders = { vim.fn.getcwd() }
            vim.g.copilot_filetypes = { ['copilot-chat'] = false }

            vim.keymap.set('i', '<D-j>', 'copilot#Accept("")', { expr = true, replace_keycodes = false })
            vim.keymap.set('i', '<D-о>', 'copilot#Accept("")', { expr = true, replace_keycodes = false })

            vim.api.nvim_create_autocmd('BufEnter', {
                pattern = { '*.env', '*.env.*' },
                callback = function()
                    vim.b.copilot_enabled = false
                end,
            })
        end,
    },

    {
        'olimorris/codecompanion.nvim',
        opts = {
            extensions = {
                mcphub = {
                    callback = 'mcphub.extensions.codecompanion',
                    opts = {
                        make_vars = true,
                        make_slash_commands = true,
                        show_result_in_chat = true,
                    },
                },
            },
            strategies = {
                chat = {
                    name = 'copilot',
                    model = 'gpt-5-mini',
                },
                inline = {
                    name = 'copilot',
                    model = 'gpt-5-mini',
                },
            },
        },
        config = function(_, opts)
            require('codecompanion').setup(opts)
            vim.keymap.set('n', '<D-k>', '<cmd>CodeCompanionChat Toggle<cr>', { noremap = true, silent = true })
            vim.keymap.set('v', '<D-i>', '<cmd>CodeCompanion<cr>', { noremap = true, silent = true })
            vim.keymap.set('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', { noremap = true, silent = true })
            vim.cmd([[cab cc CodeCompanion]])
        end,
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
            'ravitemer/mcphub.nvim',
            {
                'echasnovski/mini.diff',
                config = function()
                    local diff = require('mini.diff')
                    diff.setup({
                        -- Disabled by default
                        source = diff.gen_source.none(),
                    })
                end,
            },
        },
    },
}
