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
Plug 'tpope/vim-commentary'
Plug 'sheerun/vim-polyglot'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'bling/vim-airline'
Plug 'nanotech/jellybeans.vim'
Plug 'vim-airline/vim-airline-themes'
Plug 'christoomey/vim-tmux-navigator'

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

" git {{

cabbrev git Git
let g:gitgutter_show_msg_on_hunk_jumping = 0
nmap ]h <Plug>(GitGutterNextHunk)
nmap [h <Plug>(GitGutterPrevHunk)

" }}

" fzf {{
nnoremap <silent> <C-P> :Files!<CR><cr>
" }}

" coc.nvim {{
set nobackup              " Some servers have issues with backup files
set nowritebackup
set updatetime=300        " Having longer updatetime (default is 4000 ms = 4s) leads to noticeable  delays and poor user experience
set signcolumn=yes        " Always show the signcolumn, otherwise it would shift the text each time diagnostics appear/become resolved
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}   " add statusline
let g:coc_node_path="~/.nvm/versions/node/v18.12.1/bin/node"



" tab completion
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" jump to next suggestion
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
" jump to previous suggestion
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
" accept selection
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
" trigger completion
inoremap <silent><expr> <c-@> coc#refresh()

" diagnostic
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" show review window
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction
nnoremap <silent> K :call ShowDocumentation()<CR>

" Highlight the symbol and its references when holding the cursor
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap <C-f> and <C-b> to scroll float windows/popups
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Find symbol of current document
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>

" Symbol renaming
nmap <leader>rn <Plug>(coc-rename)
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
set listchars=eol:¬,space:\ ,lead:\ ,trail:·,nbsp:◇,tab:→-,extends:▸,precedes:◂,multispace:···⬝,leadmultispace:\│\ \ \ ,
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

" {{{ Shortcuts
nnoremap <leader>yf :let @+=expand("%:p") <CR>
nnoremap <leader>e :Buffers<CR>
nnoremap <C-N> :Lexplore<cr>
" }}}

" {{{ Quicklists
function! s:toggle_quickfix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        copen
    else
        cclose
    endif
endfunction

nnoremap <silent> <leader>q :call <sid>toggle_quickfix()<cr>
nnoremap <expr> <leader>n (empty(filter(tabpagebuflist(), 'getbufvar(v:val, "&buftype") is# "quickfix"')) ? ":bnext\n" : ":cnext\n")
nnoremap <expr> <leader>b (empty(filter(tabpagebuflist(), 'getbufvar(v:val, "&buftype") is# "quickfix"')) ? ":bprev\n" : ":cprev\n")

command! -nargs=? -complete=dir Gr :cexpr
    \ system("grep -rnI " . shellescape(<q-args>)) | copen
cabbrev gr Gr

" }}

" }}}

" {{ command alias
cabbrev now put =strftime('%Y/%m/%d %H:%M')

" }}}

" {{{ auto commands
augroup numbertogglegroup
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup end
" }}

" -----------------------------------------------------------------------------
" Specific settings for specific filetypes:	{{{

" usual policy: if there is a Makefile present, :mak calls make, otherwise we define a command to compile the filetype

" C/C++:
function! CPPSET()
  set noexpandtab
"  inoremap { {}<Left>
"  inoremap {<CR> {<CR>}<Esc>O
"  inoremap {{ {
"  inoremap {} {}
  command! -nargs=? -complete=dir Gr :cexpr
        \ system("grep -rn --include='*.h' --include='*.cpp' --include='*.c' --include='*.cc' --exclude-dir='thrift' --exclude-dir='thriftzg' " . shellescape(<q-args>)) | copen
  nnoremap <buffer> <F9> :w<cr>:!g++-11 -g -Wall -Wextra -Wshadow -O2 % -o %< -std=c++14 -I ./<cr>:!exec %:p:r<cr>
  nnoremap <buffer> <F8> :w<cr>:!g++-11 -g -Wall -Wextra -Wshadow -O2 % -o %< -std=c++14 -I ./<cr>
endfunction

" Java
function! JAVASET()
  set makeprg=if\ \[\ -f\ \"Makefile\"\ \];then\ make\ $*;else\ if\ \[\ -f\ \"makefile\"\ \];then\ make\ $*;else\ javac\ -g\ %;fi;fi
  set cindent
  set nowrap
  command! -nargs=? -complete=dir Gr :cexpr
        \ system("grep -rn --include='*.java' " . shellescape(<q-args>)) | copen
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

  command! -nargs=? -complete=dir Gr :cexpr
        \ system("grep -rn --include='*.rs' " . shellescape(<q-args>)) | copen
  nnoremap <buffer> <F8> :w<cr>:!rustc % <cr>
  nnoremap <buffer> <F9> :w<cr>:!rustc % <cr>:!./%<<cr>
endfunction

" Beautify JSON
nmap =j :%!python -m json.tool<CR>

" Remove trailing spaces
"autocmd BufWritePre * :%s/\s\+$//e

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
"autocmd BufEnter,BufReadPost,FileReadPost,BufNewFile * call system("tmux rename-window " . expand('%'))
"autocmd VimLeave * call system("tmux rename-window bash")

" Hack to make bg black with jellybeans
hi Normal ctermbg=none
hi LineNr ctermbg=none
hi NonText ctermbg=none
hi SpecialKey ctermbg=none

