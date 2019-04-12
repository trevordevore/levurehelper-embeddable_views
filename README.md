# embeddable_views

Embeddable Views is a helper for [Levure](https://github.com/trevordevore/levure) applications. It allow a [LiveCode](https://livecode.com) developer to embed the contents of a card in "instances" (groups with special properties) throughout their application. This introduces the following benefits:

* A complex user interface can be worked on in smaller pieces – Complex interfaces can be made of up of many nested groups. This makes editing the UI more difficult. An embeddable view allows you to work on a single card of controls.
* Edit a shared interface in one location – if your application uses the same interface in multiple locations you only have to edit one card.
* Updated while editing – When you edit the controls of an embeddable view card while working in the IDE all instances of the embeddable view in the Levure application are updated.

## What is an embeddable view made of (besides sugar and spice and everything nice)?

An embeddable view is a stack with a single card that is stored in it's own folder (just like `ui` stacks in Levure).

If the embeddable view requires a script then you should create a script only stack and assign it as the behavior of the card. Just create a `behaviors` folder alongside the stack file and place the script only stack in the folder. (Don't forget to assign the script only stack file to the `stackFiles` property of the stack.)

Here is an example showing a `file_inspector` embeddable view structure:

* :open_file_folder: app
  - :open_file_folder: embeddable_views
    - :open_file_folder: file_inspector
      - :open_file_folder: behaviors
        - file_inspector_card_behavior.livecodescript
      - file_inspector.livecode
  - :file_folder: ui
  - :file_folder: libraries
  - app.yml

## What is an "instance" of an embeddable view?

An instance of an embeddable view is simply a group. The group has an `uEmbeddableViewKind` property that associates the group with a specific embeddable view.

When you add an instance of an embeddable view to a card or group a new group is created and the contents of the embeddable view's card will are copied into the group. The behavior of the embeddable view card (if present) is assigned to the group as well.

The `selectGroupedControls` property of the instance group will be set to `false` and the `clipsToRect` property will be set to `true`.

## Where do embeddable views go in a Levure app folder?

Add the following entry to the `app.yml` file and place all embeddable view folders inside of the `./app/embeddable_views` folder.

```
embeddable views:
  - folder: ./embeddable views
```

## Inserting an embeddable view instance

To insert a new instance of an embeddable view using code call [`embedViewsInsertViewIntoInstance`](#embedViewsInsertViewIntoInstance). 

To preview and insert embeddable views using a user interface install the [Baker's Assistant](https://github.com/trevordevore/bakers-assistant) plugin.

## Keeping embeddable views up to date

When working in the LiveCode IDE a frontscript is inserted which keeps embeddable views up to date while you work. The stack is named `"Levure Embeddable Views Frontscript"` and has two handlers - `preOpenStack` and `saveStackRequest`. 

### Refreshing instances of embeddable Views when opening a stack

Whenever you open a stack in the IDE the `preOpenStack` handler calls `embedViewsUpdateViewInstancesInStack` which refreshes all top level instances of embeddable views within the stack.

### Saving changes to an embeddable view

Whenever you save an embeddable view stack the `saveStackRequest` handler updates instances of that view throughout your Levure application. It calls `embedViewsUpdateViewInstances` which performs this operation and saves any stacks that were updated.

## What happens when packaging a Levure application that uses embeddable views?

When packaging a Levure application the `finalizePackagedAssets` in the `embeddable-views_levure_callbacks.livecodescript` stack file performs the following modifications:

1) All behaviors used the script only stack files used as behaviors in the embeddable views will be added to the list of `behaviors` used in the application. Script only stack files being used as behaviors are detected by inspecting the `stackfiles` property of each embeddable view stack. 

2) The `behaviors` folder in each embeddable view folder will be deleted. Since the behaviors were added to the application behaviors property they are no longer needed for distribution.

## API

- [embedViewsCreateViewInstance](#embedViewsCreateViewInstance)
- [embedViewsGetKinds](#embedViewsGetKinds)
- [embedViewsInsertViewIntoInstance](#embedViewsInsertViewIntoInstance)
- [embedViewsRemoveInstanceContents](#embedViewsRemoveInstanceContents)
>
- [embedViewsStackIsAView](#embedViewsStackIsAView)
- [embedViewsUpdateViewInstances](#embedViewsUpdateViewInstances)
- [embedViewsUpdateViewInstancesInStack](#embedViewsUpdateViewInstancesInStack)
- [libraryStack](#libraryStack)

<br>

## <a name="embedViewsCreateViewInstance"></a>embedViewsCreateViewInstance

**Type**: command

**Syntax**: `embedViewsCreateViewInstance <pViewKind>,<pTargetObject>,<pRect>`

**Summary**: Adds an embeddable view instance to the target object.

**Returns**: <br>**it**: Long id of group that was created<br>**the result**: Error message

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pViewKind` |  The kind of the view to embed. |
| `pTargetObject` |  A reference to a card or group that the view will be inserted into. |
| `pRect` |  Optional rect to assign to the new instance. |

**Description**:

Pass in pRect so that embeddable view can be created at specific dimensions.
If you create and then resize then resizeControl runs twice.

<br>

## <a name="embedViewsGetKinds"></a>embedViewsGetKinds

**Type**: function

**Syntax**: `embedViewsGetKinds()`

**Summary**: Returns a CR-delimited list of embeddable view kinds. A `kind` uniquely identifies an embeddable view.

**Returns**: CR-delimited list

**Description**:

`kind` is the `name` of the embeddable view stack.

<br>

## <a name="embedViewsInsertViewIntoInstance"></a>embedViewsInsertViewIntoInstance

**Type**: command

**Syntax**: `embedViewsInsertViewIntoInstance <pViewKind>,<pGroupObject>`

**Summary**: Inserts the contents of the specified embeddable view id into an instance of the embeddable view (a group control).

**Returns**: Error

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pViewKind` |  Embeddable view identifier |
| `pGroupObject` |  Object reference that can have controls copied into it. |

<br>

## <a name="embedViewsRemoveInstanceContents"></a>embedViewsRemoveInstanceContents

**Type**: command

**Syntax**: `embedViewsRemoveInstanceContents <pGroupObject>`

**Summary**: Removes the contents of an instance of an embeddable view.

**Returns**: empty

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pGroupObject` |  Group that represents an embeddable view. |

<br>

## <a name="embedViewsStackIsAView"></a>embedViewsStackIsAView

**Type**: function

**Syntax**: `embedViewsStackIsAView(<pStackName>)`

**Summary**: Returns true if a stack is an embeddable view stack.

**Returns**: true/false

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pStackName` |  The name of the stack to check. |

<br>

## <a name="embedViewsUpdateViewInstances"></a>embedViewsUpdateViewInstances

**Type**: command

**Syntax**: `embedViewsUpdateViewInstances <pKind>`

**Summary**: Updates all instances of an embeddable view within the application.

**Returns**: <br>**it**: CR-delimited list of the long ids of stacks that were updated.<br>**the result**: Error message.

**Description**:

The "Levure Embeddable Views Frontscript" frontscript calls this in the IDE after
saving an embeddable view stack. All instances of the embeddable view in other embeddable views
as well as application stacks will be updated.

<br>

## <a name="embedViewsUpdateViewInstancesInStack"></a>embedViewsUpdateViewInstancesInStack

**Type**: command

**Syntax**: `embedViewsUpdateViewInstancesInStack <pStackObject>,<pKind>`

**Summary**: Updates view instances in a stack.

**Returns**: <br>**it**: Boolean value. `true` if the stack contained one or more embeddable views and they were updated.<br>**the result**: Error message

**Parameters**:

| Name | Description |
|:---- |:----------- |
| `pStackObject` |  Reference to the stack to check for embeddable views. |
| `pKind` |  Optional embeddable view kind. If non-empty then only embeddable views of this kind will be updated. |

<br>

## <a name="libraryStack"></a>libraryStack

**Type**: command

**Syntax**: `libraryStack `

**Summary**: Initialize the library

**Description**:

Handling behavior scripts: An embeddable view has behavior scripts that are associated with it. If the behavior
is a script only stack file then the embeddable view stack stackFiles property references the stack. When opening the
embeddable view stack in the IDE the engine will use the stackFiles property to resolve the behavior reference.

When packaging embeddable views all behaviors are added to the main "behaviors" list so they are loaded into
memory when application launches. This ensures that any stacks using the embeddable view will know where to
find the behavior.
