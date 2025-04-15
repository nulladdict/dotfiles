local vscode = require('vscode-neovim')
vim.notify = vscode.notify

require('lazy').setup({
    'ybian/smartim',
})

local nmap = function(keys, action)
    vim.keymap.set({ 'n', 'v' }, keys, function()
        if vim.fn.mode() == 'n' then
            vscode.action(action)
        else
            vscode.with_insert(function()
                vscode.action(action)
            end)
        end
    end)
end

nmap('==', 'editor.action.format')

nmap('<leader>rn', 'editor.action.rename')
nmap('<leader>ca', 'editor.action.quickFix')

nmap('gd', 'editor.action.revealDefinition')
nmap('gD', 'editor.action.revealDeclaration')
nmap('gy', 'editor.action.goToTypeDefinition')
nmap('gi', 'editor.action.goToImplementation')
nmap('gr', 'editor.action.goToReferences')

nmap('gh', 'editor.action.showHover')

nmap('<leader>sf', 'workbench.action.quickOpen')
nmap('<leader>sg', 'workbench.action.findInFiles')
