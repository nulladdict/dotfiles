local telescope = require('telescope')

telescope.setup({
    defaults = {
        mappings = {
            i = {
                ['<C-u>'] = false,
                ['<C-d>'] = false
            }
        },
    },
    pickers = {
        find_files = { hidden = true },
        grep_string = {
            additional_args = { "--hidden" }
        },
        live_grep = {
            additional_args = { "--hidden" }
        },
    },
})

-- Enable telescope fzf native, if installed
pcall(telescope.load_extension, 'fzf')

-- See `:help telescope.builtin`
local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader><space>', builtin.buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = '[/] Fuzzily search in current buffer' })

vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>st', builtin.git_status, { desc = '[S]earch git s[T]atus' })
vim.keymap.set('n', '<leader>sh', builtin.oldfiles, { desc = '[S]earch recent [H]istory' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })

-- https://github.com/nvim-telescope/telescope.nvim/issues/3436
vim.api.nvim_create_autocmd('User', {
    pattern = 'TelescopeFindPre',
    callback = function()
        vim.opt_local.winborder = 'none'
        vim.api.nvim_create_autocmd('WinLeave', {
            once = true,
            callback = function()
                vim.opt_local.winborder = 'rounded'
            end,
        })
    end,
})
