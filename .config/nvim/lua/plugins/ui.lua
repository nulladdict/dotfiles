return {
    {
        'rose-pine/neovim',
        name = 'rose-pine',
        lazy = false,
        priority = 1000,
        config = function()
            require('rose-pine').setup({
                styles = { italic = false, transparency = true },
                before_highlight = function(group, highlight)
                    local no_bg = { 'MatchParen', '@comment.todo', '@comment.hint', '@comment.info', '@comment.note' }
                    if vim.tbl_contains(no_bg, group) then
                        highlight.bg = nil
                        highlight.blend = nil
                    end
                end,
            })
            vim.api.nvim_create_autocmd('ColorScheme', { pattern = '*', command = 'hi! link Sneak Search' })
            vim.opt.background = 'dark'
            vim.cmd('colorscheme rose-pine')
        end,
    },

    {
        'nvim-lualine/lualine.nvim',
        opts = {
            options = {
                icons_enabled = false,
                theme = 'rose-pine',
                component_separators = '|',
                section_separators = '',
            },
            sections = {
                lualine_c = {
                    { 'filename', path = 1 },
                },
            },
        },
    },

    {
        'lewis6991/gitsigns.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {
            signs = {
                add = { text = '+' },
                change = { text = '~' },
                delete = { text = '_' },
                topdelete = { text = '‾' },
                changedelete = { text = '~' },
            },
            on_attach = function(bufnr)
                local gitsigns = require('gitsigns')

                vim.keymap.set('n', ']c', function()
                    if vim.wo.diff then
                        vim.cmd.normal({ ']c', bang = true })
                    else
                        gitsigns.nav_hunk('next', { target = 'all' })
                    end
                end, { buffer = bufnr })

                vim.keymap.set('n', '[c', function()
                    if vim.wo.diff then
                        vim.cmd.normal({ '[c', bang = true })
                    else
                        gitsigns.nav_hunk('prev', { target = 'all' })
                    end
                end, { buffer = bufnr })
            end,
        },
    },

    {
        'folke/snacks.nvim',
        lazy = false,
        priority = 1000,
        opts = {
            styles = {
                input = {
                    relative = 'cursor',
                },
            },
            input = {},
            picker = { ui_select = true },
            notifier = {},
        },
        keys = {
            {
                '<leader><space>',
                function()
                    require('snacks').picker.smart()
                end,
                desc = 'Smart Find Files',
            },
            {
                '<leader>sf',
                function()
                    require('snacks').picker.files({ hidden = true })
                end,
                desc = 'Find Files',
            },
            {
                '<leader>sg',
                function()
                    require('snacks').picker.grep({ hidden = true })
                end,
                desc = 'Grep',
            },
            {
                '<leader>sh',
                function()
                    require('snacks').picker.recent()
                end,
                desc = 'Recent',
            },
            {
                '<leader>sr',
                function()
                    require('snacks').picker.resume()
                end,
                desc = 'Resume',
            },
            {
                '<leader>st',
                function()
                    require('snacks').picker.git_status()
                end,
                desc = 'Git Status',
            },
            {
                '<leader>sn',
                function()
                    require('snacks').picker.notifications()
                end,
                desc = 'Notification History',
            },
        },
    },
}
