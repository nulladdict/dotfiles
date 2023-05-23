require('nvim-treesitter.configs').setup {
    -- Add languages to be installed here that you want installed for treesitter
    ensure_installed = {
        'astro', 'bash', 'c_sharp', 'comment', 'css', 'dockerfile', 'gitignore',
        'html', 'javascript', 'jsdoc', 'json', 'json5', 'lua', 'markdown',
        'markdown_inline', 'python', 'rust', 'scss', 'sql', 'svelte', 'toml',
        'tsx', 'typescript', 'vim', 'vue', 'yaml', 'zig'
    },
    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,
    -- Automatically install missing parsers when entering buffer
    auto_install = true,
    highlight = {enable = true},
    indent = {enable = true}
}
