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
let s:key_tag_import_mode = "tagImportMode"
let s:key_tag_folders= "tagIncludeFolders"
let s:key_tag_exclude_folders = "tagExcludeFolders"
"let g:project_cfg[s:key_external_tag_name] = ".tags"
let g:project_cfg = {}
let g:external_folders = []
let g:tag_folders = []

let g:project_cfg[s:key_tag_path] = "."
let g:project_cfg[s:key_tag_name] = "tags"
let g:project_cfg[s:key_bookmarks_path] = "."
let g:project_cfg[s:key_bookmarks_name] = "bookmarks"
let g:project_cfg[s:key_session_path] = "."
let g:project_cfg[s:key_session_name] = "mysession"
let g:project_cfg[s:key_project_cfg_folder] = ".vimproject"
let g:project_cfg[s:key_external_tag_name] = ".tags"
let g:project_cfg[s:key_tag_import_mode] = "root"
let g:tail_name_number = 0

call add(g:tag_folders, "allfolders")
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
      if len(pathStep) <= len($HOME)
        continue
      endif
      let foundProjecConfig = 1
      let g:project_cfg[s:key_project_root] = pathStep
      let configItems = readfile(pathStep.'/'.projectCfgName, '', 80)
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
  \ isdirectory(g:project_cfg[s:key_tag_path])
     if g:project_cfg[s:key_tag_path] != "."
       let tagPath = g:project_cfg[s:key_tag_path]
       let g:project_cfg[s:key_tag_path] = tagPath
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
function! s:makeTag(path, project)
  if !isdirectory(a:project)
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

"Make tags of folders
function! s:makeAllProjectTags(isForced)
  let retTagFiles = []
  if !isdirectory(g:project_cfg[s:key_project_root])
      return retTagFiles
  endif
 
  let tagImportMode =  g:project_cfg[s:key_tag_import_mode]
  if tagImportMode != "root" && 
  \  tagImportMode != "include" && 
  \  tagImportMode != "exclude"
     let tagImportMode = "root"
     let g:project_cfg[s:key_tag_import_mode] = tagImportMode
  endif

  let tagPath = g:project_cfg[s:key_tag_path]
  let tagName = g:project_cfg[s:key_tag_name]
  let tagPathNameAll = tagPath.'/'.tagName."_all"

  if tagImportMode == "root" 
      if (!filereadable(tagPathNameAll) || a:isForced)
        call s:makeTag(tagPathNameAll, g:project_cfg[s:key_project_root])
      endif
      call add(retTagFiles, tagPathNameAll)
      call add(g:tag_folders, "root")
      return retTagFiles 
  endif

  if tagImportMode == "include"
    let tagFolders = []
    if has_key(g:project_cfg, s:key_tag_folders)
      if (stridx(g:project_cfg[s:key_tag_folders], ',') == -1)
        if g:project_cfg[s:key_tag_folders] == "."
          call add(tagFolders, "root")
        else
          let tempFolder =  g:project_cfg[s:key_project_root].'/'.g:project_cfg[s:key_tag_folders]
          if isdirectory(tempFolder)
            call add(tagFolders, g:project_cfg[s:key_tag_folders])
          endif
        endif
      else
        let tagFolders = split(g:project_cfg[s:key_tag_folders], ",")
      endif

      let i = 0
      while i < len(tagFolders)
        let tagFolder = s:stripspaces(tagFolders[i])
        if tagFolder == "root"
          call remove(g:tag_folders, 0) 
          call remove(retTagFiles, 0)
          call add(g:tag_folders, "root")
          call add(retTagFiles, tagPathNameAll)
          return retTagFiles
        endif
        
        if isdirectory(g:project_cfg[s:key_project_root].'/'.tagFolder)
          let tagPath = g:project_cfg[s:key_tag_path]
          let tailName = tagFolder
          if (stridx(tailName, '/') != -1)
            let g:tail_name_number = g:tail_name_number + 1
            let tailName = g:tail_name_number
          endif
          
          let subTagPathName = tagPath.'/'.tagName.'_'.tailName
          if !filereadable(subTagPathName) || a:isForced
            call s:makeTag(subTagPathName, g:project_cfg[s:key_project_root].'/'.tagFolder)
          endif 
          call add(g:tag_folders, tagFolder)
          call add(retTagFiles, subTagPathName)
        endif
        let i = i + 1
      endwhile
    endif
    return retTagFiles
  endif

  if tagImportMode == "exclude"
    if has_key(g:project_cfg, s:key_tag_exclude_folders)
      if (g:project_cfg[s:key_tag_exclude_folders] == ".")
        return []
      endif

      let excludeFolders = []
      if (stridx(g:project_cfg[s:key_tag_exclude_folders], ',') == -1)
        call add(excludeFolders, g:project_cfg[s:key_tag_exclude_folders])
      else
        let excludeFolders = split(g:project_cfg[s:key_tag_exclude_folders], ",")
      endif

      let underProjectDirsOrig = system('ls -d */')
      let underProjectDirs = split(underProjectDirsOrig, "\n")
    
      for dir in underProjectDirs
        let underProjectDir = s:stripnewlines(dir)
        if len(underProjectDir) >= 2
          let underProjectDir = underProjectDir[0: len(underProjectDir)-2]
        endif
        if index(excludeFolders, underProjectDir) == -1
          let subTagPathName = g:project_cfg[s:key_tag_path].'/'.tagName.'_'.underProjectDir
          if !filereadable(subTagPathName) || a:isForced
            call s:makeTag(subTagPathName, g:project_cfg[s:key_project_root].'/'.underProjectDir)
          endif
          call add(retTagFiles, underProjectDir.'/'.tagName)
        endif
      endfor
    endif
    return retTagFiles
  endif

endfunction

"Generate all external folders tags
function! s:makeAllExternalTags(isForced)
  let retSetTagsCmd = ','
  for externalFolder in g:external_folders
    let index = 0
    if isdirectory(externalFolder)
      let exernalTagPathName = g:project_cfg[s:key_tag_path].'/'
                             \ .g:project_cfg[s:key_external_tag_name]
                             \ .'external'.index
      if !filereadable(externalTagPathName) || a:isForced
        call s:makeTag(externalTagPathName, externalFolder)
      endif
      let index = index + 1
      let retSetTagsCmd .= ','
      let retSetTagsCmd .= exernalTagPathName
    endif
  endfor

  return retSetTagsCmd
endfunction

"Set tags file
function! s:setTags()
  if !has_key(g:project_cfg, s:key_project_root)
    return s:error_list["NOT_PROJECT"]
  endif

  let tagFiles = s:makeAllProjectTags(0)
  let setTagsCmd = 'set tags='
  for tagFile in tagFiles
    let i = 0
    if filereadable(tagFile)
      let setTagsCmd .= tagFile
      if i != (len(tagFiles) - 1)
        let setTagsCmd .= ','
      endif
    endif
    let i = i + 1
  endfor

  let setTagsCmd .=  s:makeAllExternalTags(0)
  exe setTagsCmd

  return s:error_list["OK"]
endfunction

"Generate tags for some folders
function! s:makeProjectTags(...)
  if len(a:000)
    let i = 0
    while i < len(a:000)
      if match(a:000[i], '\d\+') == -1 ||
      \  str2nr(a:000[i]) < 0 ||
      \  str2nr(a:000[i]) >= len(g:tag_folders)
        let i = i + 1
        continue
      endif
      let tagDir = g:tag_folders[str2nr(a:000[i])]
      if tagDir == "root" || tagDir == "allfolders"
        call s:makeAllProjectTags(1)
        break
      elseif isdirectory(g:project_cfg[s:key_project_root].'/'.tagDir)
        let subTagPathName = g:project_cfg[s:key_tag_path].'/'.g:project_cfg[s:key_tag_name].'_'.tagDir
        call s:makeTag(subTagPathName, g:project_cfg[s:key_project_root].'/'.tagDir)
      endif

      let i = i + 1
    endwhile
  else
      call s:makeAllProjectTags(1)
  endif
endfunction

"List all project tag folders
function! s:listProjectTagFolders()
  let i = 0
  while i < len(g:tag_folders)
    echo i." : ".g:tag_folders[i]
    let i = i + 1
  endwhile
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
      let externalTagPathName = g:project_cfg[s:key_tag_path].
      \                         g:project_cfg[s:key_external_tag_name].
      \                         'external'.i
      let extDir = g:external_folders[str2nr(a:000[i])]
      if isdirectory(extDir)
        call s:makeTag(externalTagPathName, extDir) 
      endif
      let i = i + 1 
    endwhile
  else
    for externalFolder in g:external_folders
      call s:makeAllExternalTags(1) 
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
  command -nargs=* MakePTags :silent call s:makeProjectTags(<f-args>)
endif

if !exists(':MakeETags') && has_key(g:project_cfg, s:key_external_folders)
  command -nargs=* MakeETags :silent call s:makeExternalProjectTags(<f-args>)
endif

if !exists(':ListEFolders') && has_key(g:project_cfg, s:key_external_folders)
  command -nargs=0 ListEFolders : call s:listExternalFolders()
  nnoremap <silent> lse :ListEFolders<CR>
endif

if !exists(':ListPFolders') && has_key(g:project_cfg, s:key_project_root)
  command -nargs=0 ListPFolders : call s:listProjectTagFolders()
  nnoremap <silent> lst :ListPFolders<CR>
endif

