call plug#begin('~/.vim/plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'dracula/vim', { 'as': 'dracula' }

call plug#end()

let g:airline_powerline_fonts = 1

set rtp+=/usr/local/opt/fzf

packadd! dracula
set number
syntax enable
colorscheme dracula
