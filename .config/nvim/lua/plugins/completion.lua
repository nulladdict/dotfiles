return {
    {
        'saghen/blink.cmp',
        version = '1.*',
        config = function()
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
                    default = { 'lsp', 'snippets', 'path', 'buffer' },
                },
            })
        end,
    },

    {
        'github/copilot.vim',
        config = function()
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
        end,
    },

    {
        'folke/sidekick.nvim',
        opts = {
            -- Never clear suggestions automatically
            clear = {
                events = {},
                esc = false,
            },
        },
        keys = {
            {
                '<C-.>',
                function()
                    require('sidekick.cli').focus()
                end,
                mode = { 'n', 'x', 'i', 't' },
                desc = 'Sidekick Switch Focus',
            },
        },
    },
}
