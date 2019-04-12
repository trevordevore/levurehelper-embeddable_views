script "Embeddable Views Levure Callbacks"
constant kPropertyKey = "embeddable views"

/**
Summary: Add behaviors for all embeddable views to app behaviors list so that they are packaged up.

Description:
All embeddable view behaviors need to be loaded up so the engine can find them whenever an embeddable view is needed.
This handler will add to the list of behaviors in the app array so that behaviors will be loaded at launch.

Possible improvement – another approach would be to determine stacks where embeddable views are used and add the embeddable view stack stackfiles
references to the stackfile property of stacks that uses the embeddable view. That is rather involved, however, and
is not being considered at this time.
*/
command finalizePackagedAssets pBuildProfile, pPlatform, @xAppA, pAppFolder
  local tIndex, i
  local tViewFile, tStackExists, tStackFiles, tStackfile

  # add to xAppA["behaviors"]
  put the number of elements of xAppA["behaviors"] into tIndex

  repeat with i = 1 to the number of elements of xAppA[kPropertyKey]
    put xAppA[kPropertyKey][i]["filename"] into tViewFile
    put there is a stack tViewFile into tStackExists

    if tStackExists then
      put the stackFiles of stack tViewFile into tStackFiles
      delete stack tViewFile

      repeat for each line tLine in tStackFiles
        put item 2 to -1 of tLine into tStackfile
        put _resolveFilenameReference(tStackfile, _extractDir(tViewFile)) into tStackfile

        if there is a stack tStackFile then
          if isFilenameUniqueInFilesArray(tStackFile, xAppA["behaviors"]) then
            add 1 to tIndex
            put tStackfile into xAppA["behaviors"][tIndex]["filename"]
          end if
          delete stack tStackfile
        end if
      end repeat
    end if
  end repeat
end finalizePackagedAssets


/**
Summary: Delete behaviors folder in packaged embeddable view.

Description:
The behaviors have already been added to the "behaviors" list so no need to package them
with the application.
*/
command finalizePackagedUIAsset pBuildProfile, pPlatform, pViewFolder
  if there is a folder (pViewFolder & "/behaviors") then
    revDeleteFolder pViewFolder & "/behaviors"
  end if
end finalizePackagedUIAsset


private function isFilenameUniqueInFilesArray pFilename, pFilesA
  local i

  repeat with i = 1 to the number of elements of pFilesA
    if pFilesA[i]["filename"] is pFilename then
      return false
    end if
  end repeat

  return true
end isFilenameUniqueInFilesArray


private function _resolveFilenameReference pFilename, pRootFolder
  repeat while the last char of pFilename is "/"
    delete the last char of pFilename
  end repeat

  if _isFilenameRelative(pFilename) then
    put _normalizeRelativeFilename(pFilename) into pFilename

    if pFilename begins with "../" then
      return _resolveRelativeFilenameReference(pFilename, pRootFolder) for value
    else
      return pRootFolder & "/" & pFilename for value
    end if
  else
    return pFilename for value
  end if
end _resolveFilenameReference


private function _normalizeRelativeFilename pFilename
  if char 1 of pFilename is "/" then
    delete char 1 of pFilename
  else if char 1 to 2 of pFilename is "./" then
    delete char 1 to 2 of pFilename
  end if
  return pFilename for value
end _normalizeRelativeFilename


private function _resolveRelativeFilenameReference pFilename, pRootFolder
  set the itemDelimiter to "/"

  repeat while pFilename begins with "../"
    if pRootFolder is empty then
      return "relative path is too deep for root folder" for error
    else
      delete the last item of pRootFolder
      delete char 1 to 3 of pFilename
    end if
  end repeat

  return pRootFolder & "/" & pFilename for value
end _resolveRelativeFilenameReference


private function _isFilenameRelative pFilename
  set the itemDelimiter to "/"
  -- [[ is for variables
  return not ((the platform is "win32" and item 1 of pFilename contains ":") or pFilename begins with "/" or pFilename begins with "[[")
end _isFilenameRelative


private function _extractDir pFilename
  set the itemDelimiter to slash
  return item 1 to -2 of pFilename
end _extractDir
