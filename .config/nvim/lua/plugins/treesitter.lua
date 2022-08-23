require('nvim-treesitter.configs').setup {
    -- Add languages to be installed here that you want installed for treesitter
    ensure_installed = {
        'astro',
        'bash',
        'c_sharp',
        'comment',
        'css',
        'dockerfile',
        'gitignore',
        'html',
        'javascript',
        'jsdoc',
        'json',
        'json5',
        'lua',
        'markdown',
        'markdown_inline',
        'python',
        'rust',
        'scss',
        'sql',
        'svelte',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vue',
        'yaml',
    },
    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,
    -- Automatically install missing parsers when entering buffer
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
}

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)
