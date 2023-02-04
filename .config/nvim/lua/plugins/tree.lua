require('nvim-tree').setup {
    open_on_tab = true,
    ignore_buf_on_tab_change = {'term'},
    update_focused_file = {enable = true},
    filters = {dotfiles = false},
    git = {ignore = false},
    renderer = {
        icons = {
            padding = ' ',
            symlink_arrow = '',
            show = {
                file = false,
                folder = false,
                folder_arrow = false,
                git = false
            }
        }
    },
    view = {mappings = {list = {{key = "<2-MiddleMouse>", action = "tabnew"}}}}
}

local function open_nvim_tree(data)
    -- buffer is a [No Name]
    local no_name = data.file == "" and vim.bo[data.buf].buftype == ""
    -- buffer is a directory
    local directory = vim.fn.isdirectory(data.file) == 1
    if not no_name and not directory then return end
    -- change to the directory
    if directory then vim.cmd.cd(data.file) end
    -- open the tree
    require("nvim-tree.api").tree.open()
end

vim.api.nvim_create_autocmd({"VimEnter"}, {callback = open_nvim_tree})

vim.keymap.set('n', '<leader>bf', require('nvim-tree.api').tree.focus,
               {desc = '[B]rowse [F]iles'})
vim.keymap.set('n', '<leader>bb', require('nvim-tree.api').tree.toggle,
               {desc = 'Toggle [B]rowse'})
vim.keymap.set('n', '<leader>ff', function() vim.cmd [[NvimTreeFindFile]] end,
               {desc = '[Find] [F]ile'})
