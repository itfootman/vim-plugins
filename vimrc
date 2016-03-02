set wildmenu
set foldmethod=manual
set sw=4
set sta
set backspace=2
set nocompatible
set number
filetype on
filetype plugin indent on
set nocp
set history=1000
"set autoindent
"set smartindent
"set autochdir
set tabstop=4
set expandtab
%retab!
set shiftwidth=4
set ruler
set incsearch
set hlsearch
""set enc=chinese
set winaltkeys=no
""set encoding=cp936
""set termencoding=utf-8
set fileencoding=utf-8
"set fileencodings=ucs-bom,utf-8,chinese,cp936,gbk
"set gfw=楷体:h11
"set guifont=SimKai:h14
set langmenu=zh_CN,utf-8
syntax enable
syntax on

function! <SID>setLily()
  set t_Co=256
  set background=dark
  colorscheme wombat256mod
endfunction

function! <SID>setSolarized()
  set background=dark
  set t_Co=16
  let g:solarized_termcolors=16
  let g:solarized_termtrans = 1
  colorscheme solarized
endfunction

let g:screen_col = str2nr(system('tput cols'))
set runtimepath^=~/.vim/bundle/vim-colors-solarized,
               \~/.vim/bundle/loadproject,
               \~/.vim/bundle/nerdtree,
               \~/.vim/bundle/tagbar,
               \~/.vim/bundle/neocomplcache.vim,
               \~/.vim/bundle/LeaderF,
               \~/.vim/bundle/OmniCppComplete,
               \~/.vim/bundle/command-t

if !has("gui_running")
  if $TERM_NAME  == "konsole"
    s:setSolarized()
  elseif $TERM_NAME == "gnome-terminal"
    colorscheme eclipse
  elseif $TERM_NAME == "lilyterm"
    call <SID>setLily()
  else
    if $MY_CLIENT == "ipad"
      call <SID>setLily()
    else
      ""call <sid>setSolarized()
      call <SID>setLily()
    endif
endif

"  set background=light
"  colorscheme seoul256
else
 colorscheme solarized
 "colorscheme desertEx
endif

let g:NERDTree_title='NERD Tree'
let g:NERDTreeWinSize = float2nr(0.37 * g:screen_col)
function! NERDTree_Start()
    exec 'NERDTree'
endfunction

function! NERDTree_IsValid()
    return 1
endfunction

let g:winManagerWindowLayout = "NERDTree|BufExplorer,Tarbar"


let g:Lf_SearchStep = 7000
let g:Lf_WildIgnore = {
    \ 'dir': ['.svn','.git','android-rt'],
    \ 'file': ['*.sw?','~$*','*.bak','*.exe','*.o','*.class','*.so','*.py[co]','*projectcfg','*.vtg','*.vpb','*.vpw','*.vpj','*.vpwhistu','*.zip','*.a','*.p','*.pp','*.O','*.PP','*.P','*.png','*.jpeg','*.jif','*.jar','*.patch','*.apk','*.tgz','*.gz','*.sed','*.log']
    \}

"Omnicppcomplete
let g:neocomplcache_enable_at_startup = 1 " Auto complete
let OmniCpp_MayCompleteArrow = 1 " autocomplete with ->
let OmniCpp_MayCompleteScope = 1 " autocomplete with ::
let OmniCpp_SelectFirstItem = 2 " select first item (but don't insert)
let OmniCpp_NamespaceSearch = 2 " search namespaces in this and included files
let OmniCpp_ShowPrototypeInAbbr = 1 " show function prototype  in popup window
let OmniCpp_GlobalScopeSearch=1
let OmniCpp_DisplayMode=1
let OmniCpp_DefaultNamespaces=["std"]"

let g:winManagerWidth = float2nr(0.37 * g:screen_col)
let g:Tlist_WinWidth =  float2nr(0.37 * g:screen_col)
let g:tagbar_width =    float2nr(0.37 * g:screen_col)

let g:miniBufExplMapCTabSwitchBufs = 1 " 供过tab切换窗口（这个好像没有发挥作用，不知道为什么）
let g:miniBufExplMapWindowNavVim = 1 " 通过h,j,k,l切换窗口
let g:miniBufExplMapWindowNavArrows = 1 " 通过方向键切换窗口
let g:bufExplorerSortBy='mru'

let g:CommandTMaxFiles=400000

""let Tlist_Show_One_File=1 " 仅显示当前文件的tags目录
""let Tlist_Exit_OnlyWindow=1 " 当仅剩下taglist窗口的时候启动关闭
""let Tlist_Inc_Winwidth=0
""let Tlist_Use_Right_Window=1
"let Tlist_File_Fold_Auto_Close=1


"autocmd VimLeave * mks! ~/.vim/vimsession.vim
"match DiffAdd '\%>80v.*'
"highlight OverLength ctermfg=magenta guibg=#592929
"match OverLength /\%81v.\+/
"

function! <SID>ShowTabSpace()
set list
set listchars=tab:>-,trail:-
endfunction

function! <SID>HideTabSpace()
set nolist
endfunction

function! <SID>TrimTailSpace()
:%s/ *$//
endfunction

function! <SID>ConvertTabToSpace()
set expandtab
%retab!
endfunction

function! <SID>CopyPath()
    let @+=expand("%:p:h")
endfunction

function! <SID>CopyFilePathName()
    let @+=expand("%:p")
endfunction

function! <SID>CopyFileName()
    let @+=expand("%:t")
endfunction


function ShowFuncTag()
    let wordUnderCursor = expand("<cword>")
    execute ":ptag " . wordUnderCursor
endfunction

function ShowTag()
    let wordUnderCursor = expand("<cword>")
    execute ":tselect " . wordUnderCursor
endfunction

"Open file in project
"The value will be set in 'loadproject.vim'
let g:project_root = ''
function! <SID>OpenFileInProject()
    let openCmd = ":Leaderf " . g:project_root
    echo openCmd
    execute openCmd
endfunction

"Activate bookmarks placed to source files.
function! <SID>PlaceBookmarks()
  if filereadable(g:vbookmark_bookmarkSaveFile)
    execute ":VbookmarkPlaceAll"
  endif
endfunction

if has("autocmd")
   autocmd BufRead *.txt set tw=78
   "autocmd BufEnter * call <SID>ShowTabSpace()
   autocmd BufReadPost * if line("'\"") > 0 && line ("'\"") <= line("$") | exe "normal g'\"" |  endif
endif

"nmap gf :tabedit <cfile><CR>
nmap <S-F5> :call <SID>ShowTabSpace()<CR>
nmap <S-F6> :call <SID>HideTabSpace()<CR>
nmap <S-F7> :call <SID>ConvertTabToSpace()<CR>
nmap <S-F8> :call <SID>TrimTailSpace()<CR>
nmap <S-F9> :files<CR>
nmap <F10> :call <SID>OpenFileInProject()<CR>
nmap <F6> :call <SID>CopyPath()<CR>
nmap <F7> :call <SID>CopyFilePathName()<CR>
nmap <F8> :call <SID>CopyFileName()<CR>
nmap <F4> :TagbarToggle<CR>
nmap <C-F8> :set mouse=a<CR>
nmap <C-F9> :set mouse=<CR>
nmap <C-F3> :call ShowFuncTag()<CR>
nmap <C-F4> :pclose<CR>
nmap <C-S-y> :redo<CR>
"map <F9> :NERDTreeToggle<cr>
map <F3> :WMToggle<cr>
nmap lsm :VbookmarkGroup<CR>
nmap <C-F10> :VbookmarkSave<CR>
"nmap <C-F9> :VbookmarkClearAll<CR>
map <C-g> "+y$
map <C-y> "+y
nnoremap <C-F7> :set invpaste paste?<CR>
set pastetoggle=<C-F7>
set showmode
nnoremap <c-]> g<c-]>
