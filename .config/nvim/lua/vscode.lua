local vscode = require('vscode-neovim')
vim.notify = vscode.notify
vim.o.cmdheight = 1000

vim.pack.add({
    'https://github.com/ybian/smartim',
    'https://github.com/echasnovski/mini.ai',
})
require('mini.ai').setup({
    n_lines = 500,
    silent = true,
})

local vscode_map = function(keys, action)
    vim.keymap.set('n', keys, function()
        vscode.action(action)
    end)
end

vscode_map('==', 'editor.action.format')

vscode_map('grn', 'editor.action.rename')
vscode_map('gra', 'editor.action.quickFix')
vscode_map('grr', 'editor.action.goToReferences')
vscode_map('gri', 'editor.action.goToImplementation')
vscode_map('grt', 'editor.action.goToTypeDefinition')
vscode_map('gd', 'editor.action.revealDefinition')
vscode_map('gh', 'editor.action.showHover')

vscode_map('<leader>sf', 'workbench.action.quickOpen')
vscode_map('<leader>sg', 'workbench.action.findInFiles')

vscode_map(']d', 'editor.action.marker.next')
vscode_map('[d', 'editor.action.marker.prev')
