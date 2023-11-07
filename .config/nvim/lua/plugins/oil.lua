require('oil').setup({
    skip_confirm_for_simple_edits = false,
    prompt_save_on_select_new_entry = true,
    cleanup_delay_ms = 2000,
    keymaps = {
        ['g?'] = 'actions.show_help',
        ['<CR>'] = 'actions.select',
        ['<C-v>'] = 'actions.select_vsplit',
        ['<C-x>'] = 'actions.select_split',
        ['<C-t>'] = 'actions.select_tab',
        ['<C-p>'] = 'actions.preview',
        ['<C-c>'] = 'actions.close',
        ['<C-l>'] = 'actions.refresh',
        ['-'] = 'actions.parent',
        ['_'] = 'actions.open_cwd',
        ['`'] = 'actions.cd',
        ['~'] = 'actions.tcd',
        ['gs'] = 'actions.change_sort',
        ['gx'] = 'actions.open_external',
        ['g.'] = 'actions.toggle_hidden',
        ['g\\'] = 'actions.toggle_trash'
    },
    use_default_keymaps = false,
    view_options = {
        show_hidden = true,
        is_always_hidden = function(name) return name == '.DS_Store' end
    }
})

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    pattern = 'oil:///*',
    callback = function()
        if vim.bo.filetype == 'oil' then
            vim.cmd.lcd(require('oil').get_current_dir())
        end
    end
})

vim.keymap.set('n', '<leader>bb', function()
    local oil = require('oil')
    if vim.bo.filetype == 'oil' then
        oil.close()
    else
        oil.open()
    end
end, { desc = 'Toggle [B]rowse' })
