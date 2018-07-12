
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace tFT
tFT = {}

local duration
local timePassed

function tFT.initialize()
    duration = Entity():getValue("duration") or 0
    timePassed = Entity():getValue("timePassed") or 0
    if onServer() then
        if not duration then
            print(Entity().name, "duration not set")
            terminate()
        end
        if not timePassed then
            timePassed = 0
            Entity():setValue("timePassed", timePassed)
        end
    end
end

function tFT.getUpdateInterval()
    return 1
end

function tFT.update(timestep)
    timePassed = timePassed + timestep
    Entity():setValue("timePassed", timePassed)
    if timePassed >= duration then
        local owner = Entity():getValue("buyer")
        if owner then
            if onServer() then
                Entity().name = Entity():getValue("name")
                Entity().invincible = false

                Entity():setValue("timePassed", nil)
                Entity():setValue("duration", nil)
                Entity():setValue("name", nil)
                Entity():setValue("buyer", nil)
                Faction(owner):sendChatMessage("Shipyard", ChatMessageType.Normal, "Your ship: "..(Entity().name or "(unnamed)").." has finished")
            end
            Entity().factionIndex =  owner
            terminate()
        else
            print("[advShipyard]  No owner found:", Entity().index.string, Sector():getCoordinates())
        end
    end
end

function tFT.renderUIIndicator(px, py, size)
    if duration then
        local x = px - size / 2
        local y = py + size / 2 + 6

        -- outer rect
        local sx = size + 2
        local sy = 4

        drawRect(Rect(x, y, sx + x, sy + y), ColorRGB(0, 0, 0))

        -- inner rect
        sx = sx - 2
        sy = sy - 2

        sx = sx * timePassed / duration

        drawRect(Rect(x + 1, y + 1, sx + x + 1, sy + y + 1), ColorRGB(0.66, 0.66, 1.0))
    end
end
