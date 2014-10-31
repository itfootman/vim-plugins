"Load Project Config
"2014-03-12, Broton Bi
"
"  -This is for loading project's  config file.

if exists("loaded_LoadTags")
  finish
endif
let loaded_LoadTags = 1

let s:error_list = {"OK":0,"INVALID_PATH":-1,"NOT_PROJECT":-2}
let s:project_cfg_name = ".projectcfg"
let s:key_project_root = "projectRoot"
let s:key_tag_path = "tagPath"
let s:key_tag_name = "tagName"
let s:key_bookmarks_path = "bookmarksPath"
let s:key_bookmarks_name = "bookmarksName"
let s:key_session_path = "sessionPath"
let s:key_session_name = "sessionName"
let s:key_project_cfg_folder = "projectCfgFolder"
let s:key_project_includes = "projectIncludes"
let s:key_external_folders = "externalFolders"
let s:key_external_includes = "externalIncludes"
let s:key_external_tag_name = "externalTagName"
"let g:project_cfg[s:key_external_tag_name] = ".tags"
let g:project_cfg = {}
let g:external_folders = []

let g:project_cfg[s:key_tag_path] = "."
let g:project_cfg[s:key_tag_name] = "tags"
let g:project_cfg[s:key_bookmarks_path] = "."
let g:project_cfg[s:key_bookmarks_name] = "bookmarks"
let g:project_cfg[s:key_session_path] = "."
let g:project_cfg[s:key_session_name] = "mysession"
let g:project_cfg[s:key_project_cfg_folder] = ".vimproject"
let g:project_cfg[s:key_external_tag_name] = ".tags"

function! s:stripspaces(input_string)
  return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! s:stripnewlines(input_string)
  return substitute(a:input_string, '^\n*\(.\{-}\)\n*$', '\1', '')
endfunction

"Find project config and load it
function! s:loadProjectCfg()
  let splash = '/'
  let projectCfgName = s:project_cfg_name
  let here = s:stripnewlines(system("pwd")).splash
 
  let pathItems = split(here, splash)
  let pathStep = "" 
  let configItems = []
  for item in pathItems
    let item = s:stripnewlines(item)
    let pathStep =  pathStep.'/'.item
    if !isdirectory(pathStep)
      return s:error_list['INVALID_PATH']
    elseif filereadable(pathStep.'/'.projectCfgName)
      let foundProjecConfig = 1
      let g:project_cfg[s:key_project_root] = pathStep
      let configItems = readfile(pathStep.'/'.projectCfgName, '', 50)
      break
    endif
  endfor

  " Return if project config not found
  if !has_key(g:project_cfg, s:key_project_root) 
    return s:error_list['NOT_PROJECT']
  endif
 
  " For CtrlP
  let g:project_root = g:project_cfg[s:key_project_root]

  for configItem in configItems
    " Line is a comment
    if match(configItem, '^#\+\(.*\)') != -1
      continue
    endif
    let keyValues = split(configItem, "=")
    let index = 1
    let key = ""
    for keyValue in keyValues
      if index > 2
        break
      endif

      let keyValue = s:stripspaces(keyValue)
      if keyValue == ""
        continue
      endif
      if index == 1
        let key = keyValue
      elseif index == 2
        if key == s:key_project_root 
          if keyValue != "." &&
        \    isdirectory(g:project_cfg[s:key_project_root])
            let g:project_cfg[key] = keyValue 
          endif
        else
            let g:project_cfg[key] = keyValue 
        endif
      endif
      let index = index + 1
    endfor
  endfor

  if !isdirectory(g:project_cfg[s:key_project_root].'/'.
    \ g:project_cfg[s:key_project_cfg_folder])
    exe ':silent !mkdir '.g:project_cfg[s:key_project_root].'/'.
    \ g:project_cfg[s:key_project_cfg_folder] 
  endif

  let tagPath = g:project_cfg[s:key_project_root].'/'.
              \ g:project_cfg[s:key_project_cfg_folder]
  let tagName = g:project_cfg[s:key_tag_name]
  if has_key(g:project_cfg, s:key_tag_path) &&
  \  isdirectory(g:project_cfg[s:key_tag_path])
     if g:project_cfg[s:key_tag_path] != "."
       let tagPath = g:project_cfg[s:key_tag_path]
     endif
  endif
  let g:project_cfg[s:key_tag_path] = tagPath

  let externalFolders = []
  if has_key(g:project_cfg, s:key_external_folders)
    if (stridx(g:project_cfg[s:key_external_folders], ',') == -1)
      call add(externalFolders, g:project_cfg[s:key_external_folders])
    else
      let externalFolders = split(g:project_cfg[s:key_external_folders], ",")
    endif

    let i = 0
    while i < len(externalFolders)
      let externalFolder = s:stripspaces(externalFolders[i])
      if (isdirectory(externalFolder))
        call add(g:external_folders, externalFolder)
      endif
      let i = i + 1
    endwhile
  endif

  let sessionPath = g:project_cfg[s:key_project_root].'/'
                  \ .g:project_cfg[s:key_project_cfg_folder]
  let sessionName = g:project_cfg[s:key_session_name]
  if has_key(g:project_cfg, s:key_session_path) &&
  \  g:project_cfg[s:key_session_path] != "." &&
  \  isdirectory(g:project_cfg[s:key_session_path])
     let sessionPath = g:project_cfg[s:key_session_path]
  endif
  let g:project_cfg[s:key_session_path] =  sessionPath

  return s:error_list["OK"]
endfunction


"Generate tags file
function! s:makeTags(path, project)
  if !isdirectory(project)
    return s:error_list["NOT_PROJECT"]
  endif

  let ctagCommand = "ctags -f "
  let ctagCommand .= a:path
  let ctagCommand .= " --file-scope=yes
\                    --fields=+iaS --extra=+q
\                    --langmap=C++:.C.h.c.cpp.hpp.cc 
\                    --languages=c,c++ --links=yes
\                    --c-kinds=+p --c++-kinds=+p -R " 
  let ctagCommand .= a:project
  let ctagCommand .= '/'
  let ctagCommand .= " > /dev/null 2>&1 &"
  exe ':silent !' . ctagCommand

  return s:error_list["OK"]
endfunction

"Set tags file
function! s:setTags()
  if !has_key(g:project_cfg, s:key_project_root)
    return s:error_list["NOT_PROJECT"]
  endif
  
  let tagPath = g:project_cfg[s:key_tag_path]
  let tagName = g:project_cfg[s:key_tag_name]

  if !filereadable(tagPath.'/'.tagName)
     call s:makeTags(tagPath.'/'.tagName, g:project_cfg[s:key_project_root])
  endif

  let setTagsCmd = 'set tags='.g:project_cfg[s:key_tag_path].'/'.tagName

  for externalFolder in g:external_folders
    if isdirectory(externalFolder)
      if !filereadable(externalFolder.'/'.g:project_cfg[s:key_external_tag_name])
        call s:makeTags(externalFolder.'/'.g:project_cfg[s:key_external_tag_name], externalFolder)
      endif
      let setTagsCmd .= ','
      let setTagsCmd .= externalFolder.'/'.g:project_cfg[s:key_external_tag_name]
    endif
  endfor

  exe setTagsCmd

  return s:error_list["OK"]
endfunction

"Generate tags for external folder
function! s:makeExternalProjectTags(...)
  if len(a:000)
    let i = 0
    while i < len(a:000)
      if match(a:000[i], '\d\+') == -1 || 
      \  str2nr(a:000[i]) < 0 ||
      \  str2nr(a:000[i]) >= len(g:external_folders)
        let i = i + 1 
        continue
      endif
      let extDir = g:external_folders[str2nr(a:000[i])]
      if isdirectory(extDir)
        call s:makeTags(extDir.'/'.g:project_cfg[s:key_external_tag_name], extDir) 
      endif
      let i = i + 1 
    endwhile
  else
    for externalFolder in g:external_folders
      call s:makeTags(externalFolder.'/'.g:project_cfg[s:key_external_tag_name], externalFolder) 
    endfor
  endif
endfunction

"List external folders
function! s:listExternalFolders()
  let i = 0
  while i < len(g:external_folders)
    echo i." : ".g:external_folders[i]
    let i = i + 1
  endwhile
endfunction

"Save session
function! s:saveSession()
  if !has_key(g:project_cfg, s:key_project_root)
    return s:error_list["NOT_PROJECT"]
  endif

  echo "Do you want to save the session?y/n"
  let c = nr2char(getchar())
  if c == "y"
     execute ":mks! ".g:project_cfg[s:key_session_path].'/'
            \ .g:project_cfg[s:key_session_name]
  endif
  echo ""

  return s:error_list["OK"]
endfunction

"Restore session
function! s:restoreSession()
  if !has_key(g:project_cfg, s:key_project_root)
    return s:error_list["NOT_PROJECT"]
  endif

  echo "Do you want to restore the session last saved?y/n"
  let c = nr2char(getchar())
  if c == "y"
    if filereadable(g:project_cfg[s:key_session_path].'/'
            \      .g:project_cfg[s:key_session_name])
       execute ":so " . g:project_cfg[s:key_session_path].'/'
            \         . g:project_cfg[s:key_session_name]
       execute ":VbookmarkPlaceAll"
    endif
    echo ""
  endif

  return s:error_list["OK"]
endfunction

"Set bookmarks path
function! s:setBookmarksPath()
  if !has_key(g:project_cfg, s:key_project_root)
    return s:error_list["NOT_PROJECT"]
  endif

  let bookmarksPath = g:project_cfg[s:key_project_root].'/' 
                    \ .g:project_cfg[s:key_project_cfg_folder]
  let bookmarksName = g:project_cfg[s:key_bookmarks_name]

  if isdirectory(g:project_cfg[s:key_bookmarks_path]) &&
   \ g:project_cfg[s:key_bookmarks_path] != "."
     let bookmarksPath = g:project_cfg[s:key_bookmarks_path] 
  endif

  " This value will work when there is vbookmark
  let g:vbookmark_bookmarkSaveFile = bookmarksPath.'/'.bookmarksName

  return g:vbookmark_bookmarkSaveFile
endfunction

"Generate set includes command for current project 
function! s:generateIncludesCmd(initialCmd, keyProjectDir, keyIncludes)
  let setIncludesCmd = a:initialCmd
  if has_key(g:project_cfg, a:keyIncludes)
    let includes = split(g:project_cfg[a:keyIncludes], ',')
    let i = 0
    while i < len(includes)
      let include = s:stripspaces(includes[i])
      if stridx(include, g:project_cfg[a:keyProjectDir]) == -1
        if include != "."
          let include = g:project_cfg[a:keyProjectDir].'/'.include
        else
          let include = g:project_cfg[a:keyProjectDir]
        endif
      endif

      if isdirectory(include) && i != len(includes) - 1
        let setIncludesCmd .= include
        let setIncludesCmd .= ','
      elseif isdirectory(include) && i== len(includes) - 1
        let setIncludesCmd .= include
      endif
      let i = i + 1
     endwhile
  endif

  return setIncludesCmd
endfunction

"Set includes path
function! s:setIncludes()
  let s:setIncludesCmdStart = 'set path=.,'

  if !has_key(g:project_cfg, s:key_project_root)
    return
  endif

  let setIncludesCmd = s:generateIncludesCmd(s:setIncludesCmdStart, s:key_project_root, s:key_project_includes)

  if has_key(g:project_cfg, s:key_external_includes)
    if g:project_cfg[s:key_external_includes] != ""
      if strlen(setIncludesCmd) > strlen(s:setIncludesCmdStart)
        let setIncludesCmd .= ','
      endif
      let externalIncludes = split(g:project_cfg[s:key_external_includes], ',') 
      let i = 0
      while i < len(externalIncludes) 
        if i != len(externalIncludes) - 1
          if isdirectory(externalIncludes[i])
            let setIncludesCmd .= externalIncludes[i]
            let setIncludesCmd .= ','
          endif
        else
          if isdirectory(externalIncludes[i])
            let setIncludesCmd .= externalIncludes[i]
          endif
        endif
        let i = i + 1
      endwhile
    endif
  endif

  if strlen(setIncludesCmd) > strlen(s:setIncludesCmdStart)
    execute setIncludesCmd
  endif
endfunction

"Change work folder
function Chw(...)
  if !has_key(g:project_cfg, s:key_project_root)
    return s:error_list["NOT_PROJECT"]
  endif

  if a:0
    if a:1 == "rt"
      execute ":cd ".g:project_cfg[s:key_project_root]
    elseif a:1 == "cr"
      let curPath = expand("%:p:h")
      execute ":cd ".curPath
    else
      execute ":cd ".a:1
    endif
  else
    execute ":cd ".g:project_cfg[s:key_project_root]
  endif

  return s:error_list["OK"]
endfunction

"Call
let retStatus = s:loadProjectCfg()
if retStatus  == s:error_list["OK"]
  call s:setTags()
  call s:setBookmarksPath()
  call s:setIncludes()
else 
  " This value will work when there is vbookmark
  "let g:vbookmark_bookmarkSaveFile = "/home/broton/.vim/.bookmarks"
  let g:vbookmark_bookmarkSaveFile = $HOME . "/.bookmarks"
endif

"
"Command Define
"
if !exists(':Cw') && has_key(g:project_cfg, s:key_project_root)
  command! -nargs=? Cw call Chw(<f-args>)
endif

if !exists(':SaveSessionYorN') && has_key(g:project_cfg, s:key_project_root)
  command -nargs=0 SaveSessionYorN : call s:saveSession()
  nnoremap <silent> <C-F5> :SaveSessionYorN<CR>
endif

if !exists(':RestoreSessionYorN') && has_key(g:project_cfg, s:key_project_root)
  command -nargs=0 RestoreSessionYorN : call s:restoreSession()
  nnoremap <silent> <C-F6> :RestoreSessionYorN<CR>
endif

if !exists(':MakePTags') && has_key(g:project_cfg, s:key_project_root)
  command -nargs=0 MakePTags :silent call s:makeTags(
  \ g:project_cfg[s:key_tag_path].'/'.g:project_cfg[s:key_tag_name],
  \ g:project_cfg[s:key_project_root])
endif

if !exists(':MakeETags') && has_key(g:project_cfg, s:key_external_folders)
  command -nargs=* MakeETags :silent call s:makeExternalProjectTags(<f-args>)
endif

if !exists(':ListEFolders') && has_key(g:project_cfg, s:key_external_folders)
  command -nargs=0 ListEFolders : call s:listExternalFolders()
  nnoremap <silent> lf :ListEFolders<CR>
endif

