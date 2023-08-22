require('lazy').setup({
    {'lewis6991/gitsigns.nvim', dependencies = {'nvim-lua/plenary.nvim'}},
    'ybian/smartim',
    {'rose-pine/neovim', name = 'rose-pine'},
    'nvim-lualine/lualine.nvim',
    {
        'nmac427/guess-indent.nvim',
        config = function() require('guess-indent').setup() end
    },
    {
        'echasnovski/mini.pairs',
        config = function() require('mini.pairs').setup() end
    },
    {
        'echasnovski/mini.comment',
        config = function() require('mini.comment').setup() end
    },
    {'tpope/vim-surround', dependencies = {'tpope/vim-repeat'}},

    {'nvim-treesitter/nvim-treesitter', build = ':TSUpdate'},

    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
    {
        'creativenull/efmls-configs-nvim',
        dependencies = {'neovim/nvim-lspconfig'}
    },
    {
        'folke/trouble.nvim',
        config = function() require('trouble').setup {icons = false} end
    },
    {
        'j-hui/fidget.nvim',
        tag = 'legacy',
        config = function() require('fidget').setup() end
    },

    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline'
        }
    },
    'hrsh7th/cmp-vsnip',
    'hrsh7th/vim-vsnip',
    {
        'zbirenbaum/copilot.lua',
        cmd = 'Copilot',
        event = 'InsertEnter',
        config = function()
            require('copilot').setup({
                suggestion = {
                    auto_trigger = true,
                    debounce = 100,
                    keymap = {
                        accept = '<M-j>',
                        next = '<M-l>',
                        prev = false,
                        dismiss = '<M-;>'
                    }
                },
                panel = {keymap = {open = false}},
                filetypes = {
                    ['*'] = function()
                        if string.match(vim.fs.basename(vim.api
                                                            .nvim_buf_get_name(0)),
                                        '^%.env.*') then
                            -- disable for .env files
                            return false
                        end
                        return true
                    end
                }
            })
        end
    },

    {'nvim-telescope/telescope.nvim', dependencies = {'nvim-lua/plenary.nvim'}},
    {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = vim.fn.executable('make') == 1
    },
    'kyazdani42/nvim-tree.lua',
    {
        'stevearc/dressing.nvim',
        config = function() require('dressing').setup() end
    }
}, {
    ui = {
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
