local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath
    })
end
vim.opt.rtp:prepend(lazypath)

-- Change leader to a space
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.keymap.set({'n', 'v'}, '<space>', '<nop>', {noremap = true, silent = true})

require('lazy_init')
-- Core settings and functionality
require('core/colors')
require('core/keymaps')
require('core/options')
-- Plugin settings
require('plugins/cmp')
require('plugins/conform')
require('plugins/gitsings')
require('plugins/lsp')
require('plugins/lualine')
require('plugins/oil')
require('plugins/telescope')
require('plugins/treesitter')
