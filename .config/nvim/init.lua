local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
            { out, 'WarningMsg' },
            { '\nPress any key to exit...' },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Change leader to a space
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.keymap.set({ 'n', 'v' }, '<space>', '<nop>', { noremap = true, silent = true })

require('core/keymaps')
require('core/options')

if vim.g.vscode then
    local vscode = require('vscode-neovim')
    vim.notify = vscode.notify

    require('lazy').setup({
        spec = {
            'ybian/smartim',
            {
                'echasnovski/mini.ai',
                opts = {
                    n_lines = 500,
                    silent = true,
                },
            },
        },
    })

    local vscode_map = function(keys, action)
        vim.keymap.set('n', keys, function()
            vscode.action(action)
        end)
    end

    vscode_map('==', 'editor.action.format')

    vscode_map('<leader>rn', 'editor.action.rename')
    vscode_map('<leader>ca', 'editor.action.quickFix')

    vscode_map('gd', 'editor.action.revealDefinition')
    vscode_map('gD', 'editor.action.revealDeclaration')
    vscode_map('gy', 'editor.action.goToTypeDefinition')
    vscode_map('gi', 'editor.action.goToImplementation')
    vscode_map('gr', 'editor.action.goToReferences')

    vscode_map('gh', 'editor.action.showHover')

    vscode_map('<leader>sf', 'workbench.action.quickOpen')
    vscode_map('<leader>sg', 'workbench.action.findInFiles')

    vscode_map(']d', 'editor.action.marker.next')
    vscode_map('[d', 'editor.action.marker.prev')
else
    require('lazy').setup({
        rocks = {
            enabled = false,
        },
        spec = {
            { import = 'plugins' },
        },
        ui = {
            border = 'rounded',
        },
        install = {
            colorscheme = { 'rose-pine' },
        },
    })
end
