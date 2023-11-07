require('rose-pine').setup({ disable_background = true, disable_italics = true })
vim.api.nvim_create_autocmd('ColorScheme',
                            { pattern = '*', command = 'hi! link Sneak Search' })
vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.cmd('colorscheme rose-pine')
