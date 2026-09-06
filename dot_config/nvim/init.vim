filetype plugin on
filetype indent on

syntax on

set autoindent
set backspace=indent,eol,start

" Set the default indentation to 2 spaces for all files
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

" Highlight trailing whitespace in all files
autocmd BufRead,BufNewFile * match Error /\s\+$/

colorscheme sorbet
set background=dark

set number
set relativenumber
