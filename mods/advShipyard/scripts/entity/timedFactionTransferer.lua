
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace tFT
tFT = {}

function tFT.initialize()

    if onServer() then
        if not Entity():getValue("duration") then
            print(Entity().name, "duration not set")
            terminate()
        end
        if not Entity():getValue("timePassed") then
            Entity():setValue("timePassed", 0)
        end
    end
end

function tFT.getUpdateInterval()
    return 1
end

function tFT.update(timestep)
    local ship = Entity()
    local timePassed = ship:getValue("timePassed") + timestep
    local duration = ship:getValue("duration") or math.huge
    if onServer() then ship:setValue("timePassed", timePassed) end

    if timePassed >= duration then
        local owner = ship:getValue("buyer")
        if owner then
            if onServer() then
                ship.name = ship:getValue("name")
                ship.invincible = false
                local captain = ship:getValue("captain")
                ship.crew = Crew()
                if captain and captain > 0 then
                    -- add base crew
                    local crew = ship.minCrew

                    if captain == 2 then
                        crew:add(1, CrewMan(CrewProfessionType.Captain, true, 1))
                    end

                    ship.crew = crew
                end

                ship:setValue("timePassed", nil)
                ship:setValue("duration", nil)
                ship:setValue("name", nil)
                ship:setValue("buyer", nil)
                ship:setValue("captain", nil)
                Faction(owner):sendChatMessage("Shipyard", ChatMessageType.Normal, "Your ship: "..(ship.name or "(unnamed)").." has finished")
            end
            ship.factionIndex =  owner
            terminate()
        else
            print("[advShipyard]  No owner found:", ship.index.string, Sector():getCoordinates())
        end
    end

end

function tFT.renderUIIndicator(px, py, size)
    local duration = Entity():getValue("duration")
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

        sx = sx * (Entity():getValue("timePassed") or 0) / duration

        drawRect(Rect(x + 1, y + 1, sx + x + 1, sy + y + 1), ColorRGB(0.66, 0.66, 1.0))
    end
end
