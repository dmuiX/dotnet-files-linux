colorscheme argonaut
set number
nnoremap <F3> :set number!<CR>
set smartindent
set autoindent
set shiftwidth=4
set tabstop=4
set pastetoggle=<F2>
set expandtab
set backspace=indent,eol,start

syntax on
highlight Normal ctermbg=None
highlight LineNr ctermfg=DarkGrey

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall
endif

call plug#begin('~/.vim/plugged')
        Plug 'vim-airline/vim-airline'
        Plug 'vim-airline/vim-airline-themes'
        Plug 'farmergreg/vim-lastplace'
        Plug 'elzr/vim-json'
        Plug 'vim-shairport/vim-shairport'
        Plug 'flazz/vim-colorschemes'
call plug#end()

let g:airline_powerline_fonts = 1
let g:kite_auto_complete=1
let g:airline#extensions#tabline#enabled = 1
let g:lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit"
let g:lastplace_ignore_buftype = "quickfix,nofile,help"
let g:lastplace_open_folds = 0
