return {
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        lazy = false,
        priority = 1000,
        config = function()
            require('nvim-treesitter.configs').setup({
                modules = {},
                ensure_installed = {},
                ignore_install = {},
                sync_install = false,
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = { enable = true },
                incremental_selection = { enable = false }
            })
        end
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
}
