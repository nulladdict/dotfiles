local null_ls = require("null-ls")

null_ls.setup({
    sources = {
        -- null_ls.builtins.code_actions.eslint_d,

        -- null_ls.builtins.diagnostics.eslint_d,
        -- null_ls.builtins.diagnostics.markdownlint,
        null_ls.builtins.diagnostics.stylelint,
        null_ls.builtins.diagnostics.tsc,

        null_ls.builtins.formatting.lua_format,
        null_ls.builtins.formatting.prettierd,
        null_ls.builtins.formatting.sqlformat,
        null_ls.builtins.formatting.rustfmt
    }
})
