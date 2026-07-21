if vim.g.vscode then
    return
end

vim.pack.add({ 'https://github.com/nulladdict/blink-cmp-scss-vars' })

vim.pack.add({ { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') } })
do
    require('blink.cmp').setup({
        keymap = {
            preset = 'enter',
            ['<tab>'] = false,
        },
        completion = {
            documentation = { auto_show = true },
            accept = { auto_brackets = { enabled = false } },
            menu = { max_height = 16 },
        },
        sources = {
            default = {
                'lazydev',
                'lsp',
                'snippets',
                'path',
                'buffer',
                'scss-vars',
                'css-vars',
            },
            providers = {
                lazydev = {
                    name = 'LazyDev',
                    module = 'lazydev.integrations.blink',
                    score_offset = 100,
                },
                ['scss-vars'] = {
                    name = 'scss-vars',
                    module = 'scss-vars',
                    opts = {
                        include = {
                            'node_modules/@skbkontur/colors/colors.scss',
                            'packages/compass/src/styles/colors.scss',
                            'packages/compass/src/styles/common.scss',
                            'packages/compass/src/styles/mixins.scss',
                        },
                    },
                },
                ['css-vars'] = {
                    name = 'css-vars',
                    module = 'css-vars',
                    opts = {
                        include = {
                            'node_modules/@skbkontur/colors/tokens/brand-blue_accent-gray.css',
                        },
                    },
                },
            },
        },
    })
end

vim.pack.add({ 'https://github.com/github/copilot.vim' })
do
    vim.g.copilot_workspace_folders = { vim.fn.getcwd() }
    vim.g.copilot_version = 'latest'

    local function appy_suggestion()
        local suggestion = vim.fn['copilot#GetDisplayedSuggestion']()
        if suggestion.text ~= nil and suggestion.text ~= '' then
            return vim.fn['copilot#Accept']('')
        end
        return ''
    end
    local function clear_suggestion()
        vim.fn['copilot#Dismiss']()
    end

    vim.keymap.set({ 'i', 'n' }, '<D-j>', appy_suggestion, { expr = true, replace_keycodes = false })
    vim.keymap.set({ 'i', 'n' }, '<D-о>', appy_suggestion, { expr = true, replace_keycodes = false })
    vim.keymap.set({ 'i', 'n' }, '<D-l>', clear_suggestion, { silent = true })
    vim.keymap.set({ 'i', 'n' }, '<D-д>', clear_suggestion, { silent = true })

    vim.api.nvim_create_autocmd('BufEnter', {
        pattern = { '*.env', '*.env.*' },
        callback = function()
            vim.b.copilot_enabled = false
        end,
    })
end
