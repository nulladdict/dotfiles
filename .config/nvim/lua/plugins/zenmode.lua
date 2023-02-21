require("zen-mode").setup()

vim.keymap.set("n", "<leader>zz", function() require("zen-mode").toggle() end)
