" filter-lq-list.vim - filter location and quickfix lists
" Maintainer: Yogesh Dhamija <yogeshdhamija@outlook.com>
" Version 0.1

if(exists("g:loaded_filter_lq_list"))
    finish
endif
let g:loaded_filter_lq_list = 1

augroup FilterLqList
    autocmd!
    autocmd FileType qf nnoremap <buffer> d :set modifiable<CR>:let g:filter_lq_list_changed = 1<CR>d
    autocmd FileType qf xnoremap <buffer> d <Esc>:set modifiable<CR>:let g:filter_lq_list_changed = 1<CR>gvd
    autocmd TextChanged * call filterLqList#ReloadList()
augroup END
