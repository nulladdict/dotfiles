return {
    'ybian/smartim',

    {
        'nmac427/guess-indent.nvim',
        opts = {},
    },

    {
        'tpope/vim-surround',
        dependencies = { 'tpope/vim-repeat' }
    },

    {
        'mbbill/undotree',
        config = function()
            vim.g.undotree_SetFocusWhenToggle = 1
            vim.g.undotree_SplitWidth = 40
        end
    }
}
