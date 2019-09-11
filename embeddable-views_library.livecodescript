script "Levure Embeddable Views Library"
constant kPropertyKey = "embeddable views"
constant kEmbeddableViewDoesNotExist = "embeddable view does not exist"

##########
/**
Summary: Initialize the library

Description:
Handling behavior scripts: An embeddable view has behavior scripts that are associated with it. If the behavior
is a script only stack file then the embeddable view stack stackFiles property references the stack. When opening the
embeddable view stack in the IDE the engine will use the stackFiles property to resolve the behavior reference.

When packaging embeddable views all behaviors are added to the main "behaviors" list so they are loaded into
memory when application launches. This ensures that any stacks using the embeddable view will know where to
find the behavior.
*/
##########
on libraryStack
  if the target is not me then pass libraryStack

  if the environment is "development" then
    _loadBehaviorsIntoMemory
  end if
end libraryStack


/**
Summary: Load behaviors of all embeddable views into memory.

Description:
Instances of embeddable views need access to the behaviors of the
embeddable view. This handler loads all views into memory and then
removes them from memory. This action loads the behaviors associated
with the embeddable view and thus makes the behavior available to any
instances.

Returns: nothing
*/
private command _loadBehaviorsIntoMemory
  # Make all behaviors available in memory.
  local tViewsA, tIsLoaded, i

  put levureAppGet(kPropertyKey) into tViewsA
  lock messages
  repeat with i = 1 to the number of elements of tViewsA
    put the name of stack tViewsA[i]["filename"] into tIsLoaded
    delete stack tViewsA[i]["filename"]
  end repeat
  unlock messages
end _loadBehaviorsIntoMemory


/**
Summary: Returns a CR-delimited list of embeddable view kinds. A `kind` uniquely identifies an embeddable view.

Description:
`kind` is the `name` of the embeddable view stack.

Returns: CR-delimited list
*/
function embedViewsGetKinds
  local tViewsA, tKinds

  put levureAppGet(kPropertyKey) into tViewsA
  repeat with i = 1 to the number of elements of tViewsA
    put tViewsA[i]["name"] & cr after tKinds
  end repeat
  return tKinds
end embedViewsGetKinds


/**
Summary: Returns the width and height of the embeddable view stack.

Returns: Width,Height
*/
function embedViewsGetViewDimensions pViewKind
  local unloadViewStack, msgsAreLocked, tRect

  if not _doesViewResolve(pViewKind) then throw kEmbeddableViewDoesNotExist & ":" && pViewKind
  put not _viewIsInMemory(pViewKind) into unloadViewStack

  put the lockmessages into msgsAreLocked
  lock messages

  put the rect of card 1 of stack pViewKind into tRect

  if unloadViewStack then
    delete stack pViewKind
  end if

  set the lockmessages to msgsAreLocked
  return item 3 of tRect & "," & item 4 of tRect
end embedViewsGetViewDimensions


/**
Summary: Adds an embeddable view instance to the target object.

Parameters:
pViewKind: The kind of the view to embed.
pTargetObject: A reference to a card or group that the view will be inserted into.
pRect: Optional rect to assign to the new instance.

Description:
Pass in pRect so that embeddable view can be created at specific dimensions.
If you create and then resize then resizeControl runs twice.

Returns:
it: Long id of group that was created
the result: Error message
*/
command embedViewsCreateViewInstance pViewKind, pTargetObject, pRect
  local tError, unloadViewStack, msgsAreLocked, tStack, tGroup
  local tDefaultStack, tCurrCard

  if not _doesViewResolve(pViewKind) then throw kEmbeddableViewDoesNotExist & ":" && pViewKind
  put not _viewIsInMemory(pViewKind) into unloadViewStack

  put _resolveStack(pTargetObject) into tStack

  put the lockmessages into msgsAreLocked
  lock messages
  lock screen

  reset the templategroup

  if pTargetObject begins with "stack" or pTargetObject begins with "card" then
    put the defaultStack into tDefaultStack
    set the defaultStack to the short name of tStack
    if pTargetObject begins with "card" then
      put the currentCard of tStack into tCurrCard
      set the currentCard of tStack to the short name of pTargetObject
    end if
    create group
    put it into tGroup
  else if pTargetObject begins with "group" then
    create group in pTargetObject
    put it into tGroup
  end if
  set the margins of tGroup to 0
  set the borderwidth of tGroup to 0
  set the showborder of tGroup to false
  set the opaque of tGroup to false
  set the showname of tGroup to false
  if the buildnumber >= 15500 then // 9.5dp-1
    set the layermode of tGroup to "container"
  end if

  if pRect is not a rect then
    local tLoc
    put the loc of pTargetObject into tLoc
    put item 1 of tLoc - 150 into item 1 of pRect
    put item 2 of tLoc - 150 into item 2 of pRect
    put item 1 of tLoc + 150 into item 3 of pRect
    put item 2 of tLoc + 150 into item 4 of pRect
  end if

  set the uEmbeddableViewKind of tGroup to pViewKind
  set the selectGroupedControls of tGroup to false
  set the clipsToRect of tGroup to true

  if pRect is a rect then
    set the rect of tGroup to pRect
  end if

  if unloadViewStack then
    delete stack pViewKind
  end if

  if tCurrCard is not empty then
    set the currentCard of tStack to tCurrCard
  end if
  if tDefaultStack is not empty then
    set the defaultStack to tDefaultStack
  end if

  set the lockMessages to msgsAreLocked

  embedViewsInsertViewIntoInstance pViewKind, tGroup
  put the result into tError
  unlock screen

  if tError is empty then
    return tGroup for value
  else
    return tError for error
  end if
end embedViewsCreateViewInstance


/**
Summary: Inserts the contents of the specified embeddable view id into an instance of the embeddable view (a group control).

Parameters:
pViewKind: Embeddable view identifier
pGroupObject: Object reference that can have controls copied into it.

Returns: Error
*/
command embedViewsInsertViewIntoInstance pViewKind, pGroupObject
  local tError

  if not _doesViewResolve(pViewKind) then throw kEmbeddableViewDoesNotExist & ":" && pViewKind

  if tError is empty then
    local tTargetObject
    local tRestoreLockLoc, unloadViewStack, msgsAreLocked

    lock screen

    put not _viewIsInMemory(pViewKind) into unloadViewStack
    put the lockLoc of pGroupObject into tRestoreLockLoc
    set the lockLoc of pGroupObject to true

    put the long id of this card of stack pViewKind into tTargetObject

    embedViewsRemoveInstanceContents pGroupObject

    set the uEmbeddableViewKind of pGroupObject to pViewKind
    if the behavior of tTargetObject is not empty then
      set the behavior of pGroupObject to the behavior of tTargetObject
    end if

    local tTopLeft, tControlTopLeft, tWordOffset

    put the lockmessages into msgsAreLocked
    lock messages

    put the topleft of pGroupObject into tTopLeft
    put 5 into tWordOffset

    repeat with i = 1 to the number of controls of tTargetObject
      # Only copy root controls
      if word tWordOffset of the long id of control i of tTargetObject is "group" then next repeat

      put the topLeft of control i of tTargetObject into tControlTopLeft
      add item 1 of tTopLeft to item 1 of tControlTopLeft
      add item 2 of tTopLeft to item 2 of tControlTopLeft

      copy control i of tTargetObject to pGroupObject
      set the topleft of it to tControlTopLeft
    end repeat

    # Free memory
    if unloadViewStack then
      delete stack pViewKind
    end if

    unlock messages
    dispatch "resizeControl" to pGroupObject

    set the lockMessages to msgsAreLocked
    set the lockLoc of pGroupObject to tRestoreLockLoc

    unlock screen
  end if

  return tError for error
end embedViewsInsertViewIntoInstance


/**
Summary: Removes the contents of an instance of an embeddable view.

Parameters:
pGroupObject: Group that represents an embeddable view.

Returns: empty
*/
command embedViewsRemoveInstanceContents pGroupObject
  local msgsAreLocked

  put the lockmessages into msgsAreLocked
  lock messages

  # Clear out existing controls
  repeat with i = the number of groups of pGroupObject down to 1
    delete group i of pGroupObject
  end repeat
  repeat with i = the number of controls of pGroupObject down to 1
    delete control i of pGroupObject
  end repeat

  set the lockMessages to msgsAreLocked
  return empty
end embedViewsRemoveInstanceContents


/**
Summary: Returns true if a stack is an embeddable view stack.

Parameters:
pStackName: The name of the stack to check.

Returns: true/false
*/
function embedViewsStackIsAView pStackName
  local tViewsA

  put levureAppGet(kPropertyKey) into tViewsA
  repeat with i = 1 to the number of elements of tViewsA
    if tViewsA[i]["name"] is pStackName then
      return true
    end if
  end repeat
  return false
end embedViewsStackIsAView


/**
Summary: Updates all instances of an embeddable view within the application.

Description:
The "Levure Embeddable Views Frontscript" frontscript calls this in the IDE after
saving an embeddable view stack. All instances of the embeddable view in other embeddable views
as well as application stacks will be updated.

Returns:
it: CR-delimited list of the long ids of stacks that were updated.
the result: Error message.
*/
command embedViewsUpdateViewInstances pKind
  local tError

  _updateViewInstances pKind
  put the result into tError

  if tError is empty then
    return the keys of it for value
  else
    return tError for error
  end if
end embedViewsUpdateViewInstances


private command _updateViewInstances pKind
  local tError, tUpdatedViewStacksA

  if tError is empty then
    _updateViewInstancesInNonViewAppUIStacks pKind
    put the result into tError
  end if

  if tError is empty then
    put it into tUpdatedViewStacksA

    _updateViewInstancesInViews pKind
    put the result into tError

    if tError is empty then
      if it is an array then
        union tUpdatedViewStacksA with it
      end if
    end if
  end if

  if tError is empty then
    return tUpdatedViewStacksA for value
  else
    return tError for error
  end if
end _updateViewInstances


/**
Summary: Updates an embeddable view in other embeddable views (not instances).

Returns:
it: Array whose keys are the long ids of stacks that were updated.
the result: Error message
*/
private command _updateViewInstancesInViews pKind
  local tError, tViewsA, tStackIsInMemory, i
  local tUpdatedViewStacksA, tUpdatedSomething = "false"

  put levureAppGet(kPropertyKey) into tViewsA

  repeat with i = 1 to the number of elements of tViewsA
    if tViewsA[i]["name"] is pKind then next repeat

    put there is a stack tViewsA[i]["name"] into tStackIsInMemory

    embedViewsUpdateViewInstancesInStack the long id of stack tViewsA[i]["filename"], pKind
    put the result into tError

    # If embeddable view contained an instance of our target embeddable view kind then run updates for this embeddable view
    if tError is empty and it is true then
      put empty into tUpdatedViewStacksA[ the long id of stack tViewsA[i]["filename"] ]
      if the environment is "development" then
        # Any embeddable views that are updated are automatically saved
        revIDESaveStack the long id of stack tViewsA[i]["filename"]
        put the result into tError
      end if

      if tError is empty then
        _updateViewInstances tViewsA[i]["name"]
        put the result into tError
      end if

      if tError is empty then
        if it is an array then
          union tUpdatedViewStacksA with it
        end if
      end if
    end if

    if not tStackIsInMemory then
      delete stack stack tViewsA[i]["filename"]
    end if

    if tError is not empty then exit repeat
  end repeat

  if tError is empty then
    return tUpdatedViewStacksA for value
  else
    return tError for error
  end if
end _updateViewInstancesInViews


/**
Summary: Updates all toplevel instances of an embeddable view in app ui stacks that are not embeddable views. Stacks will be saved.

Returns:
it: Array whose keys are the long ids of stacks that were updated.
the result: Error message
*/
private command _updateViewInstancesInNonViewAppUIStacks pKind
  local tError, tStacksA, tStack
  local tUpdatedStacksA, tStackIsInMemory

  put levureGetUIStacks() into tStacksA

  repeat with i = 1 to the number of elements of tStacksA
    if tStacksA[i]["key"] is kPropertyKey then next repeat

    put there is a stack tStacksA[i]["name"] into tStackIsInMemory
    if tStackIsInMemory and the filename of stack tStacksA[i]["name"] is not tStacksA[i]["filename"] then
      put "Skipping stack" && quote & tStacksA[i]["name"] & quote && "because a stack with the same name but a different filename is already loaded." & cr after msg
      next repeat
    end if

    embedViewsUpdateViewInstancesInStack the long id of stack tStacksA[i]["filename"], pKind
    put the result into tError

    if tError is empty and it is true then
      put empty into tUpdatedStacksA[ the long id of stack tStacksA[i]["filename"] ]
      if the environment is "development" then
        # Any embeddable views that are updated are automatically saved
        revIDESaveStack the long id of stack tStacksA[i]["filename"]
        put the result into tError
      end if
    end if

    if not tStackIsInMemory then
      delete stack stack tStacksA[i]["filename"]
    end if

    if tError is not empty then exit repeat
  end repeat

  if tError is empty then
    return tUpdatedStacksA for value
  else
    return tError for error
  end if
end _updateViewInstancesInNonViewAppUIStacks


/**
Summary: Updates view instances in a stack.

Parameters:
pStackObject: Reference to the stack to check for embeddable views.
pKind: Optional embeddable view kind. If non-empty then only embeddable views of this kind will be updated.

Returns:
it: Boolean value. `true` if the stack contained one or more embeddable views and they were updated.
the result: Error message
*/
command embedViewsUpdateViewInstancesInStack pStackObject, pKind
  local tError, i, tGroup, tGroups
  local tGroupsToUpdate

  # First check the background groups
  repeat for each line tId in the backgroundIds of pStackObject
    if there is not a group id tId of pStackObject then next repeat

    put the long id of group id tId of pStackObject into tGroup
    if (pKind is not empty and the uEmbeddableViewKind of tGroup is pKind) \
          or (pKind is empty and the uEmbeddableViewKind of tGroup is not empty) then
      put tGroup & cr after tGroupsToUpdate
    else if the uEmbeddableViewKind of tGroup is empty then
      put _groupChildrenViewInstances(tGroup, pKind) into tGroups
      if tGroups is not empty then
        put tGroups & cr after tGroupsToUpdate
      end if
    end if
  end repeat

  if tError is empty then
    repeat with i = 1 to the number of cards of pStackObject
      repeat for each line tId in the groupIds of card i of pStackObject
        put the long id of group id tId of card i of pStackObject into tGroup
        if (pKind is not empty and the uEmbeddableViewKind of tGroup is pKind) \
              or (pKind is empty and the uEmbeddableViewKind of tGroup is not empty) then
          put tGroup & cr after tGroupsToUpdate
        else if the uEmbeddableViewKind of tGroup is empty then
          put _groupChildrenViewInstances(tGroup, pKind) into tGroups
          if tGroups is not empty then
            put tGroups & cr after tGroupsToUpdate
          end if
        end if
      end repeat
    end repeat
  end if

  if tError is empty then
    local tGroupsA

    # In case we have duplicates between background and groups on cards
    repeat for each line tGroup in tGroupsToUpdate
      put empty into tGroupsA[tGroup]
    end repeat

    repeat for each key tGroup in tGroupsA
      _updateInstanceView tGroup
      put the result into tError

      if tError is not empty then exit repeat
    end repeat
  end if

  if tError is empty then
    return tGroupsToUpdate is not empty for value
  else
    return tError for error
  end if
end embedViewsUpdateViewInstancesInStack


/**
Summary: Returns toplevel embeddable view instances in a group.

Description:
Returns a CR-delimited list of groups that are embeddable view instances. Only parent instances
will be returned.

Returns: CR-delimited list of group ids
*/
private function _groupChildrenViewInstances pGroup, pKind
  local tId, tGroup, tInstances, tChildInstances

  repeat for each line tId in the childControlIds of pGroup
    put the long id of control id tId of pGroup into tGroup
    if word 1 of tGroup is not "group" then next repeat

    if (pKind is not empty and the uEmbeddableViewKind of tGroup is pKind) \
          or (pKind is empty and the uEmbeddableViewKind of tGroup is not empty) then
      put tGroup & cr after tInstances
    else if word 1 of tGroup is "group" and the uEmbeddableViewKind of tGroup is empty then
      put _groupChildrenViewInstances(tGroup, pKind) into tChildInstances
      if tChildInstances is not empty then
        put tChildInstances & cr after tInstances
      end if
    end if
  end repeat

  delete the last char of tInstances
  return tInstances
end _groupChildrenViewInstances


private command _updateInstanceView pGroup
  local tError

  if _doesViewResolve(the uEmbeddableViewKind of pGroup) then
    embedViewsInsertViewIntoInstance the uEmbeddableViewKind of pGroup, pGroup
    put the result into tError
  else

  end if

  return tError for error
end _updateInstanceView


/**
Summary: Returns true if an embeddable view is available to the app.

Returns (boolean): true/false
*/
private function _doesViewResolve pViewKind
  local tViewsA

  repeat for each line tLine in the stackFiles of stack levureAppStackName()
    if item 1 of tLine is pViewKind then
      return true
    end if
  end repeat
  return false
end _doesViewResolve


private function _viewIsInMemory pViewKind
  set the wholematches to true
  return pViewKind is among the lines of the mainstacks
end _viewIsInMemory


private function _resolveStack pTarget
  local tStack

  if word 1 of pTarget is "card" then
    put the long id of the owner of pTarget into tStack
  else if word 1 of pTarget is "stack" then
    put the long id of pTarget into tStack
  else
    local tOffset
    put the long id of pTarget into tStack
    put offset(" of stack", tStack) into tOffset
    if tOffset > 0 then
      delete char 1 to (tOffset + 3) of tStack
      put the long id of tStack into tStack
    end if
  end if

  return tStack
end _resolveStack
