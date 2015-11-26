"Load Project Config
"2014-03-12, Broton Bi
"
"  -This is for loading project's  config file.

if exists("loaded_LoadTags")
  finish
endif
let loaded_LoadTags = 1

let s:error_list = {"OK":0,"INVALID_PATH":-1,"NOT_PROJECT":-2, "INVALID_FOLDER_TYPE":-3, "INVALID_PARAMETER":-4}
let s:project_cfg_name = ".projectcfg"
let s:key_project_root = "projectRoot"
let s:key_tag_path = "tagPath"
let s:key_tag_prefix_name = "tagPrefixName"
let s:key_bookmarks_path = "bookmarksPath"
let s:key_bookmarks_name = "bookmarksName"
let s:key_NERDTreeBookmarks_path = "NERDTreeBookmarksPath"
let s:key_NERDTreeBookmarks_name = "NERDTreeBookmarksName"
let s:key_session_path = "sessionPath"
let s:key_session_name = "sessionName"
let s:key_project_cfg_folder = "projectCfgFolder"
let s:key_project_includes = "projectIncludes"
let s:key_external_folders = "externalFolders"
let s:key_external_includes = "externalIncludes"
let s:key_external_tag_prefix_name = "externalTagPrefixName"
let s:key_tag_import_mode = "tagImportMode"
let s:key_tag_folders= "tagIncludeFolders"
let s:key_tag_exclude_folders = "tagExcludeFolders"
let s:cplusplus = "cplusplus"
let s:java = "java"
let s:js = "js"
let s:delimiter = "_"
let s:folder_type_cplusplus = 0x01
let s:folder_type_java = 0x02
let s:folder_type_js = 0x04
"let g:project_cfg[s:key_external_tag_prefix_name] = ".tags"
let g:project_cfg = {}
let g:external_folders = []
let g:tag_folders = []
let g:tag_folder_tagfile_map = {}
let g:external_tagfolder_tagfile_map = {}

let g:project_cfg[s:key_tag_path] = "."
let g:project_cfg[s:key_tag_prefix_name] = "tags"
let g:project_cfg[s:key_bookmarks_path] = "."
let g:project_cfg[s:key_bookmarks_name] = "bookmarks"
let g:project_cfg[s:key_NERDTreeBookmarks_path] = "."
let g:project_cfg[s:key_NERDTreeBookmarks_name] = "NERDTreeBookmarks"
let g:project_cfg[s:key_session_path] = "."
let g:project_cfg[s:key_session_name] = "mysession"
let g:project_cfg[s:key_project_cfg_folder] = ".vimproject"
let g:project_cfg[s:key_external_tag_prefix_name] = "tags"
let g:project_cfg[s:key_tag_import_mode] = "include"
let g:project_cfg[s:key_tag_folders] = "."
let g:tail_name_number = 0
let g:TRUE = 1
let g:FALSE = 0

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
      let configItems = readfile(pathStep.'/'.projectCfgName, '', 400)
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
    " Line is a comment or empty
    if match(configItem, '^#\+\(.*\)') != -1 ||
    \  match (configItem, '\s+') !=-1
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
  let tagName = g:project_cfg[s:key_tag_prefix_name]
  if has_key(g:project_cfg, s:key_tag_path) &&
  \ isdirectory(g:project_cfg[s:key_tag_path])
     if g:project_cfg[s:key_tag_path] == "."
       let g:project_cfg[s:key_tag_path] = tagPath
     endif
  endif

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
function! s:makeTag(path, project, projectTypes, isForced)
  if !isdirectory(a:project)
    return []
  endif

  let retFolderTagNames = []
  let ctagCommandPrix = "ctags -f "
  let ctagCommandCplus = ''
  let ctagCommandJava = ''
  let ctagCommandJs = ''
  let commandCplus = " --file-scope=yes
  \                    --fields=+iaS --extra=+q
  \                    --langmap=C++:.C.h.c.cpp.hpp.cc
  \                    --languages=c,c++ --links=yes
  \                    --c-kinds=+p --c++-kinds=+p -R "

  let commandJava = " --langmap=java:.java --languages=java -R "

  let ctagCommandCplus  = ctagCommandPrix . a:path . s:delimiter. s:cplusplus
  let ctagCommandCplus .= commandCplus
  let ctagCommandCplus .= a:project
  let ctagCommandCplus .= '/'
  let ctagCommandCplus .= " > /dev/null 2>&1 &"

  let ctagCommandJava = ctagCommandPrix . a:path . s:delimiter. s:java
  let ctagCommandJava .= commandJava
  let ctagCommandJava .= a:project
  let ctagCommandJava .= '/'
  let ctagCommandJava .= " > /dev/null 2>&1 &"

  let ctagCommandJs  = "$HOME/.vim/bundle/loadproject/plugin/make_js_tags.sh  "
  let ctagCommandJs .= a:project

  let lstCtagsCommands = []
  let cplusplusTagName = a:path.s:delimiter.s:cplusplus
  let javaTagName = a:path.s:delimiter.s:java
  let jsTagName = a:path.s:delimiter.s:js
  let ctagCommandJs .= ' ' . jsTagName
  if a:projectTypes == s:folder_type_cplusplus
    if a:isForced || !filereadable(cplusplusTagName)
      let tmpcmd = 'rm -f ' . cplusplusTagName
      call system(tmpcmd)
      call add(lstCtagsCommands, ctagCommandCplus)
    endif

    call add(retFolderTagNames, cplusplusTagName)
  elseif a:projectTypes == s:folder_type_java
    if a:isForced || !filereadable(javaTagName)
      let tmpcmd = 'rm -f ' . javaTagName
      call add(lstCtagsCommands, ctagCommandJava)
    endif

    call add(retFolderTagNames, a:path.s:delimiter.s:java)
  elseif a:projectTypes == s:folder_type_js
    if a:isForced || !filereadable(jsTagName)
      let tmpcmd = 'rm -f ' . jsTagName
      call system(tmpcmd)
      call add(lstCtagsCommands, ctagCommandJs)
    endif

    call add(retFolderTagNames, jsTagName)
  elseif a:projectTypes == s:folder_type_cplusplus + s:folder_type_java
    if a:isForced || !filereadable(cplusplusTagName)
      let tmpcmd = 'rm -f ' . cplusplusTagName
      call system(tmpcmd)
      call add(lstCtagsCommands, ctagCommandCplus)
    endif

    if a:isForced || !filereadable(javaTagName)
      let tmpcmd = 'rm -f ' . javaTagName
      call system(tmpcmd)
      call add(lstCtagsCommands, ctagCommandJava)
    endif

    call add(retFolderTagNames, cplusplusTagName)
    call add(retFolderTagNames, javaTagName)
  elseif a:projectTypes == s:folder_type_cplusplus + s:folder_type_js
    if a:isForced || !filereadable(cplusplusTagName)
      let tmpcmd = 'rm -f ' . cplusplusTagName
      call system(tmpcmd)
      call add(lstCtagsCommands, ctagCommandCplus)
    endif

    if a:isForced || !filereadable(jsTagName)
      let tmpcmd = 'rm -f ' . jsTagName
      call system(tmpcmd)
      call add(lstCtagsCommands, ctagCommandJs)
    endif

    call add(retFolderTagNames, cplusplusTagName)
    call add(retFolderTagNames, jsTagName)
  elseif a:projectTypes == s:folder_type_java + s:folder_type_js
    if a:isForced || !filereadable(javaTagName)
      let tmpcmd = 'rm -f ' . javaTagName
      call system(tmpcmd)
      call add(lstCtagsCommands, ctagCommandJava)
    endif

    if a:isForced || !filereadable(jsTagName)
      let tmpcmd = 'rm -f ' . jsTagName
      call system(tmpcmd)
      call add(lstCtagsCommands, ctagCommandJs)
    endif

    call add(retFolderTagNames, javaTagName)
    call add(retFolderTagNames, jsTagName)
  elseif a:projectTypes == s:folder_type_cplusplus + s:folder_type_java + s:folder_type_js
    if a:isForced || !filereadable(cplusplusTagName)
      let tmpcmd = 'rm -f ' .  cplusplusTagName
      call system(tmpcmd)
      call add(lstCtagsCommands, ctagCommandCplus)
    endif

    if a:isForced || !filereadable(javaTagName)
      let tmpcmd = 'rm -f ' .  javaTagName
      call system(tmpcmd)
      call add(lstCtagsCommands, ctagCommandJava)
    endif

    if a:isForced || !filereadable(jsTagName)
      let tmpcmd = 'rm -f ' . jsTagName
      call system(tmpcmd)
      call add(lstCtagsCommands, ctagCommandJs)
    endif

    call add(retFolderTagNames, cplusplusTagName)
    call add(retFolderTagNames, javaTagName)
    call add(retFolderTagNames, jsTagName)
  else
    echoerr "Invalid path, impossible..."
    return []
  endif

  for command in lstCtagsCommands
    exe ':silent !' . command
  endfor

  return retFolderTagNames
endfunction

"Calculate project types
function! s:calculateProjectTypes(folderTypes)
  let maskFolderTypes = 0x00
  let retVal = []

  let lstFolderTypes = split(a:folderTypes, "|")
  for folderType in lstFolderTypes
    if folderType == s:cplusplus
      let maskFolderTypes += s:folder_type_cplusplus
    elseif folderType == s:java
      let maskFolderTypes += s:folder_type_java
    elseif folderType == s:js
      let maskFolderTypes += s:folder_type_js
    else
      let maskFolderTypes += 0x00
    endif
  endfor

  if maskFolderTypes == 0x00
    let maskFolderTypes = s:folder_type_cplusplus
    call add(retVal, maskFolderTypes)
    call add(retVal, s:error_list["INVALID_FOLDER_TYPE"])
  else
    call add(retVal, maskFolderTypes)
    call add(retVal, s:error_list["OK"])
  endif

  return retVal
endfunction

"Todo end with /
function! s:generateTagPrefixNameWithFolder(folderName)
    let folderNodes = split(a:folderName, "/")
    let retTagNamePrix = ''
    let i = 0
    for folderNode in folderNodes
      let folderNode = s:stripspaces(folderNode)
      if (!empty(folderNode))
        if i != len(folderNodes)-1
          let retTagNamePrix .= (folderNode . '_')
        else
          let retTagNamePrix .= folderNode 
        endif
      endif
      let i += 1
    endfor

    return retTagNamePrix
endfunction

function! s:listHasValue(list, toFind)
  for value in a:list
    if (value == a:toFind)
      return g:TRUE
    endif
  endfor

  return g:FALSE
endfunction

"Make tags of a folder with types
function! s:makeFolderTagWithTypes(isForced, folderWithTypes)
  let status = s:error_list['OK']
  let folderAndStrTypes = split(a:folderWithTypes, ":")

  if empty(folderAndStrTypes)
    return s:error_list['INVALID_PARAMETER']
  endif

  let tagFolder = folderAndStrTypes[0]
  let folderStrTypes = s:cplusplus

  if len(folderAndStrTypes) > 1
    let folderStrTypes = folderAndStrTypes[1]
  endif

  let folderMaskTypesAndRetValue = s:calculateProjectTypes(folderStrTypes)
  let folderMaskTypes = folderMaskTypesAndRetValue[0]
  let status = folderMaskTypesAndRetValue[1]

  if tagFolder == "."
    let tagPath = g:project_cfg[s:key_tag_path]
    let tagName = g:project_cfg[s:key_tag_prefix_name]
    let tagPathNameAll = tagPath.'/'.tagName.s:delimiter."all"

    let retFolderTagNames = s:makeTag(tagPathNameAll, g:project_cfg[s:key_project_root], folderMaskTypes, a:isForced)
    if len(folderAndStrTypes) > 1
      if a:isForced == 0
        let tmpIndex = 'root:cplusplus'

        if status != s:error_list["INVALID_FOLDER_TYPE"]
          let tmpIndex = 'root:'.folderAndStrTypes[1]
        endif

        if !s:listHasValue(g:tag_folders,tmpIndex)
          let g:tag_folder_tagfile_map[tmpIndex] = retFolderTagNames
          call add(g:tag_folders, tmpIndex)
        endif

      endif
    else
      if a:isForced == 0
        if !s:listHasValue(g:tag_folders, "root")
          let g:tag_folder_tagfile_map['root'] = retFolderTagNames
          call add(g:tag_folders, "root")
        endif
      endif
    endif
  else
    let fullTagFolderPath = g:project_cfg[s:key_project_root].'/'.tagFolder
    let retFolderTagNames = []
    if isdirectory(fullTagFolderPath)
      let tagPath = g:project_cfg[s:key_tag_path]
      let tagName = g:project_cfg[s:key_tag_prefix_name]
      let tagAppendixName = s:generateTagPrefixNameWithFolder(tagFolder)
      let tagPathAndName = tagPath.'/'. tagName . s:delimiter . tagAppendixName
      let retFolderTagNames = s:makeTag(tagPathAndName, fullTagFolderPath, folderMaskTypes, a:isForced)
      if a:isForced == 0
        if status != s:error_list["INVALID_FOLDER_TYPE"]
          if !s:listHasValue(g:tag_folders, a:folderWithTypes)
            call add(g:tag_folders, a:folderWithTypes)
            let g:tag_folder_tagfile_map[tagFolder] = retFolderTagNames
          endif
        else
          if !s:listHasValue(a:folderWithTypes)
            call add(g:tag_folders, tagFolder.":cplusplus")
            let g:tag_folder_tagfile_map[tagFolder] = retFolderTagNames
          endif
        endif
      endif
    endif
  endif

  return status
endfunction

"Make tags of folders
function! s:makeAllProjectTags(isForced)
  if !isdirectory(g:project_cfg[s:key_project_root])
      return
  endif

  let tagImportMode =  g:project_cfg[s:key_tag_import_mode]
  if tagImportMode != "include" &&
  \  tagImportMode != "exclude"
     let g:project_cfg[s:key_tag_import_mode] = "include"
     let g:project_cfg[s:key_tag_folders] = "."
  endif

  if tagImportMode == "include"
    let tagFolders = []
    let hasRoot = 0
    if has_key(g:project_cfg, s:key_tag_folders)
      let tagFolders = split(g:project_cfg[s:key_tag_folders], ",")

      let i = 0
      while i < len(tagFolders)
        let tagFolder = s:stripspaces(tagFolders[i])
        if tagFolder =~ "^\.:.*" || tagFolder == "."
           let hasRoot = 1
           break
        endif
        let i = i + 1
      endwhile

      if hasRoot
        call s:makeFolderTagWithTypes(a:isForced, tagFolders[i])
        return
      else
         call add(g:tag_folders, "allfolders")
      endif

      let i = 0
      while i < len(tagFolders)
        call s:makeFolderTagWithTypes(a:isForced, tagFolders[i])
        let i = i + 1
      endwhile
    endif
  endif

  if tagImportMode == "exclude"
    if has_key(g:project_cfg, s:key_tag_exclude_folders)
      if (g:project_cfg[s:key_tag_exclude_folders] == ".")
        return
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
          call s:makeFolderTagWithTypes(a:isForced, underProjectDir.":".s:cplusplus)
        endif
      endfor
    endif
  endif
endfunction

"Generate all external folders tags
function! s:makeAllExternalTags(isForced)
  for externalFolder in g:external_folders
    let index = 0
    if isdirectory(externalFolder)
      let folderAndStrTypes = split(externalFolder)
      let strTypes = s:cplusplus
      if len(folderAndStrTypes) > 1
        let strTypes = folderAndStrTypes[1]
      endif

      let maskFolderTypesAndRetValue = s:calculateProjectTypes(strTypes)
      let maskFolderTypes = maskFolderTypesAndRetValue[0]
      let tagAppendixName = s:generateTagPrefixNameWithFolder(externalFolder)
      let externalTagPathName = g:project_cfg[s:key_tag_path].'/'
                             \ .g:project_cfg[s:key_external_tag_prefix_name]
                             \ .'_external'.index.s:delimiter.tagAppendixName
        let retExternalTagNames = s:makeTag(externalTagPathName, externalFolder, maskFolderTypes, a:isForced)
        let g:external_tagfolder_tagfile_map[externalFolder] = retExternalTagNames
      let index = index + 1
    endif
  endfor
endfunction

"Set tags file
function! s:setTags()
  if !has_key(g:project_cfg, s:key_project_root)
    return s:error_list["NOT_PROJECT"]
  endif

  let projectsTagFiles = values(g:tag_folder_tagfile_map)
  let setTagsCmd = 'set tags='
  for tagFiles in projectsTagFiles
    let i = 0
    let j = 0
    let theLastGroup = g:FALSE
    for tagFile in tagFiles
      if filereadable(tagFile)
        let setTagsCmd .= tagFile
        if !theLastGroup || i != (len(tagFiles) - 1)
          let setTagsCmd .= ','
        endif
      endif
      let i += 1
    endfor
    let j += 1
    if (j == len(projectsTagFiles) - 1)
      let theLastGroup = g:TRUE
    endif
  endfor

  let externalTagFiles = values(g:external_tagfolder_tagfile_map)
  for tagFiles in externalTagFiles
    let i = 0
    let j = 0
    let theLastGroup = g:FALSE
    for tagFile in tagFiles
      if filereadable(tagFile)
        let setTagsCmd .= tagFile
        if !theLastGroup || i != (len(tagFiles) - 1)
          let setTagsCmd .= ','
        endif
      endif
      let i += 1
    endfor
    let j += 1
    if (j == len(externalTagFiles) - 1)
      let theLastGroup = g:TRUE
    endif
  endfor

  exec setTagsCmd

  return s:error_list["OK"]
endfunction

"Generate tags for some folders
function! s:makeProjectTags(...)
  let isAllFolder = g:FALSE
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
      if tagDir == "allfolders"
        let isAllFolder = g:TRUE
        break
      else
        if tagDir =~ "root.*"
          let tagDir = '.'
        endif
        call s:makeFolderTagWithTypes(g:TRUE, tagDir)
      endif

      let i = i + 1
    endwhile
  else
      let isAllFolder = g:TRUE
  endif

  if isAllFolder
    for eachFolder in g:tag_folders
      if eachFolder == "allfolders"
        continue
      endif

      if eachFolder =~"root.*"
        let eachFolder = '.'
      endif

      call s:makeFolderTagWithTypes(g:TRUE, eachFolder)
    endfor
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
      \                         g:project_cfg[s:key_external_tag_prefix_name].
      \                         'external'.i
      let extDir = g:external_folders[str2nr(a:000[i])]
      if isdirectory(extDir)
        call s:makeTag(externalTagPathName, extDir, 0x01, str2nr(a:000[i]))
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

function! s:setNERDTreeBookmarksPath()
  if !has_key(g:project_cfg, s:key_project_root)
    return s:error_list["NOT_PROJECT"]
  endif

  let bookmarksPath = g:project_cfg[s:key_project_root].'/'
                    \ .g:project_cfg[s:key_project_cfg_folder]
  if isdirectory(g:project_cfg[s:key_NERDTreeBookmarks_path]) &&
   \ g:project_cfg[s:key_bookmarks_path] != "."
     let bookmarksPath = g:project_cfg[s:key_NERDTreeBookmarks_path]
  endif
  let bookmarksName = g:project_cfg[s:key_NERDTreeBookmarks_name]
  let g:NERDTreeBookmarksFile =  bookmarksPath . '/' . bookmarksName
  return g:NERDTreeBookmarksFile
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

function! s:addPTagFolders(...)
  if len(a:000)
    let i = 0
    while i < len(a:000)
      call s:makeFolderTagWithTypes(g:FALSE, a:000[i])
      let i += 1
    endwhile
    call s:setTags()
  endif
endfunction

" Delete tag from list.
function! s:delPTagFolders(...)
  if len(a:000)
    let i = 0
    let index = str2nr(a:000[i])
    while i < len(a:000)
      if match(a:000[i], '\d\+') == -1 ||
      \  index < 0 ||
      \  index >= len(g:external_folders)
        let i = i + 1
        continue
      endif

      let folderAndTypes = split(g:tag_folders[index], ":")
      if folderAndTypes[0] != "allfolders"
        call remove(g:tag_folders, index)
        call remove(g:tag_folder_tagfile_map, folderAndTypes[0])
        call s:setTags()
      endif

      let i += 1
    endwhile
  endif
endfunction

"Call
let retStatus = s:loadProjectCfg()
if retStatus  == s:error_list["OK"]
  call s:makeAllProjectTags(0)
  call s:makeAllExternalTags(0)
  call s:setTags()
  call s:setBookmarksPath()
  call s:setNERDTreeBookmarksPath()
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

if !exists(':AddPTagFolders') && has_key(g:project_cfg, s:key_project_root)
  command -nargs=* AddPTagFolders :silent call s:addPTagFolders(<f-args>)
endif

if !exists(':DelPTagFolders') && has_key(g:project_cfg, s:key_project_root)
  command -nargs=* DelPTagFolders :silent call s:delPTagFolders(<f-args>)
endif
