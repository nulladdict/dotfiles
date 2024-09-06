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
        'github/copilot.vim',
        -- enabled = false,
        event = 'VeryLazy',
        config = function()
            vim.g.copilot_no_mappings = true
            vim.keymap.set('i', '<M-j>', 'copilot#Accept("")', { expr = true, replace_keycodes = false })
            vim.keymap.set('i', '<M-k>', 'copilot#AcceptWord("")', { expr = true, replace_keycodes = false })
            vim.keymap.set('i', '<M-l>', 'copilot#Next()', { expr = true, replace_keycodes = false })
            vim.keymap.set('i', '<M-;>', 'copilot#Dismiss()', { expr = true, replace_keycodes = false })
            vim.api.nvim_create_autocmd('BufEnter', {
                pattern = { '*.env', '*.env.*' },
                callback = function() vim.b.copilot_enabled = false end
            })
            vim.g.copilot_workspace_folders = { vim.fn.getcwd() }
        end
    },
    {
        'huggingface/llm.nvim',
        enabled = false,
        opts = {
            backend = 'openai',
            url = 'http://code-llama-70b.kontur.host',
            fim = {
                enabled = true,
                prefix = "<PRE> ",
                middle = " <MID>",
                suffix = " <SUF>",
            },
            model = 'CodeLlama-70B-Instruct-GPTQ',
            context_window = 4096,
            tokenizer = { repository = 'TheBloke/CodeLlama-70B-Instruct-GPTQ' },
            accept_keymap = '<M-j>',
            dismiss_keymap = '<M-;>',
            enable_suggestions_on_startup = true,
            enable_suggestions_on_files = { '*.ts', '*.tsx', '*.lua' },
            lsp = {
                bin_path = vim.api.nvim_call_function('stdpath', { 'data' }) .. '/mason/bin/llm-ls',
                cmd_env = { LLM_LOG_LEVEL = 'DEBUG' },
            },
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
