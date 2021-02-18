" Location: autoload/filterLqList.vim
" Maintainer: Yogesh Dhamija <yogeshdhamija@outlook.com>

if(exists("g:autoloaded_filter_lq_list"))
    finish
endif
let g:autoloaded_filter_lq_list = 1

function! filterLqList#ReloadList() abort
    if(exists("g:filter_lq_list_changed") && g:filter_lq_list_changed)
        if(getwininfo(win_getid())[0]['loclist']) " is loclist
            w! /dev/null
            lgetbuffer 
            redraw!
            echo "Executed :set modifiable, deleted, then :lgetbuffer."
        else " is quickfix
            w! /dev/null
            cgetbuffer
            redraw!
            echo "Executed :set modifiable, deleted, then :cgetbuffer."
        endif
        let g:filter_lq_list_changed = 0
    endif
endfunction

