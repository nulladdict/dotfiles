require('rose-pine').setup({
    styles = { italic = false, transparency = true },
    before_highlight = function(group, highlight)
        local no_bg = { 'MatchParen', "@comment.todo", "@comment.hint", "@comment.info", "@comment.note" }
        if vim.tbl_contains(no_bg, group) then
            highlight.bg = nil
            highlight.blend = nil
        end
    end,
})
vim.api.nvim_create_autocmd('ColorScheme', { pattern = '*', command = 'hi! link Sneak Search' })
vim.opt.background = 'dark'
vim.cmd('colorscheme rose-pine')
