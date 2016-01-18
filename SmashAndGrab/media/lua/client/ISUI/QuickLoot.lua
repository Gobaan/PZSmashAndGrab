SmashAndGrabQuickLoot = {};
local markedItems = {};
local configName = "";

local function getName(_item, _player) 
    if instanceof(_item, "InventoryItem") then
        return _player .. _item:getName();
    elseif type(_item) == "table" then
        return _player .. _item.items[2]:getName();
    else
        return _player .. "Failure"
    end
end

-- This will create a new context menu entry to grab or ungrab items
function SmashAndGrabQuickLoot.createMenu(_player, _context, _items)
    if not _items then return; end
    
    for _, entry in ipairs(_items) do
        if not markedItems[getName(entry, _player)] then
            _context:addOption("Mark As Junk", _items, SmashAndGrabQuickLoot.onMarkItem, _player);
            return;
        end
    end

    _context:addOption("Unmark As Junk", _items, SmashAndGrabQuickLoot.onUnmarkItem, _player);
end

function SmashAndGrabQuickLoot.onMarkItem(_items, _player)
    for _, item in ipairs(_items) do
        markedItems[getName(item, _player)] = true;
    end
end

function SmashAndGrabQuickLoot.onUnmarkItem(_items, _player)
    for _, item in ipairs(_items) do
        markedItems[getName(item, _player)] = nil;
    end
end

function SmashAndGrabQuickLoot.addXPForTransferring(self) 
    local w = self.item:getActualWeight();
    if w > 3 then w = 3; end;
    self.character:getXp():AddXP(Perks.Nimble, w * 0.1);
end

function SmashAndGrabQuickLoot.addQuickLootButton(self)
    if self.onCharacter then return; end

    function lootUseful()
       local speed = 1.0 - (0.1 * getSpecificPlayer(self.player):getPerkLevel(Perks.Nimble))
       local it = self.inventoryPane.inventory:getItems();

       if speed < 0.1 then
           speed = 0.1
       end

       for i = 0, it:size()-1 do
           local item = it:get(i);
           if not markedItems[getName(item, self.player)] then 
               local lootAction = ISInventoryTransferAction:new(
                    getSpecificPlayer(self.player), 
                    item, 
                    item:getContainer(), 
                    getPlayerInventory(self.player).inventory);
                lootAction.maxTime = lootAction.maxTime * speed
                ISTimedActionQueue.add(lootAction);

           end
       end

       self.selected = {};
       getPlayerLoot(self.player).inventoryPane.selected = {};
       getPlayerInventory(self.player).inventoryPane.selected = {}; 
    end

    self.lootMarked = ISButton:new(85, -1, 50, 14, "Quick Loot", self, lootUseful);
    self.lootMarked:initialise();
    self.lootMarked.borderColor.a = 0.0;
    self.lootMarked.backgroundColor.a = 0.0;
    self.lootMarked.backgroundColorMouseOver.a = 0.7;
    self:addChild(self.lootMarked);
    self.lootMarked:setVisible(true);
end


function SmashAndGrabQuickLoot.getSaveName(text)
    configName = "saves/ISMarkLoot_"..text
end

-- TODO: This may not work for multiplayer, I haven't had the chance to test it :( PLEASE RITO PROVIDE ME FRIENDS
function SmashAndGrabQuickLoot.getConfigLoadedName(self)
    local sel = self.listbox.items[self.listbox.selected];
    if not sel then return; end
    configName = "saves/ISMarkLoot_"..sel.item.configName
end

function SmashAndGrabQuickLoot.loadConfig()
    local reader = getModFileReader("SmashAndGrab", configName, true)
    local text = reader and reader:readLine() or '{}'
    markedItems = JSON:decode(text)
    if reader then reader:close(); end
end

function SmashAndGrabQuickLoot.saveConfig()
    if not markedItems then return; end
    local text = JSON:encode(markedItems)
    local writer = getModFileWriter("SmashAndGrab", configName, true, false)
    if not writer then 
        print ("SmashAndGrab: Error: Failed to save file " .. configName)
        return; 
    end;
    writer:write(text)
    writer:close()
end

function SmashAndGrabQuickLoot.getContinuedSaveName(gameMode, name)
    configName = "saves/ISMarkLoot_"..name
end

-- Call our function when the event is fired
SmashAndGrabCustomEvent.addListener("createWorld")
SmashAndGrabCustomEvent.addListener("LoadGameScreen:clickPlay")
SmashAndGrabCustomEvent.addListener("ISInventoryPage.createChildren")
SmashAndGrabCustomEvent.addListener("ISInventoryTransferAction.perform")
SmashAndGrabCustomEvent.addListener("MainScreen.continueLatestSave")

Events.OnFillInventoryObjectContextMenu.Add(SmashAndGrabQuickLoot.createMenu);
Events.OnSave.Add(SmashAndGrabQuickLoot.saveConfig)
Events.OnGameStart.Add(SmashAndGrabQuickLoot.loadConfig)
Events.precreateWorld.Add(SmashAndGrabQuickLoot.getSaveName)
Events.postLoadGameScreen_clickPlay.Add(SmashAndGrabQuickLoot.getConfigLoadedName)
Events.postISInventoryTransferAction_perform.Add(SmashAndGrabQuickLoot.addXPForTransferring)
Events.postISInventoryPage_createChildren.Add(SmashAndGrabQuickLoot.addQuickLootButton)
Events.preMainScreen_continueLatestSave.Add(SmashAndGrabQuickLoot.getContinuedSaveName)
