" ----------------------------------------------------------------------------
" Plugins: {{{
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin("~/.vim/plugged")

Plug 'tpope/vim-surround'
Plug 'nanotech/jellybeans.vim'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'mileszs/ack.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'dense-analysis/ale'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'" themes
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()
" }}}

" Plugin settings: {{{

" netrw {{
" Hide .swp, .pyc, ENV/, .git/, *.map
let g:netrw_list_hide= '.*\.swp$,.*\.pyc,ENV,.git/,.*\.map'
" Override netrw settings to show line numbers
let g:netrw_bufsettings = 'noma nomod nu nobl nowrap ro'
" Set size for the new :Lexplore
let g:netrw_winsize = 16

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
  let g:airline_section_a = airline#section#create(['mode'])
  let g:airline_section_b = airline#section#create(['%f'])
  let g:airline_section_c = airline#section#create([''])
  let g:airline_section_x = airline#section#create_right([''])
  let g:airline_section_y = airline#section#create_right([''])
  let g:airline_section_z = airline#section#create_right(['%l %c'])
  AirlineToggleWhitespace
  AirlineTheme jellybeans
endfunction
autocmd VimEnter * call AirlineInit()
" }}

" ack.vim {{
let g:ackprg = 'ag --nogroup --nocolor --column --ignore ENV/'
let g:ackhighlight = 1
cabbrev Ack Ack!
" }}

set laststatus=2
set t_Co=256

" jellybeans {{
set background=dark
color jellybeans	" set background=dark for other machine, but use jellybeans in my computer
" }}

" coc.nvim {{
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

set updatetime=300

" Use tab for trigger completion with characters ahead and navigate
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
" Use <c-space> to trigger completion
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif
" GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nnoremap <silent> K :call <SID>show_documentation()<CR>

" Highlight the symbol and its references when holding the cursor
autocmd CursorHold * silent call CocActionAsync('highlight')
" }}

" ale {{
nnoremap <leader>f :ALEFix<CR>
nnoremap <leader>l :ALEToggle<CR>
nmap <silent> <leader>n <Plug>(ale_next_wrap)
nmap <silent> <leader>N <Plug>(ale_previous_wrap)
" }}

" fzf {{
nnoremap <silent> <C-P> :Files<cr>
" }}

" }}}

" -----------------------------------------------------------------------------
" Stuffs that should be set by default: {{{
let mapleader=","

syntax on
filetype plugin indent on
set nocompatible
filetype off
set encoding=utf-8
set softtabstop=4
set tabstop=4
set expandtab
set shiftwidth=4
set nocompatible	" use new features whenever they are available
set bs=2					" backspace should work as we expect
set autoindent
set history=50		" remember last 50 commands
set ruler				  " show cursor position in bottom line
set nu						" show line number
set hlsearch			" highlight search result
" y and d put stuff into system clipboard (so that other apps can see it)
set clipboard=unnamed,unnamedplus
set mouse=a			 " enable mouse. At least this should work for iTerm
set textwidth=0
" Open new split to right / bottom
set splitbelow
set splitright
" Automatically update changed files (but need to focus on the file)
set autoread
set foldmethod=indent
set foldlevel=20
" }}}

" Shortcuts

" Tab related stuffs: {{{
"set tabstop=4
"set shiftwidth=4	" tab size = 4
"set noexpandtab
"set autoindent
"set softtabstop=4
"set shiftround		" when shifting non-aligned set of lines, align them to next tabstop
" }}}

" Misc {{{
set autoread			" auto re-read changes outside vim
set autowrite		 " auto save before make/execute
set pastetoggle=<F10>
set showcmd
set timeout			 " adjust timeout for mapped commands
set timeoutlen=1200

" set visualbell		" Tell vim to shutup
" set noerrorbells	" Tell vim to shutup!
" }}}

" Display related: {{{
set display+=lastline " Show everything you can in the last line (intead of stupid @@@)
set display+=uhex		 " Show chars that cannot be displayed as <13> instead of ^M
" }}}

" Searching {{{
set incsearch		 " show first match when start typing
set ignorecase		" default should ignore case
set smartcase		 " use case sensitive if I use uppercase
" }}}

" -----------------------------------------------------------------------------
" Specific settings for specific filetypes:	{{{

" usual policy: if there is a Makefile present, :mak calls make, otherwise we define a command to compile the filetype

" C/C++:
function! CSET()
  set makeprg=if\ \[\ -f\ \"Makefile\"\ \];then\ make\ $*;else\ if\ \[\ -f\ \"makefile\"\ \];then\ make\ $*;else\ gcc\ -O2\ -g\ -Wall\ -Wextra\ -o%.bin\ %\ -lm;fi;fi
  set cindent
  set nowrap
endfunction

function! CPPSET()
  set makeprg=if\ \[\ -f\ \"Makefile\"\ \];then\ make\ $*;else\ if\ \[\ -f\ \"makefile\"\ \];then\ make\ $*;else\ g++\ -std=gnu++0x\ -O2\ -g\ -Wall\ -Wextra\ -o\ %<\ %;fi;fi
  set cindent
  set nowrap
  set tabstop=2
  set softtabstop=2
  set shiftwidth=2
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

" Makefile
function! MAKEFILESET()
  set nowrap
  " in a Makefile we need to use <Tab> to actually produce tabs
  set noexpandtab
  set softtabstop=8
  iunmap <Tab>
endfunction

" Python
function! PYSET()
  if exists('g:no_pyset')
    return
  endif
  set nowrap

  set autoindent
  set expandtab
  set shiftwidth=4
  set tabstop=4
  nnoremap <buffer> <F9> :w<cr>:exec '!clear;python' shellescape(@%, 1)<cr>
  " Docstring should be highlighted as comment
  syn region pythonDocstring	start=+^\s*[uU]\?[rR]\?"""+ end=+"""+ keepend excludenl contains=pythonEscape,@Spell,pythonDoctest,pythonDocTest2,pythonSpaceError
  syn region pythonDocstring	start=+^\s*[uU]\?[rR]\?'''+ end=+'''+ keepend excludenl contains=pythonEscape,@Spell,pythonDoctest,pythonDocTest2,pythonSpaceError
  hi	link	 pythonDocstring	Comment
endfunction

" Ruby
function! RUBYSET()
  set autoindent!
  set noexpandtab!
  set tabstop=2
  set softtabstop=2
  set shiftwidth=2
  set expandtab

  " I prefer using same highlight for Ruby string and Ruby symbol
  "	hi clear rubySymbol
  "	hi link	rubySymbol String

  " Some simple highlight for Capybara
  syn keyword rubyRailsTestMethod feature scenario before after
  hi link rubyRailsTestMethod Function

  nnoremap <buffer> <F9> :w<cr>:exec '!clear;ruby' shellescape(@%, 1)<cr>
  nnoremap <buffer> <F8> :w<cr>:exec '!clear;rspec' shellescape(@%, 1)<cr>
endfunction


" SQL
function! SQLSET()
  syn keyword sqlStatement use describe
  nnoremap <buffer> <F9> :!clear;mysql -u root -p test < %<cr>
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
autocmd FileType c          call CSET()
autocmd FileType C          call CPPSET()
autocmd FileType cc         call CPPSET()
autocmd FileType cpp        call CPPSET()
autocmd FileType java       call JAVASET()
autocmd FileType make       call MAKEFILESET()
autocmd FileType python     call PYSET()
autocmd FileType ruby       call RUBYSET()
autocmd FileType sql        call SQLSET()
au BufRead,BufNewFile *.handlebars,*.hbs set ft=html syntax=handlebars
autocmd BufRead,BufNewFile *.md setlocal spell spelllang=en_us
autocmd BufRead,BufNewFile *.txt setlocal spell spelllang=en_us
" }}}

nnoremap <leader>e :e <C-R>=expand("%:p:h") . '/' <CR>
nnoremap <leader>vs :vs <C-R>=expand("%:p:h") . '/' <CR>
nnoremap <C-N> :Lexplore<cr>

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
