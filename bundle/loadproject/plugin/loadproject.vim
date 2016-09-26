"Load Project Config
"2014-03-12, Broton Bi
"
"  -This is for loading project's  config file.

if exists("loaded_LoadTags")
  finish
endif
let loaded_LoadTags = 1

let s:error_list = {"OK":0,
                   \"INVALID_PATH":-1,"NOT_PROJECT":-2,
                   \"ALL_INVALID_FOLDER_TYPE":-3,
                   \"HAS_INVALID_FOLDER_TYPE":-4,
                   \"INVALID_PARAMETER":-5}
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
let g:tag_externalfolder_tagfile = {}

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
  ""    if len(pathStep) <= len($HOME)
  ""      continue
  ""    endif
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
  let finalStrTypes = ''
  let retStatus = s:error_list["OK"]

  let lstFolderTypes = split(a:folderTypes, "|")
  let i = 0
  let findValid = g:TRUE
  for folderType in lstFolderTypes
    if folderType == s:cplusplus
      let findValid = g:TRUE
      let maskFolderTypes += s:folder_type_cplusplus
      let finalStrTypes .= s:cplusplus
    elseif folderType == s:java
      let findValid = g:TRUE
      let maskFolderTypes += s:folder_type_java
      let finalStrTypes .= s:java
    elseif folderType == s:js
      let findValid = g:TRUE
      let maskFolderTypes += s:folder_type_js
      let finalStrTypes .= s:js
    else
      let findValid = g:FALSE
      let maskFolderTypes += 0x00
      let retStatus = s:error_list["HAS_INVALID_FOLDER_TYPE"]
    endif

    if i != len(lstFolderTypes)-1 && findValid
      let finalStrTypes .= '|'
    endif
    let i += 1
  endfor

  if maskFolderTypes == 0x00
    let maskFolderTypes = s:folder_type_cplusplus
    let finalStrTypes = s:cplusplus
    let retStatus = s:error_list["ALL_INVALID_FOLDER_TYPE"]
  else
    if !findValid
      let finalStrTypes = strpart(finalStrTypes, 0, strlen(finalStrTypes)-1)
    endif
  endif

  call add(retVal, maskFolderTypes)
  call add(retVal, retStatus)
  call add(retVal, finalStrTypes)

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
  let folderWithTypes = a:folderWithTypes

  let status = s:error_list['OK']
  let folderAndStrTypes = split(folderWithTypes, ":")
  if empty(folderAndStrTypes)
    return s:error_list['INVALID_PARAMETER']
  endif

  let tagFolder = folderAndStrTypes[0]

  let folderStrTypes = s:cplusplus

  if len(folderAndStrTypes) > 1
    let folderStrTypes = folderAndStrTypes[1]
  endif

  let len = strlen(tagFolder)
  if strpart(tagFolder, len-1, 1) == '/'
    let tagFolder = strpart(tagFolder, 0, len-1)
  endif

  let i = 0
  for folder in g:tag_folders
    let tmpFolderAndTypes = split(folder, ':')
    if tagFolder == tmpFolderAndTypes[0]
      call remove(g:tag_folders, i)
      call remove(g:tag_folder_tagfile_map, tagFolder)
      break
    endif
    let i += 1
  endfor

  let folderMaskTypesAndRetValue = s:calculateProjectTypes(folderStrTypes)
  let folderMaskTypes = folderMaskTypesAndRetValue[0]
  let status = folderMaskTypesAndRetValue[1]
  let finalStrTypes = folderMaskTypesAndRetValue[2]

  if tagFolder == "."
    let tagPath = g:project_cfg[s:key_tag_path]
    let tagName = g:project_cfg[s:key_tag_prefix_name]
    let tagPathNameAll = tagPath.'/'.tagName.s:delimiter."all"

    let retFolderTagNames = s:makeTag(tagPathNameAll, g:project_cfg[s:key_project_root], folderMaskTypes, a:isForced)
    if len(folderAndStrTypes) > 1
      if a:isForced == 0
        if !s:listHasValue(g:tag_folders,'root')
          let g:tag_folder_tagfile_map['root'] = retFolderTagNames
          call add(g:tag_folders, 'root:'.finalStrTypes)
        endif
      endif
    else
      if a:isForced == 0
        if !s:listHasValue(g:tag_folders, "root")
          let g:tag_folder_tagfile_map['root'] = retFolderTagNames
          call add(g:tag_folders, "root:".finalStrTypes)
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
      if a:isForced == g:FALSE
         call add(g:tag_folders, tagFolder.':'.finalStrTypes)
         let g:tag_folder_tagfile_map[tagFolder] = retFolderTagNames
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
        if tagFolder =~ '^\.:\?.*'
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

"Make external folder tag with types
function! s:addExternalFolderWithTypes(externalFolderWithTypes, isForced)
  let folderAndStrTypes = split(a:externalFolderWithTypes, ':')
  let strTypes = s:cplusplus
  if len(folderAndStrTypes) > 1
    let strTypes = folderAndStrTypes[1]
  endif

  let tagFolder = folderAndStrTypes[0]
  let len = strlen(tagFolder)
  if strpart(tagFolder, len-1, 1) == '/'
    let tagFolder = strpart(tagFolder, 0, len-1)
  endif

  let i = 0
  for eachFolderWithTypes in g:external_folders
    let tmpFolderAndTypes = split(eachFolderWithTypes, ':')
    if tmpFolderAndTypes[0] == tagFolder
      call remove(g:external_folders, i)
      call remove(g:tag_externalfolder_tagfile, tagFolder)
    endif
    let i += 1
  endfor

  if isdirectory(tagFolder)
    let maskFolderTypesAndRetValue = s:calculateProjectTypes(strTypes)
    let maskFolderTypes = maskFolderTypesAndRetValue[0]
    let findStrTypes = maskFolderTypesAndRetValue[2]
    let tagPrefixName = s:generateTagPrefixNameWithFolder(tagFolder)
    let externalTagPathName = g:project_cfg[s:key_tag_path].'/'
                           \ .g:project_cfg[s:key_external_tag_prefix_name]
                           \ .'_external'.s:delimiter.tagPrefixName
      let retExternalTagNames = s:makeTag(externalTagPathName, tagFolder, maskFolderTypes, a:isForced)
      call add(g:external_folders, tagFolder .':'.findStrTypes)
      let g:tag_externalfolder_tagfile[tagFolder] = retExternalTagNames
  endif
endfunction

"Generate all external folders tags
function! s:makeAllExternalTags(isForced)
  let externalFolders = []
  if has_key(g:project_cfg, s:key_external_folders)
    let externalFolders = split(g:project_cfg[s:key_external_folders], ",")
  endif

  for externalFolderWithTypes in externalFolders
    call s:addExternalFolderWithTypes(externalFolderWithTypes, a:isForced)
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

  let externalTagFiles = values(g:tag_externalfolder_tagfile)
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
      let indexWithTypes = a:000[i]
      if match(indexWithTypes, '\d\+:\?.*') == -1
        let i +=  1
        continue
      endif

      let indexAndTypes = split(a:000[i], ':')
      let index = str2nr(indexAndTypes[0])
      if (index < 0 || index >= len(g:tag_folders))
        let i += 1
        continue
      endif

      let types = ''
      if len(indexAndTypes) > 1
        let types = indexAndTypes[1]
      endif

      let tagDir = g:tag_folders[index]
      if tagDir == "allfolders"
        let isAllFolder = g:TRUE
        break
      else
        if tagDir =~ 'root.*'
          let tagDir = '.'
          let tagDir .= ':'.types
        else
          let folderAndTypes = split(tagDir, ':')
          let tagDir = folderAndTypes[0]
          let tagDir .= ':'.types
        endif
        call s:makeFolderTagWithTypes(g:TRUE, tagDir)
        break
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

      if eachFolder =~ 'root.*'
        let eachFolder = substitute(eachFolder, 'root', '.', '')
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
      let indexWithTypes = a:000[i]
      if match(indexWithTypes, '\d\+:\?.*') == -1
        let i +=  1
        continue
      endif

      let indexAndTypes = split(a:000[i], ':')
      let index = str2nr(indexAndTypes[0])
      if (index < 0 || index >= len(g:external_folders))
        let i += 1
        continue
      endif

      let types = ''
      let tagDir = ''
      if len(indexAndTypes) > 1
        let types = indexAndTypes[1]
        let tagDir = g:external_folders[index]
        let tmpFolderAndTypes = split(tagDir, ':')
        let tagDir = tmpFolderAndTypes[0] . ':'.types
      else
        let tagDir = g:external_folders[index]
      endif

      call s:addExternalFolderWithTypes(tagDir, g:TRUE)
      let i = i + 1
    endwhile
  else
    call s:makeAllExternalTags(g:TRUE)
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

function! s:checkFolderTypes(folderWithTypes)
  let folderAndStrTypes = split(a:folderWithTypes, ':')
  let folderStrTypes = s:cplusplus

  if len(folderAndStrTypes) > 1
    let folderStrTypes = folderAndStrTypes[1]
  endif

  let strTypes = split(folderStrTypes, '|')

  for strType in strTypes
    if strType != s:cplusplus &&
    \  strType != s:java &&
    \  strType != s:js
      return g:FALSE
    endif
  endfor

  return g:TRUE
endfunction

function! s:addPTagFolders(...)
  if len(a:000)
    let i = 0
    while i < len(a:000)
      if !s:checkFolderTypes(a:000[i])
        echomsg "There are invalid folder types in your input, do you want to add it continue:y/n?."
        let c = nr2char(getchar())
        if c == 'y'
          call s:makeFolderTagWithTypes(g:FALSE, a:000[i])
        else
          echomsg ''
          return
        endif
      else
        call s:makeFolderTagWithTypes(g:FALSE, a:000[i])
      endif
      let i += 1
    endwhile
    call s:setTags()
  else
    echomsg "Please assign your folder..."
  endif
endfunction

function! s:addETagFolders(...)
  if len(a:000)
    let i = 0
    while i < len(a:000)
      if !s:checkFolderTypes(a:000[i])
        echomsg "There are invalid folder types in your input, do you want to add it continue:y/n?."
        let c = nr2char(getchar())
        if c == 'y'
          call s:addExternalFolderWithTypes(a:000[i], g:FALSE)
        else
          echomsg ''
          return
        endif
      else
        call s:addExternalFolderWithTypes(a:000[i], g:FALSE)
      endif
      let i += 1
    endwhile
    call s:setTags()
  else
    echomsg "Please assign your folder..."
  endif
endfunction

" Deleted project tag with key and type
function! s:delPTagWithKeyAndType(folderIndex, key, type)
  if !has_key(g:tag_folder_tagfile_map, a:key)
    return
  endif

  let outFolderTypes = ''
  let tagfiles = g:tag_folder_tagfile_map[a:key]
  let i = 0
  for tagfile in tagfiles
    let fileNodes = split(tagfile, s:delimiter)
    if len(fileNodes) > 1
      if a:type == fileNodes[-1]
        call remove(g:tag_folder_tagfile_map[a:key], i)
        if (empty(g:tag_folder_tagfile_map[a:key]))
          call remove(g:tag_folder_tagfile_map, a:key)
        endif
      endif
    endif
    let i+= 1
  endfor

  if !empty(g:tag_folder_tagfile_map[a:key])
    let tagFolder = g:tag_folders[a:folderIndex]
      let folderWithTypes = split(tagFolder, ':')
      if len(folderWithTypes) > 1
        let folderTypes = split(folderWithTypes[1], '|')

        let i = 0
        for folderType in folderTypes
          if folderType == a:type
            call remove(folderTypes, i)
            break
          endif
          let i+= 1
        endfor

        for folderType in folderTypes
          let outFolderTypes .=  folderType . '|'
        endfor
        let outFolderTypes = strpart(outFolderTypes, 0, len(outFolderTypes)-1)
      endif
  endif

  return outFolderTypes
endfunction

" Deleted external tag with key and type
function! s:delETagWithKeyAndType(key, type)
  if !has_key(g:tag_externalfolder_tagfile, a:key)
    return
  endif

  let tagfiles = g:tag_externalfolder_tagfile[a:key]
  let i = 0
  for tagfile in tagfiles
    let fileNodes = split(tagfile, s:delimiter)
    if len(fileNodes) > 1
      if a:type == fileNodes[-1]
        call remove(g:tag_externalfolder_tagfile[a:key], i)
        if (empty(g:tag_externalfolder_tagfile[a:key]))
          call remove(g:tag_externalfolder_tagfile, a:key)
        endif
      endif
    endif
    let i+= 1
  endfor
endfunction

" Delete external folder tags
function! s:delPTagFolders(...)
  if len(a:000)
    let i = 0
    let folderToRemove = []
    while i < len(a:000)
      if a:000[i] =~ '\d\+:\?.*'
        let indexAndTypes = split(a:000[i], ':')
        let index = str2nr(indexAndTypes[0])

        if index >= len(g:tag_folders)
          let i += 1
          continue
        endif

        let folderWithTypes = g:tag_folders[index]
        let folderAndTypes = split(folderWithTypes, ':')
        let folder = folderAndTypes[0]
        if folder == "allfolder"
          if len(g:tag_folders) > 1
            call remove(g:tag_folders, 1, len(g:tag_folders)-1)
          endif
          for key in keys(g:tag_folder_tagfile_map)
            call remove(g:tag_folder_tagfile_map, key)
          endfor
          call s:setTags()
          return
        endif

        if len(indexAndTypes) > 1
          let folderTypes = indexAndTypes[1]
          let lstTypes = split(folderTypes, '|')
          for type in lstTypes
            if type != s:cplusplus &&
            \ type != s:java &&
            \ type != s:js
              continue
            endif

            let outFolderTypes = ''
            if type == s:cplusplus
              let outFolderTypes =  s:delPTagWithKeyAndType(index, folder, s:plusplus)
            endif

            if type == s:java
              let outFolderTypes =  s:delPTagWithKeyAndType(index, folder, s:java)
            endif

            if type == s:js
              let outFolderTypes =  s:delPTagWithKeyAndType(index, folder, s:js)
            endif

            if strlen(outFolderTypes) > 0
              let g:tag_folders[index] = folder . ':' . outFolderTypes
            endif
          endfor
          if !has_key(g:tag_folder_tagfile_map, folder)
            call add(folderToRemove, folderWithTypes)
          endif
        else
          call add(folderToRemove, folderWithTypes)
          if has_key(g:tag_folder_tagfile_map, folder)
            call remove(g:tag_folder_tagfile_map, folder)
          endif
        endif
      endif
      let i+= 1
    endwhile

    for tmpfolderWithTypes in folderToRemove
      let j = 0
      for origin in g:tag_folders
        if tmpfolderWithTypes == g:tag_folders[j]
          call remove(g:tag_folders, j)
          break
        endif
        let j += 1
      endfor
    endfor
  else
    if len(g:tag_folders) > 1
      call remove(g:tag_folders, 1, len(g:tag_folders)-1)
    endif
    for key in keys(g:tag_folder_tagfile_map)
      call remove(g:tag_folder_tagfile_map, key)
    endfor
  endif

  call s:setTags()
endfunction

" Delete external folder tags
function! s:delETagFolders(...)
  if len(a:000)
    let indexToRemove = []
    let i = 0
    while i < len(a:000)
      if a:000[i] =~ '\d\+:\?.*'
        let indexAndTypes = split(a:000[i], ':')
        let index = str2nr(indexAndTypes[0])

        if index >= len(g:external_folders)
          let i += 1
          continue
        endif

        let externalFolderWithType = g:external_folders[index]
        let externalFolderAndTypes = split(g:external_folders[index], ':')
        let externalFolder = externalFolderAndTypes[0]

        if len(indexAndTypes) > 1
          let folderTypes = indexAndTypes[1]
          let lstTypes = split(folderTypes, '|')
          for type in lstTypes
            if type != s:cplusplus &&
            \ type != s:java &&
            \ type != s:js
              continue
            endif

            let outFolderTypes = ''
            if type == s:cplusplus
              let outFolderTypes = s:delETagWithKeyAndType(externalFolder, s:plusplus)
            endif

            if type == s:java
              let outFolderTypes = s:delETagWithKeyAndType(externalFolder, s:java)
            endif

            if type == s:js
              let outFolderTypes = s:delETagWithKeyAndType(externalFolder, s:js)
            endif

            if strlen(outFolderTypes) > 0
              let g:tag_external_folders[index] = folder . ':' . outFolderTypes
            endif

          endfor
          if !has_key(g:tag_externalfolder_tagfile, externalFolder)
            call add(indexToRemove, index)
          endif
        else
          call add(indexToRemove, index)
          if has_key(g:tag_externalfolder_tagfile, externalFolder)
            call remove(g:tag_externalfolder_tagfile, externalFolder)
          endif
        endif
      endif
      let i+= 1
    endwhile

    for tmpfolderWithTypes in folderToRemove
      let j = 0
      for origin in g:tag_external_folders
        if tmpfolderWithTypes == g:tag_external_folders[j]
          call remove(g:tag_external_folders, j)
          break
        endif
        let j += 1
      endfor
    endfor
  else
    if len(g:tag_external_folders) > 1
      call remove(g:tag_external_folders, 0, len(g:tag_external_folders)-1)
    endif
    for key in keys(g:tag_externalfolder_tagfile)
      call remove(g:tag_externalfolder_tagfile, key)
    endfor
  endif

  call s:setTags()
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
  command -nargs=* MakePTags :call s:makeProjectTags(<f-args>)
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
  command -nargs=* -complete=dir AddPTagFolders :call s:addPTagFolders(<f-args>)
endif

if !exists(':DelPTagFolders') && has_key(g:project_cfg, s:key_project_root)
  command -nargs=* DelPTagFolders :call s:delPTagFolders(<f-args>)
endif

if !exists(':AddETagFolders') && has_key(g:project_cfg, s:key_project_root)
  command -nargs=* -complete=dir AddETagFolders :call s:addETagFolders(<f-args>)
endif

if !exists(':DelETagFolders') && has_key(g:project_cfg, s:key_project_root)
  command -nargs=* DelETagFolders :call s:delETagFolders(<f-args>)
endif
