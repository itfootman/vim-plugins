"Toggle Menu and Toolbar
set guioptions-=m
set guioptions-=T
map <silent> <S-F3> :if &guioptions =~# 'T' <Bar>
        \set guioptions-=T <Bar>
        \set guioptions-=m <Bar>
    \else <Bar>
        \set guioptions =T <Bar>
        \set guioptions =m <Bar>
    \endif<CR>

autocmd! GUIEnter * silent !wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
noremap <S-F10> :silent !wmctrl -r :ACTIVE: -b toggle,fullscreen<CR>

cmap <C-S-V>  <C-R>+
set guifont=Nimbus\ Mono\ L\ 14
