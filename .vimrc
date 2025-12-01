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
let g:netrw_list_hide= '.*\.swp$,.*\.pyc,ENV,.git/,.*\.map,.*\.plist,.*\.cache/$'
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

nmap ]d :diffget //3
nmap [d :diffget //2

" Compare working tree with git branch/commit/tag
command! -nargs=1 -complete=customlist,s:GitRefComplete GcCompare call s:GitCompare(<f-args>)

function! s:GitRefComplete(A, L, P)
  let refs = systemlist('git for-each-ref --format="%(refname:short)" refs/')
  return filter(refs + ['HEAD', 'HEAD~1', 'HEAD~2', 'HEAD~3'], 'v:val =~ "^" . a:A')
endfunction

function! s:GitCompare(ref)
  let output = systemlist('git diff --name-status ' . shellescape(a:ref) . ' 2>&1')
  if v:shell_error | echohl ErrorMsg | echo 'Git error: ' . join(output, ' ') | echohl None | return | endif
  if empty(output) | echo 'No changes' | return | endif

  let files = []
  for line in output
    let parts = split(line, "\t")
    if len(parts) >= 2
      let status = parts[0] =~# '^[DA]' ? parts[0] : 'M'
      call add(files, status . ' ' . join(parts[1:], "\t"))
    endif
  endfor
  let current = substitute(system('git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD'), '\n', '', 'g')

  " Reuse or create review buffer
  let bufname = '[Review] Git: ' . a:ref
  let existing = bufnr(bufname)
  if existing != -1 && bufwinnr(existing) != -1
    execute bufwinnr(existing) . 'wincmd w'
  else
    botright 12new
    if existing == -1
      setlocal buftype=nofile bufhidden=hide noswapfile nobuflisted cursorline nonumber norelativenumber nowrap
      execute 'file ' . fnameescape(bufname)
    else
      execute 'buffer ' . existing
    endif
  endif

  let b:review_git_ref = a:ref
  call setline(1, ['Current: ' . current, 'Compare to: ' . a:ref, 
        \ 'Help: dv=vert diff, ds=horiz diff, dq=close diff, <CR>=open, gq=quit', repeat('-', 70)] + files)

  syntax match ReviewHeader /^Current:.*\|^Compare to:.*$/
  syntax match ReviewHelp /^Help:.*$/ | syntax match ReviewSeparator /^-\+$/
  syntax match ReviewModified /^M / | syntax match ReviewDeleted /^D / | syntax match ReviewAdded /^A /
  highlight link ReviewHeader Title | highlight link ReviewSeparator Comment
  highlight ReviewHelp ctermfg=cyan guifg=cyan
  highlight ReviewModified ctermfg=yellow guifg=yellow | highlight ReviewDeleted ctermfg=red guifg=red
  highlight ReviewAdded ctermfg=green guifg=green

  nnoremap <buffer> gq :q<CR> | nnoremap <buffer> <Esc> :q<CR>
  nnoremap <buffer> <silent> <CR> :call <SID>GitOpenFile()<CR>
  nnoremap <buffer> <silent> dv :call <SID>GitDiffFile('vertical')<CR>
  nnoremap <buffer> <silent> ds :call <SID>GitDiffFile('horizontal')<CR>
  nnoremap <buffer> <silent> dq :call <SID>GitCloseDiff()<CR>
  call cursor(5, 1)
endfunction

function! s:GitGetFileInfo()
  let line = getline('.')
  return line !~# '^[MAD] ' ? v:null : {'file': substitute(line, '^[MAD] ', '', ''), 'status': matchstr(line, '^[MAD]')}
endfunction

function! s:GitOpenFile()
  let info = s:GitGetFileInfo()
  if info is v:null | return | endif
  if info.status ==# 'D' | echo 'File deleted in working tree' | return | endif

  let review_win = win_getid()
  wincmd p | execute 'edit ' . fnameescape(info.file) | call win_gotoid(review_win)
endfunction

function! s:GitDiffFile(split_type)
  let info = s:GitGetFileInfo()
  if info is v:null | return | endif

  let ref = b:review_git_ref
  let current_line = line('.')

  wincmd p | if &diff | diffoff | endif | only

  " For deleted files, show diff between ref and empty buffer
  if info.status ==# 'D'
    execute 'Gedit ' . ref . ':' . info.file
    execute (a:split_type ==# 'vertical' ? 'rightbelow vertical' : 'rightbelow') . ' new'
    setlocal buftype=nofile bufhidden=wipe noswapfile
    execute 'file ' . fnameescape(info.file . ' (deleted)')
    diffthis
    wincmd p | diffthis
  else
    execute 'edit ' . fnameescape(info.file)
    execute (a:split_type ==# 'vertical' ? 'leftabove vertical' : 'leftabove') . ' Gdiffsplit ' . ref
    wincmd p
  endif

  botright 12split | execute 'buffer ' . bufnr('[Review] Git: ' . ref)
  call cursor(current_line, 1) | wincmd k
endfunction

function! s:GitCloseDiff()
  let review_win = win_getid()
  wincmd p
  if &diff
    diffoff | wincmd w | if &diff | close | endif
  endif
  call win_gotoid(review_win)
endfunction
" }}

" fzf {{
command! -bang -nargs=* Rg
  \ cexpr system('rg --column --line-number --no-heading --smart-case ' . shellescape(<q-args>))
  \ | copen
nnoremap <silent> <C-P> :Files!<cr>
noremap <silent> t] :Tags <C-R><C-W><cr>
noremap <silent> g] :call fzf#vim#tags(expand('<cword>')) <cr>
cabbrev rg Rg

" }}

" coc.nvim {{
set nobackup              " Some servers have issues with backup files
set nowritebackup
set updatetime=300        " Having longer updatetime (default is 4000 ms = 4s) leads to noticeable  delays and poor user experience
set signcolumn=yes        " Always show the signcolumn, otherwise it would shift the text each time diagnostics appear/become resolved
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}   " add statusline
set tagfunc=CocTagFunc    " Used C+], C+t to jump back and ford

" tab completion
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" show review window
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction
nnoremap <silent> K :call ShowDocumentation()<CR>

" navigation
function! s:DoNavigation(action) 
  try
    if CocAction(a:action)
      return v:true
    endif
  catch " do nothing
  endtry
  let ret = execute("silent! normal g]>")
  if ret =~ "Error"
    call searchdecl(expand('<cword>'))
  endif
endfunction

augroup coc_keymaps
  autocmd!
  autocmd VimEnter * call s:setup_coc_keymaps()
augroup END

function! s:setup_coc_keymaps()
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
  inoremap <silent><expr> <C-@> coc#refresh()

  " diagnostic
  nmap <silent> ]g <Plug>(coc-diagnostic-prev)
  nmap <silent> [g <Plug>(coc-diagnostic-next)

  nmap <silent> gd :call <SID>DoNavigation('jumpDefinition')<cr>
  nmap <silent> gy :call <SID>DoNavigation('jumpTypeDefinition')<cr>
  nmap <silent> gi :call <SID>DoNavigation('jumpImplementation')<cr>
  nmap <silent> gr :call <SID>DoNavigation('jumpReferences')<cr>
  xmap <leader>f  <Plug>(coc-format-selected)
  nmap <leader>f  <Plug>(coc-format-selected)

  " Show a list of all available code actions (refactor, fix, etc.)
  nmap <silent> <leader>ca <Plug>(coc-codeaction)
  vmap <silent> <leader>ca <Plug>(coc-codeaction-selected)
  " Apply the most preferred quickfix action to fix diagnostic on the current line
  nmap <leader>cf  <Plug>(coc-fix-current)

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
  nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
  nnoremap <silent> <nowait> <leader>dt :call CocAction('diagnosticToggle')<cr>
  " }}
endfunction


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
set diffopt+=followwrap

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
cabbrev grep Grep
cabbrev gr Gr

" }}

" }}}

" {{ command alias
cabbrev now put =strftime('%Y-%m-%d %H:%M')

" }}}

" {{{ toggle relative number
augroup numbertogglegroup
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup end
" }}

" {{ simple autopair
let g:pairs = {'(':')', '[':']', '{':'}', '"':'"', "'":"'", '`':'`'}

" Get characters before and after cursor
function! s:AutoPairContext()
  let [line, col] = [getline('.'), col('.') - 1]
  return [col > 0 ? line[col-1] : '', col < len(line) ? line[col] : '']
endfunction

" Insert opening char and closing pair
function! s:AutoPairInsertOpen(open, close)
  return a:open . a:close . "\<Left>"
endfunction

" Jump over closing char or insert quote
function! s:AutoPairInsertClose(char)
  let [before, after] = s:AutoPairContext()
  " Jump over matching closing char
  if after == a:char | return "\<Right>" | endif
  " For quotes: insert pair only after non-word chars
  if get(g:pairs, a:char, '') == a:char && before !~ '\w'
    return a:char . a:char . "\<Left>"
  endif
  " Default: just insert
  return a:char
endfunction

" Delete pair together
function! s:AutoPairDelete()
  let [before, after] = s:AutoPairContext()
  return before != '' && has_key(g:pairs, before) && g:pairs[before] == after ? "\<BS>\<Del>" : "\<BS>"
endfunction

" Return between pairs
function! s:AutoPairReturn()
  let [before, after] = s:AutoPairContext()
  return before != '' && get(g:pairs, before, '') == after ? "\<CR>\<CR>\<Up>\<Tab>" : "\<CR>"
endfunction

" Create mappings
for [open, close] in items(g:pairs)
  if open != close " open == close, only need map close
    exe 'inoremap <silent>' open '<C-R>=<SID>AutoPairInsertOpen("'.escape(open, '\"').'", "'.escape(close, '\"').'")<CR>'
  endif
  exe 'inoremap <silent>' close '<C-R>=<SID>AutoPairInsertClose("'.escape(close, '\"').'")<CR>'
endfor

inoremap <silent> <BS> <C-R>=<SID>AutoPairDelete()<CR>
inoremap <silent> <CR> <C-R>=<SID>AutoPairReturn()<CR>
" }}

" {{ auto load local vimrc recursively
set secure " enable secure mode when load local vimrc inside sandbox

function! LoadCascadingLocalRc()
  let l:current_dir = expand('%:p:h')
  if l:current_dir ==# ''
    return
  endif
  let l:dirs = []
  let l:parent_dir = l:current_dir
  let l:previous_dir = ''
  while l:parent_dir !=# l:previous_dir
    call add(l:dirs, l:parent_dir)
    let l:previous_dir = l:parent_dir
    let l:parent_dir = fnamemodify(l:parent_dir, ':h')
  endwhile
  call reverse(l:dirs)
  for l:dir in l:dirs
    let l:exrc = l:dir . '/.exrc'
    if filereadable(l:exrc)
      silent execute 'sandbox source' fnameescape(l:exrc)
    endif
  endfor
endfunction

autocmd BufEnter * call LoadCascadingLocalRc()
" }}

" -----------------------------------------------------------------------------
" Specific settings for specific filetypes:	{{{

" usual policy: if there is a Makefile present, :mak calls make, otherwise we define a command to compile the filetype

" C/C++:
function! CPPSET()
  set noexpandtab
  " set foldmethod=marker
  " set foldmarker={,}
  command! -nargs=? -complete=dir Gr :cexpr
        \ system("grep -rnI --include='*.h' --include='*.cpp' --include='*.c' --include='*.cc' " . shellescape(<q-args>)) | copen
  command! -bang -nargs=* Rg :cexpr
        \ system('rg --column --line-number --no-heading --smart-case -t c -t cpp ' . shellescape(<q-args>)) | copen
  nnoremap <buffer> <F9> :w<cr>:!g++ -g -Wall -Wextra -Wshadow -O2 % -o %< -std=c++14 -I ./<cr>:!exec %:p:r<cr>
  nnoremap <buffer> <F8> :w<cr>:!g++ -g -Wall -Wextra -Wshadow -O2 % -o %< -std=c++14 -I ./<cr>
endfunction

" Java
function! JAVASET()
  set makeprg=if\ \[\ -f\ \"Makefile\"\ \];then\ make\ $*;else\ if\ \[\ -f\ \"makefile\"\ \];then\ make\ $*;else\ javac\ -g\ %;fi;fi
  set cindent
  set nowrap
  set foldmethod=marker
  set foldmarker={,}
  command! -nargs=? -complete=dir Gr :cexpr
        \ system("grep -rnI --include='*.java' " . shellescape(<q-args>)) | copen
  command! -bang -nargs=* Rg :cexpr
        \ system('rg --column --line-number --no-heading --smart-case -t c -t java ' . shellescape(<q-args>)) | copen
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
        \ system("grep -rnI --include='*.rs' " . shellescape(<q-args>)) | copen
  command! -bang -nargs=* Rg :cexpr
        \ system('rg --column --line-number --no-heading --smart-case -t c -t rust ' . shellescape(<q-args>)) | copen
  " set makepgr=cargo
  nnoremap <buffer> <F8> :w<cr>:!rustc % <cr>
  nnoremap <buffer> <F9> :w<cr>:!rustc % <cr>:!./%<<cr>
endfunction

" Beautify JSON
nmap =j :%!python -m json.tool<CR>

" Templates
let s:git_name = substitute(system('git config user.name'), '\n\+$', '', '')
let s:git_email = substitute(system('git config user.email'), '\n\+$', '', '')
let g:code_author = s:git_name . ' (' . s:git_email . ')'

command! Template call s:LoadTemplate()

function! s:LoadTemplate()
    let l:type = &filetype
    if l:type == ''
        let l:type = expand('%:e')
    endif

    let l:template_path = expand('~/.vim/templates/template.' . l:type)
    if !filereadable(l:template_path)
        echo "Template not found: " . l:template_path . " (Filetype: " . l:type . ")"
        return
    endif

    let l:content = readfile(l:template_path)
    let l:output = []
    let l:cursor_pos = [0, 0]
    let l:row = 1
    for l:line in l:content
        let l:line = substitute(l:line, '{{FILE}}', expand('%:t'), 'g')
        let l:line = substitute(l:line, '{{AUTHOR}}', g:code_author, 'g')
        let l:line = substitute(l:line, '{{DATE}}', strftime('%Y-%m-%d %H:%M:%S'), 'g')
        if l:line =~ '{{CURSOR}}'
            let l:col = stridx(l:line, '{{CURSOR}}')
            let l:line = substitute(l:line, '{{CURSOR}}', '', '')
            let l:cursor_pos = [l:row, l:col + 1]
        endif

        call add(l:output, l:line)
        let l:row += 1
    endfor

    call setline(1, l:output)
    if l:cursor_pos[0] != 0
        call cursor(l:cursor_pos[0], l:cursor_pos[1])
    endif
endfunction

" Remove trailing spaces
autocmd BufWritePre * :%s/\s\+$//e

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

