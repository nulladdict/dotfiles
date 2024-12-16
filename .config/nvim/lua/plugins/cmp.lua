local cmp = require('cmp')

local luasnip = require('luasnip')
luasnip.config.setup({})

cmp.setup({
    snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
    window = {
        completion = { border = 'rounded' },
        documentation = { border = 'rounded' },
    },
    formatting = {
        expandable_indicator = true,
        fields = { 'abbr', 'kind', 'menu' },
        format = function(_, vim_item)
            local original_menu = vim_item.menu or ''
            local truncated_menu = vim.fn.strcharpart(original_menu, 0, 50)
            if truncated_menu ~= original_menu then
                vim_item.menu = truncated_menu .. '…'
            end
            return vim_item
        end,
    },
    completion = { completeopt = 'menu,menuone,noinsert' },
    mapping = cmp.mapping.preset.insert({
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<Tab>'] = cmp.mapping.select_next_item({}),
        ['<S-Tab>'] = cmp.mapping.select_prev_item({}),
        ['<C-Space>'] = cmp.mapping.complete({}),
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
                luasnip.expand_or_jump()
            end
        end, { 'i', 's' }),
        ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
                luasnip.jump(-1)
            end
        end, { 'i', 's' }),
    }),
    sources = cmp.config.sources(
        { { name = 'nvim_lsp' }, { name = 'luasnip' } },
        { { name = 'buffer' }, { name = 'path' } }
    )
})

-- Use different sources for search
cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = { { name = 'buffer' } }
})
cmp.setup.cmdline('?', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = { { name = 'buffer' } }
})

-- Use cmdline & path source for ':'.
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({ { name = 'path' }, { name = 'cmdline' } })
})
