local telescope = require('telescope')

telescope.setup {
               defaults = { mappings = { i = { ['<C-u>'] = false, ['<C-d>'] = false } } }
}

-- Enable telescope fzf native, if installed
pcall(telescope.load_extension, 'fzf')
pcall(telescope.load_extension, 'neoclip')

-- See `:help telescope.builtin`
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>?', builtin.oldfiles,
               { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', builtin.buffers,
               { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find,
               { desc = '[/] Fuzzily search in current buffer]' })

vim.keymap.set('n', '<leader>sf', builtin.find_files,
               { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string,
               { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep,
               { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics,
               { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>st', builtin.git_status,
               { desc = '[S]earch git s[T]atus' })

vim.keymap.set('n', '[q', ':cprevious<CR>',
               { desc = 'Go to previous quickfix item', silent = true })
vim.keymap.set('n', ']q', ':cnext<CR>',
               { desc = 'Go to next quickfix item', silent = true })
