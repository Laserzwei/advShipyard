package.path = package.path .. ";data/scripts/lib/?.lua"
require ("faction")


local nameTextBox
local titleTextBox
local confirmButton
local cancelButton

function initialize(name)
    if name ~= nil then
        setName(name)
    end
end

function interactionPossible(playerIndex, option)
    return checkEntityInteractionPermissions(Entity(), {AlliancePrivilege.ModifyCrafts})
end

function initUI()
    local res = getResolution()
    local size = vec2(350, 200)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Rename"
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "rename Ship")

    local x = 10
    local y = 10

    local textBoxSizeX = 300
    local textBoxSizeY = 25
    local buttonSizeX = 100
    local buttonSizeY = 25
    local lb = window:createLabel(vec2(x,y), "Name", 15)
    y = y + 25
    nameTextBox = window:createTextBox(Rect(x, y, x + textBoxSizeX, y + textBoxSizeY), "onNameChanged")
    nameTextBox.text = Entity().name or ""

    y = y + 35
    local lb = window:createLabel(vec2(x,y), "Title", 15)
    y = y + 25
    titleTextBox = window:createTextBox(Rect(x, y, x + textBoxSizeX, y + textBoxSizeY), "onTitleChanged")
    titleTextBox.text = Entity().title or ""


    confirmButton = window:createButton(Rect(x, size.y-10-buttonSizeY, x + buttonSizeX, size.y-10), "confirm", "onConfirmPressed")
    confirmButton.tooltip = "Confirm your name-changes."
    cancelButton = window:createButton(Rect(size.x - 10- buttonSizeX, size.y-10-buttonSizeY, size.x - 10, size.y-10), "cancel", "onCancelPressed")
    cancelButton.tooltip = "Cancel renaming."
end

function onNameChanged() end
function onTitleChanged() end

function onConfirmPressed()
    if string.len(nameTextBox.text) < 3 then
        displayChatMessage("Ship name has to be at least 3 characters long!", "", 0)
    else
        invokeServerFunction("setName", nameTextBox.text)
        local renameText = "Ship "..(Entity().name or "").." has been renamed to "..nameTextBox.text
        displayChatMessage(renameText, "", 0)
    end
    invokeServerFunction("setTitle", titleTextBox.text or "")
    ScriptUI():stopInteraction()
end

function onCancelPressed()
    ScriptUI():stopInteraction()
end

function setName(newName)
    Entity():waitUntilAsyncWorkFinished()
    if onServer() then
        Entity().name = newName
    else
        print("setName onClient")
    end
end

function setTitle(newTitle)
    if onServer() then
        Entity().title = newTitle
    else
        print("setName onClient")
    end
end
