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
            },
        },
    })
end

vim.pack.add({ 'https://github.com/github/copilot.vim' })
do
    vim.g.copilot_workspace_folders = { vim.fn.getcwd() }
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_version = 'latest'

    local function appy_suggestion(fallback)
        return function()
            if require('sidekick').nes_jump_or_apply() then
                return
            end
            local suggestion = vim.fn['copilot#GetDisplayedSuggestion']()
            if suggestion.text ~= nil and suggestion.text ~= '' then
                return vim.fn['copilot#Accept'](fallback)
            end
            return fallback
        end
    end
    local function clear_suggestion()
        vim.fn['copilot#Dismiss']()
        require('sidekick.nes').clear()
    end

    for key, fallback in pairs({ ['<tab>'] = '\t', ['<D-j>'] = '', ['<D-о>'] = '' }) do
        vim.keymap.set({ 'i', 'n' }, key, appy_suggestion(fallback), { expr = true, replace_keycodes = false })
    end
    vim.keymap.set({ 'i', 'n' }, '<D-l>', clear_suggestion, { silent = true })
    vim.keymap.set({ 'i', 'n' }, '<D-д>', clear_suggestion, { silent = true })

    vim.api.nvim_create_autocmd('BufEnter', {
        pattern = { '*.env', '*.env.*' },
        callback = function()
            vim.b.copilot_enabled = false
        end,
    })
end

vim.pack.add({ 'https://github.com/folke/sidekick.nvim' })
do
    require('sidekick').setup()
end
