return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    use {'lewis6991/gitsigns.nvim', requires = {'nvim-lua/plenary.nvim'}}
    use 'ybian/smartim'
    use {'rose-pine/neovim', as = 'rose-pine'}
    use 'nvim-lualine/lualine.nvim'
    use {
        'nmac427/guess-indent.nvim',
        config = function() require('guess-indent').setup() end
    }
    use {
        'windwp/nvim-autopairs',
        config = function() require('nvim-autopairs').setup() end
    }
    use {
        'numToStr/Comment.nvim',
        config = function() require('Comment').setup() end
    }
    use 'tpope/vim-repeat'
    use 'tpope/vim-surround'
    use 'justinmk/vim-sneak'

    use {
        'nvim-treesitter/nvim-treesitter',
        run = function()
            require('nvim-treesitter.install').update({with_sync = true})
        end
    }

    use 'williamboman/mason.nvim'
    use 'williamboman/mason-lspconfig.nvim'
    use 'neovim/nvim-lspconfig'
    use {
        'jose-elias-alvarez/null-ls.nvim',
        requires = {'nvim-lua/plenary.nvim'}
    }
    use 'MunifTanjim/prettier.nvim'
    use {
        'folke/trouble.nvim',
        config = function() require('trouble').setup {icons = false} end
    }
    use {'j-hui/fidget.nvim', config = function() require('fidget').setup() end}

    use {
        'hrsh7th/nvim-cmp',
        requires = {
            'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline'
        }
    }
    use 'hrsh7th/cmp-vsnip'
    use 'hrsh7th/vim-vsnip'
    use {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        config = function()
            require("copilot").setup({
                suggestion = {
                    auto_trigger = true,
                    debounce = 100,
                    keymap = {
                        accept = "<M-j>",
                        next = "<M-l>",
                        prev = false,
                        dismiss = "<M-;>"
                    }
                },
                panel = {keymap = {open = false}},
                filetypes = {
                    ["*"] = function()
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
    }

    use {'nvim-telescope/telescope.nvim', requires = {'nvim-lua/plenary.nvim'}}
    use {
        'nvim-telescope/telescope-fzf-native.nvim',
        run = 'make',
        cond = vim.fn.executable('make') == 1
    }
    use {
        'AckslD/nvim-neoclip.lua',
        config = function() require('neoclip').setup() end
    }
    use 'kyazdani42/nvim-tree.lua'
    use 'folke/zen-mode.nvim'
end)
