vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.keymap.set({ 'n', 'v' }, '<space>', '<nop>', { noremap = true, silent = true })

require('keymaps')
require('options')

if vim.g.vscode then
    require('vs_code')
end
