set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'git://git.wincent.com/command-t.git'
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'preservim/nerdtree'
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'
Plugin 'airblade/vim-gitgutter' 
Plugin 'joshdick/onedark.vim'
Plugin 'Zenburn'
Plugin 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}
Plugin 'voldikss/vim-floaterm'
Plugin 'prettier/vim-prettier', {'do': 'yarn install'}
Plugin 'apzelos/blamer.nvim'
Plugin 'tpope/vim-commentary'
call vundle#end()            " required
filetype plugin indent on    " required

colorscheme zenburn
syntax on
set backspace=indent,eol,start
set number
set signcolumn=auto
set expandtab
set shiftwidth=4
set tabstop=4
set is hls

let g:fzf_preview_window = 'right:50%'
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6  }  }
let $FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%' --layout reverse --margin=1,4 --preview 'bat --theme=Zenburn --color=always --style=header,grid --line-range :300 {}'"
let $FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'

nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
" nnoremap <C-W>] :exec "vert norm <C-V><C-W>f"<CR>
nnoremap <c-w>[ <c-w>v<c-]>
nmap <silent> <C-N> :GFiles<CR>
nmap <silent> <C-F> :Ag<CR>
map <leader>r :NERDTreeFind<cr>
nmap <C-G> :GitGutterBufferToggle<CR>
" nmap <C-Q> :FloatermToggle<CR>
nmap <Leader>p :PrettierPartial<CR>
nmap <Leader>o :NERDTreeToggle<CR>
xmap <Leader>p :PrettierPartial<CR>
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>"

" --------------------------------------------------------
" SETTINGS START

set completeopt=longest,menuone

" SETTINGS END
" --------------------------------------------------------

" --------------------------------------------------------
" COC-VIM TAB SETTINGS START

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
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
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
" <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif
inoremap <silent><expr> <c-space> coc#refresh()
" COC-VIM TAB SETTINGS END
" --------------------------------------------------------
