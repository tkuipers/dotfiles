let mapleader = "\<Space>"

nnoremap <F3> :set hlsearch!<CR>
set number


set tabstop=4
set softtabstop=4
set shiftwidth=4
set noexpandtab

set smartindent
syntax on

set ignorecase
set smartcase
set termguicolors

set foldmethod=indent " fold based on indentation
set foldnestmax=10 " deepest fold is 10 levels
set nofoldenable " disable fold by default
set foldlevel=1

nnoremap <leader>j <C-W><C-H>
nnoremap <leader>; <C-W><C-L>
nnoremap <leader>k <C-W><C-J>
nnoremap <leader>l <C-W><C-K>

nnoremap j h
nnoremap k j
nnoremap l k
nnoremap ; l

nnoremap ba :diffget BA<CR>
nnoremap re :diffget RE<CR>
nnoremap lo :diffget LO<CR>
nnoremap rr :edit<CR>

let base16colorspace=256
colorscheme base16-default-dark
