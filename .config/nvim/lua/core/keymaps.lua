local opts = { noremap = true, silent = true }

-- Enable full mouse support
vim.opt.mouse = 'a'

-- Unmap Ex mode
vim.keymap.set('n', 'Q', '<nop>', opts)

-- Unmap man entry
vim.keymap.set('n', 'K', '<nop>', opts)

-- Conventional saving
vim.keymap.set({ 'n', 'v' }, '<C-s>', ':w<cr>', opts)
vim.keymap.set('i', '<C-s>', '<esc>:w<cr>', opts)

-- Auto indent pasted text
vim.keymap.set('n', 'p', 'p=`]', opts)
vim.keymap.set('n', 'P', 'P=`]', opts)

vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', opts)

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
    -- vim.keymap.set('n', '<leader>ss', ':setlocal spell!<cr>', opts)
    vim.opt.spell = true
    vim.opt.spelllang = 'ru_yo,en_us,en_gb'
    vim.opt.spelloptions = 'camel'
end

-- Terminal mode
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', opts)
vim.api
    .nvim_create_autocmd('TermOpen', { pattern = '*', command = 'startinsert' })
vim.api.nvim_create_autocmd('TermOpen', { pattern = '*', command = 'setlocal spell!' })

-- Tab management
vim.keymap.set('n', '<leader>tt', ':tabnew<cr>', opts)
vim.keymap.set('n', '<leader>te', ':tabedit %<cr>', opts)
vim.keymap.set('n', '<leader>tw', ':tabclose<cr>', opts)

vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function() vim.highlight.on_yank() end,
})
