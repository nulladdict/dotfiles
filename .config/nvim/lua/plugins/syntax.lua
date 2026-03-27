return {
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        build = ':TSUpdate',
        branch = 'main',
        config = function()
            require('nvim-treesitter').install({ 'all' })
            vim.api.nvim_create_autocmd('FileType', {
                callback = function(args)
                    local buf, filetype = args.buf, args.match

                    local language = vim.treesitter.language.get_lang(filetype)
                    if not language then
                        return
                    end
                    if not vim.treesitter.language.add(language) then
                        return
                    end

                    vim.treesitter.start(buf, language)
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                    -- vim.wo.foldmethod = 'expr'
                    -- vim.wo.foldlevel = 99
                end,
            })
        end,
    },

    {
        'windwp/nvim-ts-autotag',
        opts = {},
    },

    {
        'echasnovski/mini.ai',
        opts = {
            n_lines = 500,
            silent = true,
        },
    },
}
