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

" Everything that makes a list what it is, so a filter can put it all back.
let s:what = {'items': 0, 'title': 0, 'context': 0, 'quickfixtextfunc': 0, 'idx': 0}

function! s:IsLoc(winid) abort
    return getwininfo(a:winid)[0]['loclist']
endfunction

function! s:IsQf(winid) abort
    return getwininfo(a:winid)[0]['quickfix'] == 1
endfunction

function! s:Get(winid, what) abort
    return s:IsLoc(a:winid) ? getloclist(a:winid, a:what) : getqflist(a:what)
endfunction

" Which list, at which revision. The id alone isn't enough: setqflist(...,'r')
" reuses it, so another plugin refreshing the list in place looks identical.
function! s:Sig(winid) abort
    let l:props = s:Get(a:winid, {'id': 0, 'changedtick': 0})
    return [l:props['id'], l:props['changedtick']]
endfunction

function! s:Set(winid, what) abort
    if(s:IsLoc(a:winid))
        call setloclist(a:winid, [], 'r', a:what)
    else
        call setqflist([], 'r', a:what)
    endif
    call cursor(min([max([get(a:what, 'idx', 1), 1]), line('$')]), 1)
    " Adopt the revision we just created, so our own write isn't mistaken for
    " somebody else's on the next call.
    if(exists('b:filter_lq_list_undo'))
        let b:filter_lq_list_undo['sig'] = s:Sig(a:winid)
    endif
endfunction

" We replace the list in place rather than pushing a new one, so the quickfix
" stack keeps holding your actual greps -- :colder is not spent on filters.
" That means undo has to be ours. Drop the stack whenever the list was last
" touched by anything other than us (a new grep, an LSP refresh, another
" plugin): undoing one list's filter into a different list would be worse
" than having no undo at all.
function! s:Stack(winid) abort
    if(!exists('b:filter_lq_list_undo') || b:filter_lq_list_undo['sig'] != s:Sig(a:winid))
        let b:filter_lq_list_undo = {'sig': s:Sig(a:winid), 'undo': [], 'redo': []}
    endif
    return b:filter_lq_list_undo
endfunction

function! filterLqList#Remove(first, last) abort
    let l:winid = win_getid()
    if(!s:IsQf(l:winid))
        return
    endif

    let l:list = s:Get(l:winid, copy(s:what))
    let l:first = max([a:first, 1])
    let l:last = min([a:last, len(l:list['items'])])
    if(l:first > l:last)
        return
    endif

    let l:stack = s:Stack(l:winid)
    call add(l:stack['undo'], deepcopy(l:list))
    let l:stack['redo'] = []

    call remove(l:list['items'], l:first - 1, l:last - 1)
    " Leave the cursor on whatever slid up into the deleted spot, so repeated
    " dd's walk down the list the way they do in a normal buffer.
    let l:list['idx'] = min([l:first, max([len(l:list['items']), 1])])
    call s:Set(l:winid, l:list)
endfunction

function! s:Step(from, to, atEnd) abort
    let l:winid = win_getid()
    if(!s:IsQf(l:winid))
        return
    endif
    let l:stack = s:Stack(l:winid)
    if(empty(l:stack[a:from]))
        echo a:atEnd
        return
    endif
    call add(l:stack[a:to], s:Get(l:winid, copy(s:what)))
    call s:Set(l:winid, remove(l:stack[a:from], -1))
endfunction

function! filterLqList#Undo() abort
    call s:Step('undo', 'redo', 'Already at oldest change')
endfunction

function! filterLqList#Redo() abort
    call s:Step('redo', 'undo', 'Already at newest change')
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
    nnoremap <buffer> u <Cmd>call filterLqList#Undo()<CR>
    nnoremap <buffer> <C-r> <Cmd>call filterLqList#Redo()<CR>
endfunction
