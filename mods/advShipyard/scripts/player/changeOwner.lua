local factionIndex
function initialize(index)
    if onClient() then
        sendTarget()
    else
        if index then factionIndex = index end
    end
end

function sendTarget()
    local target = Player().selectedObject
    invokeServerFunction("changeOwnership", target.string)
end

function changeOwnership(target)
    if onServer() then
        local e = Entity(Uuid(target))
        print("a", target)
        if valid(e) then
            if factionIndex  then
                e.factionIndex = factionIndex
            else
                e.factionIndex = Player().index
            end
        end
    end
    terminate()
end
