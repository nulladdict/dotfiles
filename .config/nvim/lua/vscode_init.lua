local vscode = require('vscode-neovim')
vim.notify = vscode.notify

require('lazy').setup({
    'ybian/smartim',
})
