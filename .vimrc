" Set spell check to be enabled to files which end with either .md or .txt
"
" To get over complete type z= when you are over the word
autocmd BufRead,BufNewFile *.md setlocal spell spelllang=en_us
autocmd BufRead,BufNewFile *.txt setlocal spell spelllang=en_us

""" Indentation and Tabs"""
"Copy indentation from current line when making a new line
set autoindent

" Smart indentation when programming: indent after {
set smartindent

set tabstop=4 		" number of spaces per tab
set expandtab 		" convert tab to space
set shiftwidth=4 	" set a tab press equal to 4 spaces
set softtabstop=4   " set tab width to 4 spaces in insert mode

""" Looking and Appearance"""

" Enable systax highlight
syntax enable

" File Encoding
set encoding=utf8

" Use unix as the standard file type
set ffs=unix,dos,mac

""" Productivity"""

" Set line number to show
set number

" Show a auto complete tab when use are typing command
" like :sp <tab>
set wildmenu

" Split new window to the right of current window when use :vsplit
set splitright

" Split new window below current window when use :split
set splitbelow

" Sets the size of the status bar at the bottom to have a height of two
set laststatus=2

" Searching when in command mode type /words to find
" search as characters are entered
set incsearch

" Highlight matched characters
set hlsearch

" Clear last used  search pattern
:nnoremap <silent> <esc><esc> :let @/="" <CR>

" Ignore case when searching
set ignorecase

" Turn off default regex characters
nnoremap / /\v
vnoremap / /\v

" Display ruler on the bottom right -- shoule be there by default
set ruler

" Enables mouse support
set mouse=a

" Auto updates file if an external source edits the file
set autoread

" Improves performance by only redrawing screen when needed
set lazyredraw

" Disable ding sound on error, flashes cursor instead
" set visualbell


""" Building code"""
" c++
autocmd filetype cpp nnoremap<C-B> :w <CR> :!g++ % -o %< -std=c++17 -lstdc++fs -pthread -O2 -Wall <CR>
" python
autocmd filetype python nnoremap<C-B> :w <CR> :execute '!python' shellescape(@%, 1)  <CR>
" java
autocmd filetype java nnoremap<C-B> :w <CR> :!javac % && java -enableassertions %< <CR>

""" Plugins"""
" YouCompleteMe
let g:ycm_global_ycm_extra_conf = '~/.vim/bundle/YouCompleteMe/third_party/ycmd/.ycm_extra_conf.py'
let g:ycm_autoclose_preview_window_after_insertion = 1
let g:ycm_autoclose_preview_window_after_completion = 1
" let g:loaded_youcompleteme = 1

" colorscheme gruvbox

set nocompatible              " be iMproved, required
filetype off                  " required

execute pathogen#infect()

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo

Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
" Plugin 'L9'
" Git plugin not hosted on GitHub

Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
" Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.

Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Install L9 and avoid a Naming conflict if you've already installed a
" different version somewhere else.
" Plugin 'ascenator/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
Plugin 'Valloric/YouCompleteMe'

call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

