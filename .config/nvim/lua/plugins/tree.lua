require('nvim-tree').setup {
    open_on_setup = true,
    -- open_on_setup_file = true,
    open_on_tab = true,
    ignore_buf_on_tab_change = { 'term' },
    renderer = {
        icons = {
            padding = ' ',
            symlink_arrow = '',
            show = {
                file = false,
                folder = false,
                folder_arrow = false,
                git = false,
            },
        }
    }
}

vim.keymap.set('n', '<leader>bf', require('nvim-tree.api').tree.focus, { desc = '[B]rowse [F]iles' })
vim.keymap.set('n', '<leader>bb', require('nvim-tree.api').tree.toggle, { desc = 'Toggle [B]rowse' })
vim.keymap.set('n', '<leader>ff', function() vim.cmd [[NvimTreeFindFile]] end, { desc = '[Find] [F]ile' })
