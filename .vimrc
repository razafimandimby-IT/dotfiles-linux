" =============================================================================
"  .vimrc — Minimal Vim Configuration
"  Part of dotfiles-linux (https://github.com/razafimandimby-IT/dotfiles-linux)
" =============================================================================

" ── General ──────────────────────────────────────────────────────────────────

set nocompatible              " Disable vi-compatibility (must be first)
filetype plugin indent on     " Enable file type detection, plugins, and indentation
syntax on                     " Enable syntax highlighting

" ── Appearance ───────────────────────────────────────────────────────────────

set number                    " Show absolute line numbers
set relativenumber            " Show relative line numbers (hybrid mode)
set numberwidth=4             " Minimum width for line numbers
set showcmd                   " Show (partial) command in the last line
set showmode                  " Show current mode in the last line
set ruler                     " Show cursor position (row,col)
set cursorline                " Highlight the current line
set colorcolumn=80,100        " Highlight columns 80 and 100 as guides
set laststatus=2              " Always show a status line
set statusline=%F%m%r%h%w\   " Status line: full path, modified, read-only, help, preview
set statusline+=%=            " Right-align the rest
set statusline+=%l:%c\        " Line:Column
set statusline+=%p%%          " Percentage through file
set listchars=tab:→\ ,trail:·,eol:$,nbsp:␣,extends:»,precedes:«
set list                      " Show invisible characters
set showmatch                 " Show matching brackets
set matchtime=2               " 2/10 second for matching bracket flash
set visualbell                " Use visual bell instead of beeping
set t_vb=                     " Disable any bell/visual bell
set title                     " Set terminal title to filename
set background=dark           " Assume dark background for color scheme

" ── Tabs & Indentation ───────────────────────────────────────────────────────

set expandtab                 " Convert tabs to spaces
set tabstop=4                 " Number of spaces for a tab character
set shiftwidth=4              " Number of spaces for auto-indent
set softtabstop=4             " Number of spaces for tab in editing
set smarttab                  " smart tab handling
set autoindent                " Auto-indent new lines
set smartindent               " Smart auto-indenting
set shiftround                " Round indent to multiple of shiftwidth

" ── Searching ────────────────────────────────────────────────────────────────

set hlsearch                  " Highlight all search matches
set incsearch                 " Show matches while typing
set ignorecase                " Case-insensitive search...
set smartcase                 " ...unless search contains uppercase
set wrapscan                  " Wrap search around file end
set gdefault                  " Default to /g flag on substitutions

" ── Editing ──────────────────────────────────────────────────────────────────

set backspace=indent,eol,start  " Allow backspacing over everything in insert mode
set whichwrap+=<,>,[,]        " Cursor keys wrap at line ends
set linebreak                 " Break lines at word boundaries
set hidden                    " Allow switching buffers without saving
set history=1000              " Remember last 1000 commands
set undofile                  " Persistent undo
set undodir=~/.vim/undodir    " Where to store undo files
set undolevels=1000           " Maximum undo levels
set undoreload=10000          " Maximum lines for undo on reload
set autoread                  " Auto-reload files changed externally
set timeoutlen=400            " Timeout for key mappings (ms)
set ttimeoutlen=50            " Timeout for terminal key codes (ms)

" ── Mouse ────────────────────────────────────────────────────────────────────

set mouse=a                   " Enable mouse in all modes
set mousemodel=popup          " Right-click shows popup menu
set selectmode=mouse          " Mouse starts select mode
set ttyfast                   " Faster terminal rendering

" ── Folding ──────────────────────────────────────────────────────────────────

set foldenable                " Enable folding
set foldmethod=syntax         " Fold based on syntax
set foldlevelstart=99         " Start with all folds open
set foldnestmax=10            " Max 10 nested folds

" ── Completion ───────────────────────────────────────────────────────────────

set wildmenu                  " Enhanced command-line completion
set wildmode=longest:full,full  " Tab completion behavior
set wildignore=*.o,*.obj,*.pyc,*.class,*.swp,.git,node_modules,*.jpg,*.png
set wildignore+=*.pdf,*.zip,*.tar.gz,*.tar.bz2,*.tar.xz
set wildignore+=*.exe,*.dll,*.so,*.dylib
set completeopt=menu,menuone,noselect  " Completion popup settings

" ── Encryption (optional) ────────────────────────────────────────────────────

set cryptmethod=blowfish2     " Use stronger encryption for :X

" ── Filetype-specific Settings ───────────────────────────────────────────────

" Python: 4-space indentation
augroup filetype_python
    autocmd!
    autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
augroup END

" YAML: 2-space indentation
augroup filetype_yaml
    autocmd!
    autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
augroup END

" JSON: 2-space indentation
augroup filetype_json
    autocmd!
    autocmd FileType json setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
augroup END

" Markdown: no wrapping by default, spell check
augroup filetype_markdown
    autocmd!
    autocmd FileType markdown setlocal wrap linebreak nolist spell
    autocmd FileType markdown setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
augroup END

" Makefile: must use real tabs
augroup filetype_make
    autocmd!
    autocmd FileType make setlocal noexpandtab tabstop=4 shiftwidth=4
augroup END

" Shell: 4-space indentation
augroup filetype_sh
    autocmd!
    autocmd FileType sh setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
augroup END

" Go: 8-space tabs (gofmt standard)
augroup filetype_go
    autocmd!
    autocmd FileType go setlocal noexpandtab tabstop=8 shiftwidth=8
augroup END

" ── Key Mappings ─────────────────────────────────────────────────────────────

" Leader key
let mapleader = " "
let maplocalleader = "\\"

" Escape with 'jj' in insert mode
inoremap jj <Esc>

" Clear search highlighting
nnoremap <Leader>h :nohlsearch<CR>

" Save with Ctrl+S
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>

" Quit with Ctrl+Q
nnoremap <C-q> :q<CR>
inoremap <C-q> <Esc>:q<CR>

" Reload vimrc
nnoremap <Leader>vr :source $MYVIMRC<CR>

" Edit vimrc
nnoremap <Leader>ve :e $MYVIMRC<CR>

" Better line navigation (wrapped lines)
nnoremap j gj
nnoremap k gk

" Center search results
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap * *zzzv
nnoremap # #zzzv
nnoremap g* g*zzzv
nnoremap g# g#zzzv

" Quick split navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize splits
nnoremap <S-Up> :resize +2<CR>
nnoremap <S-Down> :resize -2<CR>
nnoremap <S-Left> :vertical resize +2<CR>
nnoremap <S-Right> :vertical resize -2<CR>

" Tab management
nnoremap <Leader>tn :tabnew<CR>
nnoremap <Leader>tc :tabclose<CR>
nnoremap <Leader>tm :tabmove
nnoremap <Leader>tl :tabnext<CR>
nnoremap <Leader>th :tabprev<CR>

" Buffer management
nnoremap <Leader>bn :bnext<CR>
nnoremap <Leader>bp :bprevious<CR>
nnoremap <Leader>bd :bdelete<CR>
nnoremap <Leader>bl :ls<CR>

" Visual mode indenting
vnoremap < <gv
vnoremap > >gv

" Keep visual selection when indenting
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

" Copy to clipboard
vnoremap <Leader>y "+y
nnoremap <Leader>Y "+yg_
nnoremap <Leader>y "+y
nnoremap <Leader>p "+p
nnoremap <Leader>P "+P

" Paste without yanking replaced text
xnoremap p pgvy

" Yank from cursor to end of line (consistent with D, C)
nnoremap Y y$

" ── Commands ─────────────────────────────────────────────────────────────────

" Trim trailing whitespace
command! Trim %s/\s\+$//e | echo "Trailing whitespace removed."

" Convert tabs to spaces
command! Untab %retab

" Convert spaces to tabs (with 4-space tab stops)
command! Tab %retab!

" Highlight current word
command! HighlightWord set hlsearch | let @/ = expand('<cword>')

" JSON format
command! JsonFormat %!python3 -m json.tool 2>/dev/null || %!python -m json.tool 2>/dev/null

" Base64 encode/decode visual selection
vnoremap <Leader>b64e c<c-r>=system('base64 -w0', @")<CR><Esc>
vnoremap <Leader>b64d c<c-r>=system('base64 -d', @")<CR><Esc>

" ── Auto-Commands ────────────────────────────────────────────────────────────

" Create parent directories on save if they don't exist
augroup mkdir_on_save
    autocmd!
    autocmd BufWritePre * call s:mkdir_parent()
augroup END

function! s:mkdir_parent()
    let dir = expand('<afile>:p:h')
    if !isdirectory(dir)
        call mkdir(dir, 'p')
    endif
endfunction

" Remember last cursor position
augroup cursor_position
    autocmd!
    autocmd BufReadPost *
        \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
        \ |   exe "normal! g`\""
        \ | endif
augroup END

" ── Plugin-like Features (Vim built-ins) ─────────────────────────────────────

" Enable netrw for file browsing
let g:netrw_banner = 0
let g:netrw_liststyle = 3     " Tree view
let g:netrw_browse_split = 4  " Open file in previous window
let g:netrw_altv = 1          " Open splits to the right
let g:netrw_winsize = 25      " File explorer takes 25% of screen

" Disable netrw history
let g:netrw_dirhistmax = 0

" ── Create undo directory if needed ─────────────────────────────────────────

if !isdirectory(expand('~/.vim/undodir'))
    call mkdir(expand('~/.vim/undodir'), 'p')
endif

" ── Installation check (optional ─ only if you have a plugin manager) ───────
" To install vim-plug (plugin manager), run:
"   curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"
" Then uncomment the section below and run :PlugInstall inside Vim.

" call plug#begin('~/.vim/plugged')
"
" " Essentials
" Plug 'tpope/vim-sensible'           " Sensible defaults
" Plug 'tpope/vim-fugitive'           " Git integration
" Plug 'tpope/vim-surround'           " Surround text objects
" Plug 'tpope/vim-commentary'         " Comment toggling
" Plug 'tpope/vim-repeat'             " Repeat plugin commands
" Plug 'airblade/vim-gitgutter'       " Git diff in sign column
" Plug 'junegunn/fzf.vim'             " FZF integration
" Plug 'sheerun/vim-polyglot'         " Language pack
" Plug 'preservim/nerdtree'           " File explorer
" Plug 'vim-airline/vim-airline'      " Status line
" Plug 'vim-airline/vim-airline-themes'
" Plug 'dracula/vim'                  " Dracula color scheme
"
" call plug#end()
"
" colorscheme dracula

" That's all. Vim is now configured.
