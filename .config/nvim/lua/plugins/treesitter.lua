require('nvim-treesitter.configs').setup({
    ensure_installed = { 'astro', 'bash', 'c_sharp', 'comment', 'css', 'dockerfile', 'gitignore', 'html', 'javascript', 'jsdoc', 'json', 'json5', 'lua', 'markdown', 'markdown_inline', 'python', 'rust', 'scss', 'sql', 'svelte', 'toml', 'tsx', 'typescript', 'vim', 'vue', 'yaml', 'zig' },
    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true,
        disable = function(_, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
                return true
            end
        end,
        additional_vim_regex_highlighting = false,
    },
    indent = { enable = true },
    incremental_selection = { enable = false }
})

