return {
    {
        'saghen/blink.cmp',
        version = '1.*',
        dependencies = {
            {
                'L3MON4D3/LuaSnip',
                build = 'make install_jsregexp',
            },
        },
        config = function()
            require('blink.cmp').setup({
                keymap = { preset = 'enter' },
                completion = {
                    documentation = { auto_show = true },
                    accept = { auto_brackets = { enabled = false } },
                    menu = { max_height = 16 },
                },
                sources = { default = { 'lsp', 'snippets', 'path', 'buffer' } },
            })
        end,
    },

    {
        'github/copilot.vim',
        config = function()
            vim.g.copilot_settings = { selectedCompletionModel = 'gpt-4o-copilot' }
            vim.g.copilot_workspace_folders = { vim.fn.getcwd() }
            vim.g.copilot_filetypes = { ['copilot-chat'] = false }

            vim.keymap.set('i', '<D-j>', 'copilot#Accept("")', { expr = true, replace_keycodes = false })
            vim.keymap.set('i', '<D-о>', 'copilot#Accept("")', { expr = true, replace_keycodes = false })

            vim.api.nvim_create_autocmd('BufEnter', {
                pattern = { '*.env', '*.env.*' },
                callback = function() vim.b.copilot_enabled = false end
            })
        end
    },

    {
        'CopilotC-Nvim/CopilotChat.nvim',
        dependencies = {
            { 'nvim-lua/plenary.nvim' },
        },
        build = 'make tiktoken',
        opts = {
            model = 'claude-3.7-sonnet',
            agent = 'copilot',
            providers = {
                github_models = {
                    disabled = true,
                },
            },
            window = {
                layout = 'vertical',
                width = 0.4,
            }
        },
        config = function(_, opts)
            local chat = require('CopilotChat')
            chat.setup(opts)
            local select = require('CopilotChat.select')

            vim.keymap.set('n', '<D-k>', function() chat.open() end)
            vim.keymap.set('v', '<D-i>', function()
                vim.ui.input({ prompt = 'Ask Copilot' }, function(input)
                    if input ~= '' then
                        chat.ask(input, { selection = select.visual })
                    end
                end)
            end)

            vim.api.nvim_create_autocmd('BufEnter', {
                pattern = 'copilot-*',
                callback = function()
                    vim.opt_local.conceallevel = 0
                end
            })
        end
    },
}
