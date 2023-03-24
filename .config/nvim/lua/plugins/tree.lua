require('nvim-tree').setup {
    update_focused_file = {enable = true},
    filters = {dotfiles = false},
    git = {ignore = false},
    renderer = {
        indent_width = 1,
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
    view = {
        width = 32,
        mappings = {list = {{key = "<2-MiddleMouse>", action = "tabnew"}}}
    },
    actions = {open_file = {quit_on_open = true}}
}

local function open_nvim_tree(data)
    -- buffer is a [No Name]
    local no_name = data.file == "" and vim.bo[data.buf].buftype == ""
    -- buffer is a directory
    local directory = vim.fn.isdirectory(data.file) == 1
    if not no_name and not directory then return end
    -- change to the directory
    if directory then vim.cmd.cd(data.file) end
end

vim.api.nvim_create_autocmd({"VimEnter"}, {callback = open_nvim_tree})

vim.keymap.set('n', '<leader>bb', require('nvim-tree.api').tree.toggle,
               {desc = 'Toggle [B]rowse'})
