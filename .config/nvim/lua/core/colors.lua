require('rose-pine').setup({
    styles = { italic = false, transparency = true, },
})
vim.api.nvim_create_autocmd('ColorScheme', { pattern = '*', command = 'hi! link Sneak Search' })
vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.cmd('colorscheme rose-pine')
