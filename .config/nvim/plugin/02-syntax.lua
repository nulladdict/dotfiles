if vim.g.vscode then
    return
end

vim.pack.add({ { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' } })
do
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
end

vim.pack.add({ 'https://github.com/windwp/nvim-ts-autotag' })
do
    require('nvim-ts-autotag').setup({})
end

vim.pack.add({ 'https://github.com/echasnovski/mini.ai' })
do
    require('mini.ai').setup({
        n_lines = 500,
        silent = true,
    })
end
