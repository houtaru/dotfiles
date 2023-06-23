" ----------------------------------------------------------------------------
" Plugins: {{{
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin("~/.vim/plugged")

Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'sheerun/vim-polyglot'
Plug 'dense-analysis/ale'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'bling/vim-airline'
Plug 'nanotech/jellybeans.vim'
Plug 'vim-airline/vim-airline-themes'

call plug#end()
" }}}

" Plugin settings: {{{

" netrw {{
" Hide .swp, .pyc, ENV/, .git/, *.map, *.plist
let g:netrw_list_hide= '.*\.swp$,.*\.pyc,ENV,.git/,.*\.map,.*\.plist$'
" Override netrw settings to show line numbers
let g:netrw_bufsettings = 'noma nomod nu nobl nowrap ro'
" Set size for the new :Lexplore
let g:netrw_winsize = 20

" }}

" vim-airlien {{
function! AirlineInit()
  let g:airline_mode_map = {
        \ '__' : '-',
        \ 'n' : 'N',
        \ 'i' : 'I',
        \ 'R' : 'R',
        \ 'c' : 'C',
        \ 'v' : 'V',
        \ 'V' : 'V',
        \ 's' : 'S',
        \ 'S' : 'S',
        \ }
  let g:airline_left_sep = ''
  let g:airline_left_alt_sep= ''
  let g:airline_right_sep = ''
  let g:airline_right_alt_sep = ''
  let g:airline_symbols.linenr = ' '
  let g:airline_symbols.colnr = ' '
  AirlineToggleWhitespace
  AirlineTheme jellybeans
endfunction
autocmd VimEnter * call AirlineInit()
" }}

" jellybeans {{
set background=dark
color jellybeans	" set background=dark for other machine, but use jellybeans in my computer
" }}

" ale {{
set omnifunc=ale#completion#OmniFunc
set completeopt=menu,menuone,preview,noselect,noinsert

let g:ale_floating_preview=1
let g:ale_completion_enabled=1
let g:ale_completion_autoimport=0
let g:ale_cpp_clangd_options='--background-index -j=8 -malloc-trim -pch-storage=memory -header-insertion=never --all-scopes-completion'
let g:ale_cpp_clangd_options='--background-index -j=8 -malloc-trim -pch-storage=memory -header-insertion=never --all-scopes-completion'

nnoremap <silent> K <Plug>(ale_hover)
imap <silent> <C-Space> <Plug>(ale_complete)
nmap <silent> gd <Plug>(ale_go_to_definition)
nmap <silent> gy <Plug>(ale_go_to_type_definition)
nmap <silent> gi <Plug>(ale_go_to_implementation)
nmap <silent> gr <Plug>(ale_find_references)

nmap <silent> [g <Plug>(ale_previous_wrap_error)
nmap <silent> ]g <Plug>(ale_next_wrap_error)
nmap <silent> [w <Plug>(ale_previous_wrap_warning)
nmap <silent> ]w <Plug>(ale_next_wrap_warning)

" }}

" fzf {{
cabbrev rg Rg
nnoremap <silent> <C-P> :Files!<CR><cr>
" }}

" }}}

" -----------------------------------------------------------------------------
" Default vim variables: {{{
let mapleader=","

set nocompatible	" use new features whenever they are available

syntax on
filetype on
filetype plugin indent on
set encoding=utf-8
set nu						" show line number
set autoindent
set shiftwidth=4
set softtabstop=4
set tabstop=4
set noexpandtab

set bs=2				" backspace should work as we expect
set history=50			" remember last 50 commands
set ruler				" show cursor position in bottom line
set hlsearch			" highlight search result
" y and d put stuff into system clipboard (so that other apps can see it)
set clipboard=unnamed,unnamedplus
set mouse=a			 " enable mouse. At least this should work for iTerm
set textwidth=0
" Open new split to right / bottom
set splitbelow
set splitright
set foldmethod=indent
set foldlevel=20
nnoremap Q <Nop>
" }}}

" Misc {{{
set autoread			" auto re-read changes outside vim
set autowrite			" auto save before make/execute
set pastetoggle=<F10>
set showcmd
set timeout			 " adjust timeout for mapped commands
set timeoutlen=1200

set visualbell
set noerrorbells
" }}}

" Display related: {{{
set display+=lastline   " Show everything you can in the last line (intead of stupid @@@)
set display+=uhex	    " Show chars that cannot be displayed as <13> instead of ^M
set colorcolumn=80
set listchars=lead:\ ,trail:·,tab:\|·
set listchars=eol:¬,space:·,lead:\ ,trail:·,nbsp:◇,tab:→-,extends:▸,precedes:◂,multispace:···⬝,leadmultispace:\│\ \ \ ,
set list
" }}}

" Searching {{{
set incsearch		" show first match when start typing
set ignorecase		" default should ignore case
set smartcase		" use case sensitive if I use uppercase
" }}}

" {{{ jumping
set switchbuf=useopen,usetab
" }}}

" Shortcuts

nnoremap <leader>yf :let @+=expand("%:p") <CR>
nnoremap <leader>e :e <C-R>=expand("%:p:h") . '/' <CR>
nnoremap <leader>vs :vs <C-R>=expand("%:p:h") . '/' <CR>
nnoremap <C-N> :Lexplore<cr>

inoremap {<cr> {<cr><cr>}<up><tab>

" -----------------------------------------------------------------------------
" Specific settings for specific filetypes:	{{{

" usual policy: if there is a Makefile present, :mak calls make, otherwise we define a command to compile the filetype

" C/C++:
function! CPPSET()
  set noexpandtab
  nnoremap <buffer> <F9> :w<cr>:!g++-9 -O2 % -o %< -std=c++14 -I ./<cr>:!./%<<cr>
  nnoremap <buffer> <F8> :w<cr>:!g++-9 -Wall -Wextra -Wshadow -O2 % -o %< -std=c++14 -I ./<cr>
endfunction

" Java
function! JAVASET()
  set makeprg=if\ \[\ -f\ \"Makefile\"\ \];then\ make\ $*;else\ if\ \[\ -f\ \"makefile\"\ \];then\ make\ $*;else\ javac\ -g\ %;fi;fi
  set cindent
  set nowrap
  nnoremap <buffer> <F8> :w<cr>:!javac %<cr>
  nnoremap <buffer> <F9> :w<cr>:!javac %<cr>:!java %< %<cr>
endfunction

" vim scripts
function! VIMSET()
  set nowrap
  set tabstop=2
  set softtabstop=2
  set shiftwidth=2
endfunction

" Rust
function! RUSTSET()
  set nowrap
  set tabstop=2
  set softtabstop=2
  set shiftwidth=2

  nnoremap <buffer> <F8> :w<cr>:!rustc % <cr>
  nnoremap <buffer> <F9> :w<cr>:!rustc % <cr>:!./%<<cr>
endfunction


" Autocommands for all languages:
autocmd BufNewFile,BufReadPost *.py2 set filetype=python
autocmd FileType rust       call RUSTSET()
autocmd FileType vim        call VIMSET()
autocmd FileType c,cc,cpp   call CPPSET()
autocmd FileType java       call JAVASET()
" }}}


" Disable ~ when inside tmux, as Ctrl + PageUp/Down are translated to 5~
if &term =~ '^screen'
  map ~ <Nop>
endif

" Show filename in tmux panel
autocmd BufEnter,BufReadPost,FileReadPost,BufNewFile * call system("tmux rename-window " . expand('%'))
autocmd VimLeave * call system("tmux rename-window bash")

" Hack to make bg black with jellybeans
hi Normal ctermbg=none
hi LineNr ctermbg=none
hi NonText ctermbg=none
hi SpecialKey ctermbg=none

