local opts = { noremap = true, silent = true }

-- Enable full mouse support
vim.opt.mouse = 'a'

-- Unmap Ex mode
vim.keymap.set('n', 'Q', '<nop>', opts)

-- Unmap man entry
vim.keymap.set({ 'n', 'v' }, 'K', '<nop>', opts)

-- Conventional saving
vim.keymap.set('n', '<D-s>', ':w<cr>', opts)
vim.keymap.set('i', '<D-s>', '<esc>:w<cr>', opts)

vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', opts)
vim.keymap.set({ 'n', 'v' }, '<leader>p', '"+p', opts)

-- Moving lines around
vim.keymap.set('n', '<C-j>', ':m .+1<CR>', opts)
vim.keymap.set('n', '<C-k>', ':m .-2<CR>', opts)
vim.keymap.set('i', '<C-j>', '<Esc>:m .+1<CR>gi', opts)
vim.keymap.set('i', '<C-k>', '<Esc>:m .-2<CR>gi', opts)
vim.keymap.set('v', '<C-j>', ":m '>+1<CR>gv", opts)
vim.keymap.set('v', '<C-k>', ":m '<-2<CR>gv", opts)

-- Search highlight
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<cr>')

-- Spell checking
if not vim.g.vscode then
    vim.opt.spell = true
    vim.opt.spelllang = 'ru_yo,en_us,en_gb'
    vim.opt.spelloptions = 'camel'
end

-- Terminal mode
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', opts)
vim.api.nvim_create_autocmd('TermOpen', { pattern = '*', command = 'startinsert' })
vim.api.nvim_create_autocmd('TermOpen', { pattern = '*', command = 'setlocal spell!' })

vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    desc = 'Force unix file format for git commit messages',
    pattern = 'gitcommit',
    callback = function()
        vim.schedule(function()
            vim.bo.fileformat = 'unix'
        end)
    end,
})
