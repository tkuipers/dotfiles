set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call plug#begin()
Plug 'VundleVim/Vundle.vim'
Plug 'tpope/vim-fugitive'
Plug 'git://git.wincent.com/command-t.git'
Plug 'rstacruz/sparkup', {'rtp': 'vim/'}
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'preservim/nerdtree'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'joshdick/onedark.vim'
Plug 'voldikss/vim-floaterm'
Plug 'prettier/vim-prettier', {'do': 'yarn install'}
Plug 'apzelos/blamer.nvim'
Plug 'tpope/vim-commentary'
Plug 'ianding1/leetcode.vim'
Plug 'catppuccin/vim', { 'as': 'catppuccin' }
call plug#end()            " required
filetype plugin indent on    " required

syntax on
set backspace=indent,eol,start
set number
set signcolumn=auto
set expandtab
set shiftwidth=4
set tabstop=4
set is hls
set termguicolors
let g:airline_theme='bubblegum'


nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <c-w>[ <c-w>v<c-]>
nmap <silent> <C-N> :GFiles<CR>
nmap <silent> <C-F> :Ag<CR>
map <leader>r :NERDTreeFind<cr>
nmap <C-G> :GitGutterBufferToggle<CR>
nmap <Leader>p :PrettierPartial<CR>
nmap <Leader>o :NERDTreeToggle<CR>
xmap <Leader>p :PrettierPartial<CR>
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>"

" --------------------------------------------------------
" SETTINGS START

set completeopt=longest,menuone

" nmap <C-Q> :FloatermToggle<CR>
" SETTINGS END
" --------------------------------------------------------
