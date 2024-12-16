local vscode = require('vscode-neovim')
vim.notify = vscode.notify

require('lazy').setup({
    'ybian/smartim',
})

local nmap = function(keys, action)
    local func = function()
        vscode.with_insert(function()
            vscode.action(action)
        end)
    end
    vim.keymap.set({ 'n', 'v' }, keys, func)
end

nmap('==', 'editor.action.format')

nmap('<leader>rn', 'editor.action.rename')
nmap('<leader>ca', 'editor.action.quickFix')

nmap('gd', 'editor.action.revealDefinition')
nmap('gD', 'editor.action.revealDeclaration')
nmap('gy', 'editor.action.goToTypeDefinition')
nmap('gi', 'editor.action.goToImplementation')
nmap('gr', 'editor.action.goToReferences')
-- editor.action.referenceSearch.trigger

nmap('gh', 'editor.action.showHover')

nmap('<leader>sf', 'workbench.action.quickOpen')
nmap('<leader>sg', 'workbench.action.findInFiles')
