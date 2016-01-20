SmashAndGrabQuickLoot = {}
local markedItems = {}
local configName = ""
local fetchSpeedBonus = 0.1 
local lootXPMultiplier = 0.1

local function getName(_item, _player) 
    if instanceof(_item, "InventoryItem") then
        return _player .. _item:getName()
    elseif type(_item) == "table" then
        return _player .. _item.items[2]:getName()
    else
        return _player .. "Failure"
    end
end

-- This will create a new context menu entry to grab or ungrab items
function SmashAndGrabQuickLoot.createMenu(_player, _context, _items)
    if not _items then return end
    
    for _, entry in ipairs(_items) do
        if not markedItems[getName(entry, _player)] then
            _context:addOption("Mark As Junk", _items, SmashAndGrabQuickLoot.onMarkItem, _player)
            return
        end
    end

    _context:addOption("Unmark As Junk", _items, SmashAndGrabQuickLoot.onUnmarkItem, _player)
end

function SmashAndGrabQuickLoot.onMarkItem(_items, _player)
    for _, item in ipairs(_items) do
        markedItems[getName(item, _player)] = true
    end
end

function SmashAndGrabQuickLoot.onUnmarkItem(_items, _player)
    for _, item in ipairs(_items) do
        markedItems[getName(item, _player)] = nil
    end
end

function SmashAndGrabQuickLoot.addXPForTransferring(self) 
    local w = self.item:getActualWeight()
    if w > 3 then w = 3 end
    self.character:getXp():AddXP(Perks.Nimble, w * lootXPMultiplier)
end

function SmashAndGrabQuickLoot.addQuickLootButton(self)
    if self.onCharacter then return end

    function lootUseful()
       local speed = 1.0 - (fetchSpeedBonus * getSpecificPlayer(self.player):getPerkLevel(Perks.Nimble))
       local it = self.inventoryPane.inventory:getItems()

       if speed < fetchSpeedBonus then
           speed = fetchSpeedBonus
       end

       for i = 0, it:size()-1 do
           local item = it:get(i)
           if not markedItems[getName(item, self.player)] then 
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

function SmashAndGrabQuickLoot.getSaveName(text)
    configName = "saves/QuickLoot_"..text
end

-- TODO: This may not work for multiplayer, I haven't had the chance to test it :( PLEASE RITO PROVIDE ME FRIENDS
function SmashAndGrabQuickLoot.getConfigLoadedName(self)
    local sel = self.listbox.items[self.listbox.selected]
    if not sel then return end
    configName = "saves/QuickLoot_"..sel.item.saveName
end

function SmashAndGrabQuickLoot.loadConfig()
    local reader = getModFileReader("SmashAndGrab", configName, true)
    local text = reader and reader:readLine() or '{}'
    markedItems = JSON:decode(text)
    if reader then reader:close() end
end

function SmashAndGrabQuickLoot.saveConfig()
    if not markedItems then return end
    local text = JSON:encode(markedItems)
    local writer = getModFileWriter("SmashAndGrab", configName, true, false)
    if not writer then 
        print ("SmashAndGrab: Error: Failed to save file " .. configName)
        return 
    end
    writer:write(text)
    writer:close()
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

Events.OnFillInventoryObjectContextMenu.Add(SmashAndGrabQuickLoot.createMenu)
Events.OnSave.Add(SmashAndGrabQuickLoot.saveConfig)
Events.OnGameStart.Add(SmashAndGrabQuickLoot.loadConfig)
Events.precreateWorld.Add(SmashAndGrabQuickLoot.getSaveName)
Events.postLoadGameScreen_clickPlay.Add(SmashAndGrabQuickLoot.getConfigLoadedName)
Events.postISInventoryTransferAction_perform.Add(SmashAndGrabQuickLoot.addXPForTransferring)
Events.preISInventoryPage_createChildren.Add(SmashAndGrabQuickLoot.addQuickLootButton)
Events.preMainScreen_continueLatestSave.Add(SmashAndGrabQuickLoot.getContinuedSaveName)
