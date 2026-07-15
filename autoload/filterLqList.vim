" Location: autoload/filterLqList.vim
" Maintainer: Yogesh Dhamija <yogeshdhamija@outlook.com>

if(exists("g:autoloaded_filter_lq_list"))
    finish
endif
let g:autoloaded_filter_lq_list = 1

" In a quickfix/location window, buffer line N is always entry N of the list --
" Neovim renders exactly one line per entry, whatever the entry looks like. So
" filtering is just "drop entries first..last"; the rendered text never has to
" be read or parsed. That keeps the entries themselves intact (end_col, type,
" module, user_data, ...), and keeps us out of the way of 'quickfixtextfunc'.

function! s:IsLoc(winid) abort
    return getwininfo(a:winid)[0]['loclist']
endfunction

function! filterLqList#Remove(first, last) abort
    let l:winid = win_getid()
    if(getwininfo(l:winid)[0]['quickfix'] != 1)
        return
    endif

    let l:what = {'items': 0, 'title': 0, 'context': 0, 'quickfixtextfunc': 0}
    let l:list = s:IsLoc(l:winid) ? getloclist(l:winid, l:what) : getqflist(l:what)

    let l:first = max([a:first, 1])
    let l:last = min([a:last, len(l:list['items'])])
    if(l:first > l:last)
        return
    endif
    call remove(l:list['items'], l:first - 1, l:last - 1)

    " Leave the cursor on whatever slid up into the deleted spot, so repeated
    " dd's walk down the list the way they do in a normal buffer.
    if(!empty(l:list['items']))
        let l:list['idx'] = min([l:first, len(l:list['items'])])
    endif

    if(s:IsLoc(l:winid))
        call setloclist(l:winid, [], 'r', l:list)
    else
        call setqflist([], 'r', l:list)
    endif

    call win_execute(l:winid, 'call cursor(min([' . l:first . ', line("$")]), 1)')
endfunction

" Operator, so counts and motions come from Vim rather than being reimplemented:
" dd, 3dd, d5j, dG, dap all arrive here as a line range.
function! filterLqList#Operator(...) abort
    if(a:0)
        call filterLqList#Remove(line("'["), line("']"))
        return ''
    endif
    set operatorfunc=filterLqList#Operator
    return 'g@'
endfunction

function! filterLqList#Attach() abort
    " <expr> keeps a pending count intact; the old ':'-based mapping ate it,
    " which is why 5dd used to delete a single line.
    nnoremap <buffer><expr> d filterLqList#Operator()
    nnoremap <buffer><expr> dd filterLqList#Operator() . '_'
    xnoremap <buffer> d :<C-u>call filterLqList#Remove(line("'<"), line("'>"))<CR>
endfunction
