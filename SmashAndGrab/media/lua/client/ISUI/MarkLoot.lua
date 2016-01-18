SmashAndGrabMarkItems = {};
local markedItems = {};
local saveName = "";

-- This will create a new context menu entry to grab or ungrab items
function SmashAndGrabMarkItems.createMenu(_player, _context, _items)
    if not _items then return; end
    
    -- Iterate through all clicked items
    for _, entry in ipairs(_items) do
        if not markedItems[SmashAndGrabMarkItems.getName(entry, _player)] then
            _context:addOption("Mark As Junk", _items, SmashAndGrabMarkItems.onMarkItem, _player);
            return;
        end
    end

    _context:addOption("Unmark As Junk", _items, SmashAndGrabMarkItems.onUnmarkItem, _player);
end

function SmashAndGrabMarkItems.onMarkItem(_items, _player)
    for _, item in ipairs(_items) do
        markedItems[SmashAndGrabMarkItems.getName(item, _player)] = true;
    end
end

function SmashAndGrabMarkItems.onUnmarkItem(_items, _player)
    for _, item in ipairs(_items) do
        markedItems[SmashAndGrabMarkItems.getName(item, _player)] = nil;
    end
end

function SmashAndGrabMarkItems.getName(_item, _player) 
    if instanceof(_item, "InventoryItem") then
        return _player .. _item:getName();
    elseif type(_item) == "table" then
        return _player .. _item.items[2]:getName();
    else
        return _player .. "Failure"
    end
end

-- Add XP for transfering items
function SmashAndGrabMarkItems.postInventoryTransfer(self) 
    local w = self.item:getActualWeight();
    if w > 3 then w = 3; end;
    self.character:getXp():AddXP(Perks.Nimble, w * 0.1);
end

-- Add Quick Loot Button to inventory tabs
function SmashAndGrabMarkItems.postCreateChildren(self)
    if self.onCharacter then return; end

    function lootUseful()
       local speed = 1.0 - (0.1 * getSpecificPlayer(self.player):getPerkLevel(Perks.Nimble))
       local it = self.inventoryPane.inventory:getItems();

       if speed < 0.1 then
           speed = 0.1
       end

       for i = 0, it:size()-1 do
           local item = it:get(i);
           if not markedItems[SmashAndGrabMarkItems.getName(item, self.player)] then 
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


-- Find out save files name (Core.getGameWorld is broken and loads the previous saves value)
function SmashAndGrabMarkItems.preCreateWorld(text)
    saveName = "saves/ISMarkLoot_"..text
end

-- TODO: This may not work for multiplayer, I haven't had the chance to test it :( PLEASE RITO PROVIDE ME FRIENDS
function SmashAndGrabMarkItems.postClickPlay(self)
    local sel = self.listbox.items[self.listbox.selected];
    if not sel then return; end
    saveName = "saves/ISMarkLoot_"..sel.item.saveName
end

-- Load the list of items that are being junked
function SmashAndGrabMarkItems.onLoad()
    local reader = getModFileReader("SmashAndGrab", saveName, true)
    local text = reader and reader:readLine() or '{}'
    markedItems = JSON:decode(text)
    if reader then reader:close(); end
end

-- Unload list of items being junked
function SmashAndGrabMarkItems.onSave()
    if not markedItems then return; end
    local text = JSON:encode(markedItems)
    local writer = getModFileWriter("SmashAndGrab", saveName, true, false)
    if not writer then 
        print ("SmashAndGrab: Error: Failed to save file " .. saveName)
        return; 
    end;
    writer:write(text)
    writer:close()
end

function SmashAndGrabMarkItems.preContinue(gameMode, name)
    saveName = "saves/ISMarkLoot_"..name
end

-- Call our function when the event is fired
SmashAndGrabCustomEvent.addListener("createWorld")
SmashAndGrabCustomEvent.addListener("LoadGameScreen:clickPlay")
SmashAndGrabCustomEvent.addListener("ISInventoryPage.createChildren")
SmashAndGrabCustomEvent.addListener("ISInventoryTransferAction.perform")
SmashAndGrabCustomEvent.addListener("MainScreen.continueLatestSave")

Events.OnFillInventoryObjectContextMenu.Add(SmashAndGrabMarkItems.createMenu);
Events.OnSave.Add(SmashAndGrabMarkItems.onSave)
Events.OnGameStart.Add(SmashAndGrabMarkItems.onLoad)
Events.precreateWorld.Add(SmashAndGrabMarkItems.preCreateWorld)
Events.postLoadGameScreen_clickPlay.Add(SmashAndGrabMarkItems.postClickPlay)
Events.postISInventoryTransferAction_perform.Add(SmashAndGrabMarkItems.postInventoryTransfer)
Events.postISInventoryPage_createChildren.Add(SmashAndGrabMarkItems.postCreateChildren)
Events.preMainScreen_continueLatestSave.Add(SmashAndGrabMarkItems.preContinue)
