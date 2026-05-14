if vim.g.vscode then
    return
end

vim.api.nvim_create_user_command('PackUpdate', function()
    vim.pack.update()
end, {})

vim.pack.add({ 'https://github.com/nvim-lua/plenary.nvim' })

vim.pack.add({ 'https://github.com/ybian/smartim' })

vim.pack.add({ 'https://github.com/nmac427/guess-indent.nvim' })
require('guess-indent').setup({})

vim.pack.add({ 'https://github.com/tpope/vim-repeat' })
vim.pack.add({ 'https://github.com/tpope/vim-surround' })

vim.pack.add({ 'https://github.com/mbbill/undotree' })
do
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.g.undotree_SplitWidth = 40
end
