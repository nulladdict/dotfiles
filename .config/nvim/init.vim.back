set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

" The mapleader has to be set before we start loading all
" the plugins.
let mapleader = "\<space>"
nnoremap <space> <nop>

" Mouse is great!
set mouse=a

" Indets and whitespaces
set autoindent
set smartindent
set smarttab
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab
set wrap
set lbr

set list
set listchars=tab:│\ ,trail:~,lead:·,multispace:·,nbsp:×

" Auto indent pasted text
nnoremap p p=`]
nnoremap P P=`]

call plug#begin('~/.local/share/nvim/plugged')

" Cool plugins
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'mg979/vim-visual-multi', { 'branch': 'master' }
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'jiangmiao/auto-pairs'
Plug 'itchyny/lightline.vim'
Plug 'justinmk/vim-sneak'
Plug 'luochen1990/indent-detector.vim'

" Localization
Plug 'ybian/smartim'

" Search
Plug 'henrik/vim-indexed-search'

" Git
Plug 'airblade/vim-gitgutter'

" Visuals
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'cocopon/iceberg.vim', { 'as': 'iceberg' }

" HTML
Plug 'slim-template/vim-slim'

" Javascript Typescript
Plug 'yuezk/vim-js'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'maxmellon/vim-jsx-pretty'

" Markdown
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app & yarn install'  }

" Rust
Plug 'rust-lang/rust.vim'
Plug 'NoahTheDuke/vim-just'

" Svelte
Plug 'evanleck/vim-svelte', { 'branch': 'main' }

call plug#end()

syntax enable
filetype plugin indent on

" coc config
let g:coc_global_extensions = [
  \ 'coc-json',
  \ 'coc-tsserver',
  \ 'coc-html',
  \ 'coc-css',
  \ 'coc-yaml',
  \ 'coc-lists',
  \ 'coc-git',
  \ ]

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Remap keys for gotos
nmap <silent>gd <Plug>(coc-definition)
nmap <silent>gy <Plug>(coc-type-definition)
nmap <silent>gi <Plug>(coc-implementation)
nmap <silent>gr <Plug>(coc-references)
nmap <silent>gh :call <SID>show_documentation()<CR>
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>ac <Plug>(coc-codeaction)
nmap <leader>qf <Plug>(coc-fix-current)

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')

" FZF mapping
let $FZF_DEFAULT_COMMAND='rg --files'
nnoremap <C-p> :FZF<cr>
nnoremap <C-g> :Rg<cr>

" svelte
let g:svelte_preprocessors = ['typescript', 'scss']

" Color theme
set background=dark
colorscheme iceberg

" let g:lightline = { 'colorscheme': 'dracula' }
let g:lightline = { 'colorscheme': 'iceberg' }
let g:lightline.active = {
      \ 'right': [
      \   ['percent', 'lineinfo'],
      \   ['fileformat', 'fileencoding', 'filetype'],
      \ ]}


set cursorline
set laststatus=2

" Sets how many lines of history VIM has to remember
set history=500

" Set 5 lines to the cursor - when moving vertically using j/k
set so=5

" Turn on the Wild menu
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

" Always show current position
set ruler

" Height of the command bar
set cmdheight=1

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Search
set ignorecase
set smartcase
set hlsearch
set incsearch
set magic
map <silent> <leader><cr> :noh<cr>

" Don't redraw while executing macros (good performance config)
set lazyredraw

" Unmap Ex mode
nnoremap Q <Nop>

" Show matching brackets when text indicator is over them
" How many tenths of a second to blink when matching brackets
set showmatch
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Enable line numbers
set number

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

" No backup here
set nobackup
set nowritebackup

" Specify the behavior when switching between buffers
try
  set switchbuf=useopen,usetab,newtab
  set stal=2
catch
endtry

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Remap VIM 0 to first non-blank character
map 0 ^

" Splits
set splitbelow
set splitright

" Better terminal mode
tnoremap <Esc> <C-\><C-n>
command! -nargs=0 Tterminal :tabnew <bar> :terminal
nnoremap <leader>t :Tterminal<cr>
autocmd TermOpen term://* startinsert

" Explore mapping
nnoremap <leader>v :Lexplore <bar> vertical resize 32<cr>

" Move a line of text
nnoremap <C-j> :m .+1<CR>
nnoremap <C-k> :m .-2<CR>
inoremap <C-j> <Esc>:m .+1<CR>gi
inoremap <C-k> <Esc>:m .-2<CR>gi
vnoremap <C-j> :m '>+1<CR>gv
vnoremap <C-k> :m '<-2<CR>gv

" Toggle and untoggle spell checking
map <leader>ss :setlocal spell!<cr>
set spelllang=ru_ru,ru_yo,en_us,en_gb

" nvim providers
let g:loaded_ruby_provider=0
let g:loaded_python_provider=0
let g:python_host_prog = '/usr/bin/python'
let g:python3_host_prog='/usr/local/bin/python3'

" Persistent undo
if has('persistent_undo')
  silent !mkdir ~/.vim/backups > /dev/null 2>&1
  set undodir=~/.vim/backups
  set undofile
endif

