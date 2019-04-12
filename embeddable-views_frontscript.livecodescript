script "Levure Embeddable Views Frontscript"
local sProcessingSaveRequest = "false"

/**
Summary: In the development environemnt look for and update embeddable views on cards of stack being opened.
*/
on preOpenStack
  if the environment is "development" then
    embedViewsUpdateViewInstancesInStack the long id of the owner of the target
  end if

  pass preOpenStack
end preOpenStack


/**
Summary: When an embeddable view stack is saved update instances of the embeddable view.

Description:
In the development environment any time an embeddable view stack is saved instances
of the embeddable view in other embeddable views and in open stacks must be updated.
*/
on saveStackRequest
  if the environment is "development" and not sProcessingSaveRequest and embedViewsStackIsAView(the short name of the owner of the target) then
    local tError

    put true into sProcessingSaveRequest
    put empty

    embedViewsUpdateViewInstances the short name of the owner of the target
    put the result into tError

    if tError is not empty then
      answer error "An error occurred while updating an instance of this embeddable view:" && tError & "."
    else
      beep
      put "The following stacks were updated:" & cr & the long id of the owner of the target & cr & it after msg
    end if

    put false into sProcessingSaveRequest
  end if

  pass saveStackRequest
end saveStackRequest
