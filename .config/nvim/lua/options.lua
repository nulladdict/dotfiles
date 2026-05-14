-- Indents
vim.opt.smartindent = true -- Autoindent new lines
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- UI
vim.opt.encoding = 'utf-8' -- Set default encoding
vim.opt.ff = 'unix'
vim.opt.ffs = 'unix,dos,mac' -- Use Unix as the standard file type
vim.opt.linebreak = true -- Wrap on word boundary
vim.opt.laststatus = 2 -- Always show statusline
vim.opt.cursorline = true -- Show current line
vim.opt.splitright = true -- Vertical split to the right
vim.opt.splitbelow = true -- Horizontal split to the bottom
vim.opt.scrolloff = 8 -- Always show rows from edge of the screen
vim.opt.cmdheight = 1 -- Height of the command bar
vim.opt.winborder = 'rounded'

-- Sidebar
vim.opt.number = true -- Show line number
vim.opt.numberwidth = 3 -- Reserve a couple columns
vim.opt.signcolumn = 'yes' -- Always show signcolumns
vim.opt.ruler = true -- Always show current position

-- Commands mode
vim.opt.wildmenu = true -- on TAB, complete options for system command
vim.opt.wildignore = '.git/*,.hg/*,.svn/*,*/.DS_Store'

-- Search
vim.opt.incsearch = true -- Starts searching as soon as typing, without enter needed
vim.opt.ignorecase = true -- Ignore case letters when search
vim.opt.smartcase = true -- Ignore lowercase for the whole pattern

-- Invisible characters
vim.opt.list = true
vim.opt.listchars = 'tab:│ ,trail:~,lead:·,multispace:·,nbsp:×'
vim.opt.backspace = 'indent,eol,start' -- backspace works on every char in insert mode

-- Backup files
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = true
