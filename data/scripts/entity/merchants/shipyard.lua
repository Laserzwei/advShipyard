local config = include("data/config/advshipyardconfig")

-- Menu items
local shipSelectionWindow

-- ship building menu items
local selectShipDesignButton

-- ship selectionwindow
local planSelection
local selectionPlandisplayer

local advSY_oldInitUI = Shipyard.initUI
-- create all required UI elements for the client side
function Shipyard.initUI()
    local menu = ScriptUI()

    advSY_oldInitUI()

    local res = getResolution()
    local size = vec2(800, 600)
    local vsplit = UIVerticalSplitter(Rect(vec2(0, 0), size), 10, 10, 0.5)
    -- custom designs
    local rect = Rect(statsCheckBox.rect.lower + vec2(0, 25), statsCheckBox.rect.upper + vec2(0, 35))
    selectShipDesignButton = window:createButton(Rect(), "Select Design" % _t, "onDesignButtonPress")
    selectShipDesignButton.rect = rect

    shipSelectionWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    shipSelectionWindow.caption = "Select your Design" % _t
    shipSelectionWindow.showCloseButton = 1
    shipSelectionWindow.moveable = 1
    shipSelectionWindow.visible = 0

    local selectDesignButton = shipSelectionWindow:createButton(Rect(vec2(10, shipSelectionWindow.size.y - 65), vec2(130, shipSelectionWindow.size.y - 20)), "Select" % _t, "onPlanSelectedPressed")
    local cancelButton = shipSelectionWindow:createButton(Rect(vec2(150, shipSelectionWindow.size.y - 65), vec2(250, shipSelectionWindow.size.y - 20)), "Deselect" % _t, "onDesignCancelPressed")

    planSelection = shipSelectionWindow:createSavedDesignsSelection(Rect(vec2(10, 10), vec2(shipSelectionWindow.size.x / 2, shipSelectionWindow.size.y - 100)), 5)
    planSelection.dropIntoSelfEnabled = false
    planSelection.dropIntoEnabled = false
    planSelection.dragFromEnabled = false
    planSelection.entriesSelectable = true
    planSelection.onSelectedFunction = "onDesignSelected"
    planSelection.padding = 4

    selectionPlandisplayer = shipSelectionWindow:createPlanDisplayer(Rect(vec2(shipSelectionWindow.size.x / 2, 0), vec2(shipSelectionWindow.size.x, shipSelectionWindow.size.y - 100)))
    selectionPlandisplayer.showStats = false
end

-- TODO no overwrite, just customization
local advSY_oldRenderUI = Shipyard.renderUI
function Shipyard.renderUI()

    local ship = Player().craft
    if not ship then
        return
    end

    local buyer = Faction(ship.factionIndex)
    if buyer.isAlliance then
        buyer = Alliance(buyer.index)
    elseif buyer.isPlayer then
        buyer = Player(buyer.index)
    end

    local fee = GetFee(Faction(), buyer) * 2

    local planMoney = preview:getMoneyValue()

    local planResources = {preview:getResourceValue()}
    local planResourcesFee = {}
    local planResourcesTotal = {}

    local foundingResources = ShipFounding.getNextShipCosts(buyer)

    local timeToConstruct = math.floor(20.0 + preview.durability / 100.0)
    -- crew
    local crewMoney = 0
    if captainCombo.selectedIndex > 0 then
        crewMoney = Shipyard.getCrewMoney(preview, captainCombo.selectedIndex == 2)
        timeToConstruct = timeToConstruct + 300
    end

    -- plan resources
    for _, v in pairs(planResources) do
        table.insert(planResourcesTotal, v)
    end

    -- founding resources
    for i, amount in pairs(foundingResources) do
        planResourcesTotal[i] = planResourcesTotal[i] + amount
    end

    local offset = 10
    if not shipSelectionWindow.visible then
        offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Founding Costs" % _t, 0, foundingResources)
        offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Ship Costs" % _t, planMoney, planResources)
        offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Crew" % _t, crewMoney)
        offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Fee" % _t, planMoney * fee, planResourcesFee)

        offset = offset + 20
        offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Total" % _t, planMoney + planMoney * fee + crewMoney, planResourcesTotal)
        local x, y = planDisplayer.lower.x + 10, planDisplayer.lower.y + offset
        drawText("Time to construct:" % _t .. "\n" .. createReadableTimeString(timeToConstruct), x, y, ColorRGB(1, 1, 1), 13, 0, 0, 2)
    end
end

local advSY_oldUpdatePlan = Shipyard.updatePlan
function Shipyard.updatePlan()
    advSY_oldUpdatePlan()
    if not planSelection then
        return
    end
    local planItem = planSelection.selected
    if planItem and planItem.plan and planItem.type == SavedDesignType.CraftDesign then
        preview = planItem.plan
    end

    -- set to display
    planDisplayer.plan = preview
end

local advSY_oldStartClientJob = Shipyard.startClientJob
function Shipyard.startClientJob(executed, duration, name, buyer)
    advSY_oldStartClientJob(executed, duration)
    local job = runningJobs[#runningJobs]
    job.name = name
    job.shipOwner = buyer
    runningJobs[#runningJobs] = job -- TODO necessary? - Yes
   
end

function Shipyard.onDesignButtonPress()
    shipSelectionWindow.visible = 1
    planSelection:refreshTopLevelFolder()
end

function Shipyard.onDesignSelected()
    local planItem = planSelection.selected
    if not planItem then
        -- displayChatMessage("You have no plan selected."%_t, "Shipyard"%_t, 1) << TODO gives confusing response, when clicking on folder icons
        return
    end
    if planItem.type ~= SavedDesignType.CraftDesign then
        displayChatMessage("You may only select ship blueprints." % _t, "Shipyard" % _t, 1)
        return
    end

    local plan = planItem.plan
    if not plan then
        return
    end
    selectionPlandisplayer.plan = plan
end

function Shipyard.onDesignCancelPressed()
    shipSelectionWindow.visible = 0
    planSelection:unselect()
    Shipyard.updatePlan()
end

function Shipyard.onPlanSelectedPressed()
    shipSelectionWindow.visible = 0
    Shipyard.updatePlan()
end

-- TODO decide if a build-button-onPressed function switcheroo for designs is the way to go?
local advSY_oldOnBuildButtonPress = Shipyard.onBuildButtonPress
function Shipyard.onBuildButtonPress()
    -- advSY_oldOnBuildButtonPress() << TODO invokeServerFunction messes the vanilla on up
    -- check whether a ship with that name already exists
    local name = nameTextBox.text

    if name == "" then
        displayChatMessage("You have to give your ship a name!" % _t, "Shipyard" % _t, 1)
        return
    end

    if Player():ownsShip(name) then
        displayChatMessage("You already have a ship called '${x}'" % _t % {
            x = name
        }, "Shipyard" % _t, 1)
        return
    end

    local singleBlock = singleBlockCheckBox.checked
    local founder = stationFounderCheckBox.checked
    local captain = captainCombo.selectedIndex
    local seed = seedTextBox.text

    local planItem = planSelection.selected
    if planItem and planItem.plan and planItem.type == SavedDesignType.CraftDesign then
        invokeServerFunction("startServerDesignJob", founder, captain, scale, name, planItem.plan)
    else
        invokeServerFunction("startServerJob", singleBlock, founder, captain, styleName, seed, volume, scale, material, name)
    end

end

-- ######################################################################################################### --
-- ######################################        Common        ############################################# --
-- ######################################################################################################### --

-- TODO can this be done without a full overwrite? Shipyard.createShip() is different
local advSY_oldUpdate = Shipyard.update
function Shipyard.update(timeStep)
    for i, job in pairs(runningJobs) do
        job.executed = job.executed + timeStep

        if job.executed >= job.duration then

            if onServer() then
                local owner = Galaxy():findFaction(job.shipOwner)
                local player = Player(job.player)

                local gameversion = GameVersion()
                if (gameversion.major >= 1 and gameversion.minor >= 2) then
                    if owner and player then
                        Shipyard.createShip(owner, player, job.singleBlock, job.founder, job.captain, job.styleName, job.seed, job.volume, job.scale, job.material, job.shipName, job.uuid)
                    end
                else
                    if owner then
                        Shipyard.createShip(owner, player, job.singleBlock, job.founder, job.captain, job.styleName, job.seed, job.volume, job.scale, job.material, job.shipName, job.uuid)
                    end
                end
            end
            runningJobs[i] = nil
        end
    end
end

-- ######################################################################################################### --
-- ######################################     Server Sided     ############################################# --
-- ######################################################################################################### --

function Shipyard.startServerDesignJob(founder, captain, scale, name, planToBuild)
    if not name then
        print("Not a valid shipname", name)
        return
    end
    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources, AlliancePrivilege.FoundShips)
    if not buyer then
        return
    end

    local stationFaction = Faction()
    local station = Entity()

    -- shipyard may only have x jobs
    if tablelength(runningJobs) >= config.maxParallelShips then
        player:sendChatMessage(station.title, 1, "The shipyard is already at maximum capacity." % _t)
        return
    end

    local settings = GameSettings()
    local limit
    if buyer.isPlayer or buyer.isAlliance then
        limit = buyer.maxNumShips
    end

    if limit and limit >= 0 and buyer.numShips >= limit then
        player:sendChatMessage("", 1, "Maximum ship limit for this faction (%s) of this server reached!" % _t, limit)
        return
    end

    -- check if the player can afford the ship
    -- first create the plan
    local plan = planToBuild

    plan:scale(vec3(scale, scale, scale))

    local requiredMoney, fee = Shipyard.getRequiredMoney(plan, buyer)
    local requiredResources = Shipyard.getRequiredResources(plan, buyer)

    if captain > 0 then
        if captain == 2 then
            if stationFaction:getRelations(buyer.index) < 30000 then
                local name = "Good" % _t
                player:sendChatMessage(station.title, ChatMessageType.Error, "You need relations of at least '%s' to this faction to include a captain with the ship." % _t, name)
                return
            end
        end

        requiredMoney = requiredMoney + Shipyard.getCrewMoney(plan, captain == 2)
    end

    -- check if the player has enough money & resources
    local canPay, msg, args = buyer:canPay(requiredMoney, unpack(requiredResources))
    if not canPay then -- if there was an error, print it
        player:sendChatMessage(station, 1, msg, unpack(args))
        return
    end

    receiveTransactionTax(station, fee)

    -- let the player pay
    buyer:pay(requiredMoney, unpack(requiredResources))

    -- relations of the player to the faction owning the shipyard get better
    local relationsChange = GetRelationChangeFromMoney(requiredMoney)
    for _, v in pairs(requiredResources) do
        relationsChange = relationsChange + v / 4
    end

    changeRelations(buyer, stationFaction, relationsChange, RelationChangeType.ServiceUsage)

    -- start the job
    local requiredTime = math.floor(20.0 + plan.durability / 100.0)

    if captain > 0 then
        requiredTime = requiredTime + 300
    end

    if buyer.infiniteResources then
        requiredTime = 1.0
    end

    -- create job
    local job = {}
    job.executed = 0
    job.duration = requiredTime
    job.shipOwner = buyer.index
    job.player = callingPlayer
    job.scale = scale
    job.shipName = name
    job.founder = founder
    job.captain = captain
    -- job.plan = seriLib.serializeBlockPlan(planToBuild)  << If only someone had made a full serialzation lib. Hint @1694550170

    local position = Entity().orientation
    local sphere = Entity():getBoundingSphere()
    position.translation = sphere.center + random():getDirection() * (sphere.radius + plan.radius + 50)
    local ship = Sector():createShip(Faction(Entity().factionIndex), job.shipName, plan, position)
    ship.invincible = true
    local crew = ship.minCrew
    crew:add(1, CrewMan(CrewProfessionType.Captain, true, 1))
    ship.crew = crew
    ship.factionIndex = -1

    ship:addScriptOnce("data/scripts/entity/timedFactionTransferer.lua")
    ship:invokeFunction("data/scripts/entity/timedFactionTransferer.lua", "setVars", requiredTime, requiredTime, name, buyer.index, captain)
    job.uuid = ship.index.string

    table.insert(runningJobs, job)

    player:sendChatMessage(station.title, 0, "Thank you for your purchase. Your ship will be ready in about %s." % _t, createReadableTimeString(requiredTime))

    -- tell all clients in the sector that production begins
    broadcastInvokeClientFunction("startClientJob", 0, requiredTime, name, buyer.index)
end
callable(Shipyard, "startServerDesignJob")

local advSY_oldCreateShip = Shipyard.createShip
function Shipyard.createShip(buyer, player, singleBlock, founder, captain, styleName, seed, volume, scale, material, name, uuid)
    if not uuid then
        local gameversion = GameVersion()
        if (gameversion.major >= 1 and gameversion.minor >= 2) then
            advSY_oldCreateShip(buyer, player, singleBlock, founder, captain, styleName, seed, volume, scale, material, name)
        else
            advSY_oldCreateShip(buyer, singleBlock, founder, captain, styleName, seed, volume, scale, material, name)
        end
        return
    end

    local settings = GameSettings()
    local limit
    if buyer.isPlayer then
        limit = settings.maximumPlayerShips
    elseif buyer.isAlliance then
        if settings.maximumAllianceShipsPerMember < 0 then
            limit = settings.MaximumAllianceShips;
        elseif settings.maximumAllianceShips < 0 then
            limit = settings.maximumAllianceShipsPerMember * #{buyer:getMembers()};
        else
            limit = math.min(settings.maximumAllianceShips, settings.maximumAllianceShipsPerMember * #{buyer:getMembers()});
        end
    end

    local stationFaction = Faction()

    local ship = Entity(Uuid(uuid))
    if not ship then
        print("skipping invalid ship:", name, "buyer:", buyer.name, "Sector:", Sector():getCoordinates(), "uuid:", uuid)
        return
    end

    if limit and limit >= 0 and buyer.numShips >= limit then
        local gameversion = GameVersion()
        if (gameversion.major >= 1 and gameversion.minor >= 2) then
            player:sendChatMessage("", 1, "Maximum ship limit for this faction (%s) of this server reached!" % _t, limit)
        end

        -- ship limit reached, so purchase will be reverted

        -- get the money required for the plan
        local requiredMoney, fee = Shipyard.getRequiredMoney(plan, buyer)
        local requiredResources = Shipyard.getRequiredResources(plan, buyer)

        if captain > 0 then
            requiredMoney = requiredMoney + Shipyard.getCrewMoney(plan, captain == 2)
        end

        -- revert the direct payment of the player, but not the fee payment or relations change
        buyer:receive("Received a refund of %1% Credits and resources from the shipyard." % _T, requiredMoney - fee, unpack(requiredResources))

        Sector():deleteEntity(ship)
        return
    end

    -- add base scripts
    AddDefaultShipScripts(ship)
    SetBoardingDefenseLevel(ship)

    if founder then
        ship:addScript("data/scripts/entity/stationfounder.lua", stationFaction)
    end

    if captain > 0 then
        -- add base crew
        local crew = ship.minCrew

        if captain == 2 then
            crew:add(1, CrewMan(CrewProfessionType.Captain, true, 1))
        end

        ship.crew = crew
    end
end
