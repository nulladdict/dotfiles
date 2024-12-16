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
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
    'yioneko/nvim-vtsls',
    {
        'folke/lazydev.nvim',
        opts = {}
    },
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
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'saadparwaiz1/cmp_luasnip',
        }
    },

    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make',
                cond = vim.fn.executable('make') == 1
            }
        }
    },
    'stevearc/oil.nvim',
    {
        'stevearc/dressing.nvim',
        opts = {},
    }
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
