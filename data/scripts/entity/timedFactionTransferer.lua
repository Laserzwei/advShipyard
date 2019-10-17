package.path = package.path .. ";data/scripts/lib/?.lua"
include ("callable")
include ("reconstructiontoken")
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace tFT
tFT = {}
local constructionTime
local timeUntilFinished
local name
local buyer
local captain

function tFT.initialize()
    if onServer() then
        Entity():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
    else
        invokeServerFunction("sendVars")
    end
end

function tFT.sendVars()
    if onServer() then
        broadcastInvokeClientFunction("setVars", constructionTime, timeUntilFinished, name, buyer, captain)
    end
end
callable(tFT, "sendVars")

function tFT.setVars(pConstructionTime, pTimeUntilFinished, pName, pBuyer, pCaptain)
    if not pConstructionTime or not pTimeUntilFinished or not pName or not pBuyer or not pCaptain then
        print("Nothing set")
    else
        constructionTime = pConstructionTime
        timeUntilFinished = pTimeUntilFinished
        name = pName
        buyer = pBuyer
        captain = pCaptain
    end
end

function onRestoredFromDisk(time)
    tFT.update(time)
end

function tFT.getUpdateInterval()
    return 1
end

function tFT.update(timestep)
    if not timeUntilFinished then return end
    timeUntilFinished = timeUntilFinished - timestep

    if timeUntilFinished <= 0 then
        local ship = Entity()
        if onServer() then
            if buyer then
                ship.name = name

                ship.crew = Crew()
                if captain and captain > 0 then
                    -- add base crew
                    local crew = ship.minCrew

                    if captain == 2 then
                        crew:add(1, CrewMan(CrewProfessionType.Captain, true, 1))
                    end

                    ship.crew = crew
                end
                buyerFaction = Faction(buyer)
                buyerFaction:sendChatMessage("Shipyard", ChatMessageType.Normal, "Your ship: %s has finished production"%_t, (ship.name or "(unnamed)"%_t))
                ship.invincible = false
                ship.factionIndex = buyer

                local version = GameVersion()
                if version.major == 0 and version.minor >= 27 then
                    if GameSettings().difficulty < Difficulty.Hard then
                        local token = createReconstructionToken(ship)
                        if GameSettings().difficulty <= Difficulty.Easy then
                            buyerFaction:getInventory():addOrDrop(token, true)
                        end
                        buyerFaction:getInventory():addOrDrop(token, true)
                    end
                else
                    if GameSettings().difficulty < Difficulty.Hard then
                        local token = createReconstructionToken(ship)
                        if GameSettings().difficulty <= Difficulty.Easy then
                            buyerFaction:getInventory():add(token, true)
                        end
                        buyerFaction:getInventory():add(token, true)
                    end
                end

                terminate()
            else
                print(string.format("[Advanced Shipyard Mod] No owner found for ship (-index): %s   in sector: (%i:%i)", ship.index.string, Sector():getCoordinates()))
                terminate()
            end
        end
    end

end

function tFT.renderUIIndicator(px, py, size)
    if timeUntilFinished then
        local x = px - size / 2
        local y = py + size / 2 + 6

        -- outer rect
        local sx = size + 2
        local sy = 4

        drawRect(Rect(x, y, sx + x, sy + y), ColorRGB(0, 0, 0))

        -- inner rect
        sx = sx - 2
        sy = sy - 2

        sx = sx * (constructionTime - (timeUntilFinished or 0)) / constructionTime
        drawRect(Rect(x + 1, y + 1, sx + x + 1, sy + y + 1), ColorRGB(0.66, 0.66, 1.0))
    end
end

function tFT.restore(data)
    tFT.setVars(data.constructionTime, data.time, data.name, data.buyer, data.captain)
end

function tFT.secure()
    local data = {}
    data.constructionTime = constructionTime
    data.time = timeUntilFinished
    data.name = name
    data.buyer = buyer
    data.captain = captain
    return data
end
