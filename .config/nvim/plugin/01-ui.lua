if vim.g.vscode then
    return
end

vim.pack.add({ { src = 'https://github.com/rose-pine/neovim', name = 'rose-pine' } })
do
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
end

vim.pack.add({ 'https://github.com/nvim-lualine/lualine.nvim' })
do
    require('lualine').setup({
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
    })
end

vim.pack.add({ 'https://github.com/lewis6991/gitsigns.nvim' })
do
    require('gitsigns').setup({
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
    })
end

vim.pack.add({ 'https://github.com/folke/snacks.nvim' })
do
    require('snacks').setup({
        styles = {
            input = {
                relative = 'cursor',
            },
        },
        input = {},
        picker = {
            ui_select = true,
            previewers = {
                diff = { style = 'syntax' },
            },
        },
        notifier = {},
    })

    vim.keymap.set('n', '<leader><space>', function()
        require('snacks').picker.smart()
    end, { desc = 'Smart Find Files' })
    vim.keymap.set('n', '<leader>sf', function()
        require('snacks').picker.files({ hidden = true })
    end, { desc = 'Find Files' })
    vim.keymap.set('n', '<leader>sg', function()
        require('snacks').picker.grep({ hidden = true })
    end, { desc = 'Grep' })
    vim.keymap.set('n', '<leader>sh', function()
        require('snacks').picker.recent()
    end, { desc = 'Recent' })
    vim.keymap.set('n', '<leader>sr', function()
        require('snacks').picker.resume()
    end, { desc = 'Resume' })
    vim.keymap.set('n', '<leader>st', function()
        require('snacks').picker.git_status()
    end, { desc = 'Git Status' })
    vim.keymap.set('n', '<leader>sn', function()
        require('snacks').picker.notifications()
    end, { desc = 'Notification History' })
end
