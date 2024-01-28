local palette = require('rose-pine.palette')
require('rose-pine').setup({
    styles = { italic = false },
    highlight_groups = {
        Normal = { fg = palette.text, bg = "NONE" },
        NormalNC = { fg = palette.text, bg = "NONE" },
    }
})
vim.api.nvim_create_autocmd('ColorScheme', { pattern = '*', command = 'hi! link Sneak Search' })
vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.cmd('colorscheme rose-pine')
