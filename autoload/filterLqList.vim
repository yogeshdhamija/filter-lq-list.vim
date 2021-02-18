" Location: autoload/filterLqList.vim
" Maintainer: Yogesh Dhamija <yogeshdhamija@outlook.com>

if(exists("g:autoloaded_filter_lq_list"))
    finish
endif
let g:autoloaded_filter_lq_list = 1

function! filterLqList#ReloadList() abort
    if(getwininfo(win_getid())[0]['loclist']) " is loclist
        lgetbuffer 
        redraw!
        echo "Executed :set modifiable, deleted, then :lgetbuffer."
    else " is quickfix
        cgetbuffer
        redraw!
        echo "Executed :set modifiable, deleted, then :cgetbuffer."
    endif
endfunction

