-- This file deals with morphing the underlying trash and junk items model to maintain the marked item states
SmashAndGrabQuickLoot = SmashAndGrabQuickLoot or {}
local configName = ""
local fetchSpeedBonus = 0.1 
local lootXPMultiplier = 0.1

local function makeTrash() 
    return ItemContainer.new("junk", nil, nil, 10, 10) 
end 

local function makeEmptyDict()
    return {}
end

SmashAndGrabQuickLoot.junkItems = SmashAndGrabUtils.defaultdict(makeEmptyDict)
SmashAndGrabQuickLoot.trash = SmashAndGrabUtils.defaultdict(makeTrash)

function SmashAndGrabQuickLoot.onMarkItem(_items, _player)
    local marked = false
    if not _items then
    	return false
    end

    for _, item in ipairs(_items) do
     	name = SmashAndGrabUtils.getName(item)
    	if not SmashAndGrabQuickLoot.junkItems[_player][name] then
    	    local item = SmashAndGrabUtils.getItem(item)
    	    local clone = instanceItem(name)
            clone:setModule(item:getModule())
    	    clone:setType(item:getType())
            SmashAndGrabQuickLoot.trash[_player]:AddItem(clone)
            SmashAndGrabQuickLoot.junkItems[_player][name] = clone:getType()
    		marked = true
    	end
    end
    return marked
end

function SmashAndGrabQuickLoot.onUnmarkItem(_items, _player)
    local unmarked = false
    for _, item in ipairs(_items) do
        SmashAndGrabQuickLoot.junkItems[_player][SmashAndGrabUtils.getName(item)] = nil
        item = SmashAndGrabUtils.getItem(item)
    	SmashAndGrabQuickLoot.trash[_player]:RemoveAll(item:getType())
    	unmarked = true
    end
    return true
end

function SmashAndGrabQuickLoot.addXPForTransferring(self) 
    local w = self.item:getActualWeight()
    if w > 3 then w = 3 end
    self.character:getXp():AddXP(Perks.Nimble, w * lootXPMultiplier)
end

function SmashAndGrabQuickLoot.addQuickLootLogic(self)
    if self.onCharacter then return end

    function lootUseful()
       local speed = 1.0 - (fetchSpeedBonus * getSpecificPlayer(self.player):getPerkLevel(Perks.Nimble))
       local it = self.inventoryPane.inventory:getItems()

       if speed < fetchSpeedBonus then
           speed = fetchSpeedBonus
       end

       for i = 0, it:size()-1 do
           local item = it:get(i)
           if not SmashAndGrabQuickLoot.junkItems[self.player][SmashAndGrabUtils.getName(item)] then 
               local lootAction = ISInventoryTransferAction:new(
                    getSpecificPlayer(self.player), 
                    item, 
                    item:getContainer(), 
                    getPlayerInventory(self.player).inventory)
                lootAction.maxTime = lootAction.maxTime * speed
                ISTimedActionQueue.add(lootAction)
           end
       end

       self.selected = {}
       getPlayerLoot(self.player).inventoryPane.selected = {}
       getPlayerInventory(self.player).inventoryPane.selected = {} 
    end

    ISInventoryPage.lootAll = lootUseful
end


function SmashAndGrabQuickLoot.loadConfig()
    local reader = getModFileReader("SmashAndGrab", configName, true)
    local text = reader and reader:readLine() or '{}'
    local junk = JSON:decode(text)
    if reader then reader:close() end

    for player, contents in pairs(junk) do
        player = tonumber(player)
        for name, value in pairs(contents) do
            local clone = instanceItem(name)
            clone:setType(value)
            SmashAndGrabQuickLoot.trash[player]:AddItem(clone)
            SmashAndGrabQuickLoot.junkItems[player][name] = clone:getType()
        end
    end
end

function SmashAndGrabQuickLoot.saveConfig()
    if not SmashAndGrabQuickLoot.junkItems then return end
    local text = JSON:encode(SmashAndGrabQuickLoot.junkItems)
    local writer = getModFileWriter("SmashAndGrab", configName, true, false)
    if not writer then 
        return 
    end
    writer:write(text)
    writer:close()
end

function SmashAndGrabQuickLoot.getSaveName(text)
    configName = "saves/QuickLoot_"..text
end

-- TODO: This may not work for multiplayer, I haven't had the chance to test it :( PLEASE RITO PROVIDE ME FRIENDS
function SmashAndGrabQuickLoot.getConfigLoadedName(self)
    local sel = self.listbox.items[self.listbox.selected]
    if not sel then return end
    configName = "saves/QuickLoot_"..sel.item.saveName
end

function SmashAndGrabQuickLoot.getContinuedSaveName(gameMode, name)
    configName = "saves/QuickLoot_"..name
end

-- Call our function when the event is fired
SmashAndGrabCustomEvent.addListener("createWorld")
SmashAndGrabCustomEvent.addListener("LoadGameScreen:clickPlay")
SmashAndGrabCustomEvent.addListener("ISInventoryPage.createChildren")
SmashAndGrabCustomEvent.addListener("ISInventoryTransferAction.perform")
SmashAndGrabCustomEvent.addListener("MainScreen.continueLatestSave")

Events.OnSave.Add(SmashAndGrabQuickLoot.saveConfig)
Events.OnGameStart.Add(SmashAndGrabQuickLoot.loadConfig)
Events.precreateWorld.Add(SmashAndGrabQuickLoot.getSaveName)
Events.postLoadGameScreen_clickPlay.Add(SmashAndGrabQuickLoot.getConfigLoadedName)
Events.postISInventoryTransferAction_perform.Add(SmashAndGrabQuickLoot.addXPForTransferring)
Events.preISInventoryPage_createChildren.Add(SmashAndGrabQuickLoot.addQuickLootLogic)
Events.preMainScreen_continueLatestSave.Add(SmashAndGrabQuickLoot.getContinuedSaveName)
