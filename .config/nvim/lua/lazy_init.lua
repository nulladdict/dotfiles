require('lazy').setup({
    {
        'lewis6991/gitsigns.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' }
    },
    'ybian/smartim',
    {
        'rose-pine/neovim',
        name = 'rose-pine',
    },
    'nvim-lualine/lualine.nvim',
    {
        'nmac427/guess-indent.nvim',
        opts = {},
    },
    {
        'tpope/vim-surround',
        dependencies = { 'tpope/vim-repeat' }
    },

    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate'
    },
    {
        'windwp/nvim-ts-autotag',
        opts = {}
    },
    {
        'echasnovski/mini.ai',
        opts = {
            n_lines = 500,
            silent = true,
        }
    },

    'williamboman/mason.nvim',
    'neovim/nvim-lspconfig',
    'stevearc/conform.nvim',
    {
        'folke/trouble.nvim',
        opts = { icons = false }
    },
    {
        'j-hui/fidget.nvim',
        opts = {},
    },

    {
        'L3MON4D3/LuaSnip',
        build = 'make install_jsregexp',
    },
    {
        'saghen/blink.cmp',
        version = '1.*',
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

            local function set_all(keymaps, rhs)
                for _, lhs in ipairs(keymaps) do
                    vim.keymap.set('i', lhs, rhs, { expr = true, replace_keycodes = false })
                end
            end
            set_all({ '<D-j>', '<D-о>' }, 'copilot#Accept("")')
            set_all({ '<D-k>', '<D-л>' }, 'copilot#AcceptWord("")')
            set_all({ '<D-l>', '<D-д>' }, 'copilot#Next()')
            set_all({ '<D-;>', '<D-ж>' }, 'copilot#Prev()')
            vim.api.nvim_create_autocmd('BufEnter', {
                pattern = { '*.env', '*.env.*' },
                callback = function() vim.b.copilot_enabled = false end
            })
            vim.g.copilot_workspace_folders = { vim.fn.getcwd() }
        end
    },

    'stevearc/oil.nvim',
    {
        'folke/snacks.nvim',
        opts = {
            styles = {
                input = {
                    relative = 'cursor',
                }
            },
            input = {},
            picker = {
                ui_select = true,
            }
        },
        keys = {
            { '<leader><space>', function() Snacks.picker.smart() end,                  desc = 'Smart Find Files' },
            { '<leader>sf',      function() Snacks.picker.files({ hidden = true }) end, desc = 'Find Files' },
            { '<leader>sg',      function() Snacks.picker.grep({ hidden = true }) end,  desc = 'Grep' },
            { '<leader>sh',      function() Snacks.picker.recent() end,                 desc = 'Recent' },
            { '<leader>sr',      function() Snacks.picker.resume() end,                 desc = 'Resume' },
            { '<leader>st',      function() Snacks.picker.git_status() end,             desc = 'Git Status' },
        },
    },
}, {
    ui = {
        border = 'rounded',
        icons = {
            cmd = '⌘',
            config = '🛠',
            event = '📅',
            ft = '📂',
            init = '⚙',
            keys = '🗝',
            plugin = '🔌',
            runtime = '💻',
            source = '📄',
            start = '🚀',
            task = '📌',
            lazy = '💤 '
        }
    }
})
