" Name: Vim bookmark
" Author: Name5566 <name5566@gmail.com>
" Version: 0.3.0

if exists('loaded_vbookmark')
	finish
endif
let loaded_vbookmark = 1

let s:savedCpo = &cpo
set cpo&vim
let g:isBroken = 0

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Sign
"""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight Custom1 ctermfg=darkblue ctermbg=235
highlight Custom2 ctermfg=black ctermbg=green

exec 'sign define vbookmark_sign text=++ texthl=Custom1'

function! s:Vbookmark_placeSign(id, file, lineNo)
""    let signStr = 'sign define vbookmark_sign text='
""    let signStr .= a:id - 100
""    let signStr .= ' texthl=search'
""
""    exec signStr

	exec 'sign place ' . a:id
		\ . ' line=' . a:lineNo
		\ . ' name=vbookmark_sign'
		\ . ' file=' . a:file
endfunction

function! s:Vbookmark_unplaceSign(id, file)
	exec 'sign unplace ' . a:id
		\ . ' file=' . a:file
endfunction

function! s:Vbookmark_jumpSign(id, file)
	exec 'sign jump ' . a:id
		\ . ' file=' . a:file
endfunction

" I don't like this implementation
function! s:Vbookmark_getSignId(line)
	let savedZ = @z
	redir @z
	silent! exec 'sign place buffer=' . winbufnr(0)
	redir END
	let output = @z
	let @z = savedZ

	let match = matchlist(output, '    \S\+=' . a:line . '  id=\(\d\+\)')
	if empty(match)
		return -1
	else
		return match[1]
	endif
endfun


"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Bookmark
"""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:Vbookmark_initVariables()
	let s:vbookmark_groups = []
	let s:vbookmark_curGroupIndex = s:Vbookmark_addGroup('default')
endfunction

function! s:Vbookmark_isSignIdExist(id)
	let group = s:vbookmark_groups[s:vbookmark_curGroupIndex]
	for mark in group.marks
		if mark.id == a:id
			return 1
		endif
	endfor
	return 0
endfunction

function! s:Vbookmark_generateSignId()
	if !exists('s:vbookmark_signSeed')
		let s:vbookmark_signSeed = 100
	endif
	while s:Vbookmark_isSignIdExist(s:vbookmark_signSeed)
		let s:vbookmark_signSeed += 1
	endwhile
	return s:vbookmark_signSeed
endfunction

function! s:Vbookmark_adjustCurGroupIndex()
	let size = len(s:vbookmark_groups)
	let s:vbookmark_curGroupIndex = s:vbookmark_curGroupIndex % size
	if s:vbookmark_curGroupIndex < 0
		let s:vbookmark_curGroupIndex += size
	endif
endfunction

function! s:Vbookmark_adjustCurMarkIndex()
	let group = s:vbookmark_groups[s:vbookmark_curGroupIndex]
	let size = len(group.marks)
	let group.index = group.index % size
	if group.index < 0
		let group.index += size
	endif
endfunction

function! Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! s:Vbookmark_setBookmark(line)
	let id = s:Vbookmark_generateSignId()
	let file = expand("%:p")
	if file == ''
		echo "No valid file name"
		return
	endif
    let bufline = getline('.')
    let tripline = Strip(bufline)
	call s:Vbookmark_placeSign(id, file, a:line)
	let group = s:vbookmark_groups[s:vbookmark_curGroupIndex]
	call add(group.marks, {'id': id, 'file': file, 'bufline': tripline, 'line': a:line})
endfunction

function! s:Vbookmark_unsetBookmark(id)
	let marks = s:vbookmark_groups[s:vbookmark_curGroupIndex].marks
	let i = 0
	let size = len(marks)
	while i < size
		let mark = marks[i]
		if mark.id == a:id
			call s:Vbookmark_unplaceSign(mark.id, mark.file)
			call remove(marks, i)
			call s:Vbookmark_adjustCurMarkIndex()
			break
		endif
		let i += 1
	endwhile
endfunction

function! s:Vbookmark_refreshSign(file)
	let marks = s:vbookmark_groups[s:vbookmark_curGroupIndex].marks
	for mark in marks
		if mark.file == a:file
			call s:Vbookmark_placeSign(mark.id, mark.file, mark.line)
		endif
	endfor
endfunction

function! s:Vbookmark_jumpBookmark(method)
	let group = s:vbookmark_groups[s:vbookmark_curGroupIndex]
	if empty(group.marks)
        echo "No bookmarks found"
		return
	endif

	if a:method == 'next'
		let group.index += 1
	elseif a:method == 'prev'
		let group.index -= 1
	endif
	call s:Vbookmark_adjustCurMarkIndex()

	let mark = group.marks[group.index]
	try
		call s:Vbookmark_jumpSign(mark.id, mark.file)
	catch
        echo "problem"
		if !filereadable(mark.file)
			call remove(group.marks, group.index)
			call s:Vbookmark_adjustCurMarkIndex()
			call s:Vbookmark_jumpBookmark(a:method)
			return
		endif
		exec 'e ' . mark.file
		call s:Vbookmark_refreshSign(mark.file)
		call s:Vbookmark_jumpSign(mark.id, mark.file)
	endtry
endfunction

function! s:Vbookmark_placeAllSign()
	let marks = s:vbookmark_groups[s:vbookmark_curGroupIndex].marks
	for mark in marks
		try
			call s:Vbookmark_placeSign(mark.id, mark.file, mark.line)
		catch
		endtry
	endfor
endfunction

function! s:Vbookmark_unplaceAllSign()
	let marks = s:vbookmark_groups[s:vbookmark_curGroupIndex].marks
	for mark in marks
		try
			call s:Vbookmark_unplaceSign(mark.id, mark.file)
		catch
		endtry
	endfor
endfunction

function! s:Vbookmark_clearAllBookmark()
	call s:Vbookmark_unplaceAllSign()
	call s:Vbookmark_initVariables()
endfunction

function! s:Vbookmark_addGroup(name)
    let s:vbookmark_signSeed = 100
	call add(s:vbookmark_groups, {'name': a:name, 'marks': [], 'index': -1})
	return len(s:vbookmark_groups) - 1
endfunction

function! s:Vbookmark_removeGroup(name)
	if len(s:vbookmark_groups) <= 1
        echo "Cann't remove the last bookmark group"
		return
	endif

	let curGroupName = s:vbookmark_groups[s:vbookmark_curGroupIndex].name
	if curGroupName =~ '^' . a:name
		call s:Vbookmark_unplaceAllSign()
		call remove(s:vbookmark_groups, s:vbookmark_curGroupIndex)
		call s:Vbookmark_adjustCurGroupIndex()
		call s:Vbookmark_placeAllSign()
		echo 'Remove the current bookmark group ' . curGroupName
			\ . '. Open the bookmark group ' . s:vbookmark_groups[s:vbookmark_curGroupIndex].name
		return
	endif

	let i = 0
	let size = len(s:vbookmark_groups)
	while i < size
		let group = s:vbookmark_groups[i]
		if group.name =~ '^' . a:name
			call remove(s:vbookmark_groups, i)
			if i < s:vbookmark_curGroupIndex
				let s:vbookmark_curGroupIndex -= 1
			endif
			echo 'Remove the bookmark group ' . group.name
			return
		endif
		let i += 1
	endwhile

	echo 'No bookmark group ' . a:name . ' found'
endfunction

function! s:Vbookmark_openGroup(name)
	if s:vbookmark_groups[s:vbookmark_curGroupIndex].name =~ '^' . a:name
		return 1
	endif

	let i = 0
	let size = len(s:vbookmark_groups)
	while i < size
		let group = s:vbookmark_groups[i]
		if group.name =~ '^' . a:name
			call s:Vbookmark_unplaceAllSign()
			let s:vbookmark_curGroupIndex = i
			call s:Vbookmark_placeAllSign()
			echo 'Open the bookmark group ' . group.name
			return 1
		endif
		let i += 1
	endwhile
	return 0
endfunction

function! s:Vbookmark_listGroup()
	let i = 0
	let size = len(s:vbookmark_groups)
	while i < size
		let output = '  '
		if i == s:vbookmark_curGroupIndex
			let output = '* '
		endif
        let output .= i
        let output .= ' '
		let output .= s:vbookmark_groups[i].name
		echo output
		let i += 1
	endwhile
endfunction

function! s:Vbookmark_listBookMarks()
    let group = s:vbookmark_groups[s:vbookmark_curGroupIndex]
    let index = 0
    for mark in group.marks
        if index == group.index
          let output = '*'. (mark.id-100) . ' ' . mark.line . ' ' . mark.bufline . ' ' 
        else
          let output = ' '. (mark.id-100) . ' ' . mark.line . ' ' . mark.bufline . ' ' 
        endif
        let output .= '@@' . mark.file
        let index = index + 1
        echo output
    endfor
endfunction

function Vbookmark_goBookMark(...)
    let group = s:vbookmark_groups[s:vbookmark_curGroupIndex]
    let size = len(group.marks)
    let i = 0
    let markid= a:1 + 100
    while i < size
       if group.marks[i].id == markid
           break
       endif
       let i += 1 
    endwhile

    if i == size
        return
    endif

   	let group.index = i 
	let mark = group.marks[group.index]
	try
		call s:Vbookmark_jumpSign(mark.id, mark.file)
	catch
		if !filereadable(mark.file)
			call remove(group.marks, group.index)
			call s:Vbookmark_adjustCurMarkIndex()
			call s:Vbookmark_jumpBookmark(a:method)
			return
		endif
		exec 'e ' . mark.file
		call s:Vbookmark_refreshSign(mark.file)
		call s:Vbookmark_jumpSign(mark.id, mark.file)
	endtry
endfunction

function Vbookmark_goBookMarkGroup(...)
    if a:0 <= 0 || a:1 >= len(s:vbookmark_groups)
       return
    endif
	let group = s:vbookmark_groups[a:1]
    call s:Vbookmark_unplaceAllSign()
   	let s:vbookmark_curGroupIndex = a:1
	call s:Vbookmark_placeAllSign()
	echo 'Open the bookmark group ' . group.name
endfunction

function! s:Vbookmark_Go()
    let c = nr2char( getchar() )
    let isnum = match(c, '[0123456789]')
    if isnum == -1
       return
    endif

    let strid = ""
    while c != 'g'
        let strid .= c
        let c = nr2char( getchar() )
    endwhile
    let id = str2nr(strid, 10)
    call Vbookmark_goBookMark(id)
endfunction

function! s:Vbookmark_saveAllBookmark()
	if !exists('g:vbookmark_bookmarkSaveFile')
		return
	end

    if g:isBroken == 1
       return
    endif

	let outputGroups = 'let g:__vbookmark_groups__ = ['
	for group in s:vbookmark_groups
		let outputGroups .= '{"name": "' . group.name . '", "index": ' . group.index . ', "marks": ['
		for mark in group.marks
            let evalline = substitute(mark.bufline, "\\", "\\\\\\\\", 'g') 
            let evalline = substitute(evalline, '"', '\\"', 'g') 
            let evalline = substitute(evalline, '[', '\\[', 'g') 
            let evalline = substitute(evalline, ']', '\\]', 'g') 
            let evalline = substitute(evalline, '{', '\\{', 'g') 
            let evalline = substitute(evalline, '}', '\\}', 'g') 
            let evalline = substitute(evalline, ',', '\\,', 'g') 
            let evalline = substitute(evalline, ':', '\\:', 'g') 
            let evalline = substitute(evalline, "'", "\\'", 'g') 

			let outputGroups .= '{"id": ' . mark.id . ', "file": "' .  escape(mark.file, ' \') . '", "line": ' . mark.line . ', "bufline": "' .  evalline . '"' . '},'
		endfor
		let outputGroups .= ']},'
	endfor
	let outputGroups .= ']'
	let outputCurGroupIndex = "let g:__vbookmark_curGroupIndex__ = " . s:vbookmark_curGroupIndex
	call writefile([outputGroups, outputCurGroupIndex], g:vbookmark_bookmarkSaveFile)
endfunction

autocmd VimLeave * call s:Vbookmark_saveAllBookmark()

function! s:Vbookmark_loadAllBookmark()
	if !exists('g:vbookmark_bookmarkSaveFile') || !filereadable(g:vbookmark_bookmarkSaveFile)
		return
	end
	try
		exec 'source ' . g:vbookmark_bookmarkSaveFile
	catch
        let g:isBroken = 1
        echo "Bookmark save file is broken"
		return
	endtry
	if !exists('g:__vbookmark_groups__') || type(g:__vbookmark_groups__) != 3
		\ || !exists('g:__vbookmark_curGroupIndex__') || type(g:__vbookmark_curGroupIndex__) != 0
		echo "Bookmark save file is invalid"
		return
	end

	let s:vbookmark_groups = deepcopy(g:__vbookmark_groups__)
	let s:vbookmark_curGroupIndex = g:__vbookmark_curGroupIndex__
	call s:Vbookmark_placeAllSign()
	unlet g:__vbookmark_groups__
	unlet g:__vbookmark_curGroupIndex__
endfunction
autocmd VimEnter * call s:Vbookmark_loadAllBookmark()

call s:Vbookmark_initVariables()


"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:VbookmarkToggle()
	let line = line('.')
	let id = s:Vbookmark_getSignId(line)
	if id == -1
		call s:Vbookmark_setBookmark(line)
	else
		call s:Vbookmark_unsetBookmark(id)
	endif
endfunction

function! s:VbookmarkNext()
	call s:Vbookmark_jumpBookmark('next')
endfunction

function! s:VbookmarkPrevious()
	call s:Vbookmark_jumpBookmark('prev')
endfunction

function! s:VbookmarkClearAll()
	call s:Vbookmark_clearAllBookmark()
endfunction

function! s:VbookmarkGroup(name)
	if a:name == ''
		call s:Vbookmark_listGroup()
	elseif !s:Vbookmark_openGroup(a:name)
		call s:Vbookmark_unplaceAllSign()
		let s:vbookmark_curGroupIndex = s:Vbookmark_addGroup(a:name)
		echo 'Add a new bookmark group ' . a:name
	endif
endfunction

function! s:VbookmarkGroupRemove(name)
	let name = a:name
	if name == ''
		let name = s:vbookmark_groups[s:vbookmark_curGroupIndex].name
	endif
	call s:Vbookmark_removeGroup(name)
endfunction

if !exists(':VbookmarkToggle')
	command -nargs=0 VbookmarkToggle :call s:VbookmarkToggle()
endif

if !exists(':VbookmarkNext')
	command -nargs=0 VbookmarkNext :call s:VbookmarkNext()
endif

if !exists(':VbookmarkPrevious')
	command -nargs=0 VbookmarkPrevious :call s:VbookmarkPrevious()
endif

if !exists(':VbookmarkClearAll')
	command -nargs=0 VbookmarkClearAll :call s:VbookmarkClearAll()
endif

if !exists(':VbookmarkGroup')
	command -nargs=? VbookmarkGroup :call s:VbookmarkGroup(<q-args>)
endif

if !exists(':VbookmarkList')
	command -nargs=0 VbookmarkList :call s:Vbookmark_listBookMarks()
endif

if !exists(':Mg')
	command -nargs=1 Mg call Vbookmark_goBookMark(<f-args>)
endif

if !exists(':MG')
    command -nargs=1 MG call Vbookmark_goBookMarkGroup(<f-args>)
endif

if !exists(':VbookmarkGo')
	command -nargs=0 VbookmarkGo call s:Vbookmark_Go()
endif

if !exists(':VbookmarkGroupRemove')
	command -nargs=? VbookmarkGroupRemove :call s:VbookmarkGroupRemove(<q-args>)
endif

if !exists(':VbookmarkSave')
	command -nargs=0 VbookmarkSave call s:Vbookmark_saveAllBookmark()
endif

if !exists(':VbookmarkPlaceAll')
	command -nargs=0 VbookmarkPlaceAll call s:Vbookmark_placeAllSign()
endif

if !exists('g:vbookmark_disableMapping')
	nnoremap <silent> mm :VbookmarkToggle<CR>
	nnoremap <silent> mn :VbookmarkNext<CR>
	nnoremap <silent> mp :VbookmarkPrevious<CR>
	"nnoremap <silent> mc :VbookmarkClearAll<CR>
	nnoremap <silent> ml :VbookmarkList<CR>
    nnoremap <silent> mg :VbookmarkGo<CR>
    "nmap <expr> mg Vbookmark_Go()<CR>
endif

let &cpo = s:savedCpo
