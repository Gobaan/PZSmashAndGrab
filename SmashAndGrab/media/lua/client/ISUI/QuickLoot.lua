SmashAndGrabQuickLoot = SmashAndGrabQuickLoot or {}
local hotkey = 34 -- 'g'

function SmashAndGrabQuickLoot.lootAll (_keyPressed)
    if (_keyPressed ~= hotkey) then return end
    local lootWindow = ISLayoutManager.windows["loot".."0"]
    if not lootWindow or not lootWindow.target.javaObject:isVisible() then
        return
    end
    lootWindow.funcs.lootAll()
end

local function makeTrash() 
    return ItemContainer.new("junk", nil, nil, 10, 10) 
end 

local function makeEmptyDict()
    return {}
end

local configName = ""
local fetchSpeedBonus = 0.1 
local lootXPMultiplier = 0.1
local junkItems = SmashAndGrabUtils.defaultdict(makeEmptyDict)
SmashAndGrabQuickLoot.trash = SmashAndGrabUtils.defaultdict(makeTrash)

local function getItem(_item)
    if instanceof(_item, "InventoryItem") then
        return _item
    elseif type(_item) == "table" then
        return _item.items[2]
    end
end

local function getName(_item)
    if type(_item) == "table" then
        _item = _item.items[2]
    end
    return _item:getModule() .. "." .. _item:getType()
end

-- This will create a new context menu entry to grab or ungrab items
function SmashAndGrabQuickLoot.createMenu(_player, _context, _items)
    if not _items then return end
    for _, entry in ipairs(_items) do
        if not junkItems[_player][getName(entry)] then
            _context:addOption("Mark As Junk", _items, SmashAndGrabQuickLoot.onMarkItem, _player)
            return
        end
    end

    _context:addOption("Unmark As Junk", _items, SmashAndGrabQuickLoot.onUnmarkItem, _player)
end

function SmashAndGrabQuickLoot.onMarkItem(_items, _player)
    local marked = false
    if not _items then
    	return false
    end

    for _, item in ipairs(_items) do
     	name = getName(item)
		print (name)
    	if not junkItems[_player][name] then
    	    local item = getItem(item)
    	    local clone = instanceItem(name)
            clone:setModule(item:getModule())
    	    clone:setType(item:getType())
            SmashAndGrabQuickLoot.trash[_player]:AddItem(clone)
            junkItems[_player][name] = clone:getType()
    		marked = true
    	end
    end
    return marked
end

function SmashAndGrabQuickLoot.onUnmarkItem(_items, _player)
    local unmarked = false
    for _, item in ipairs(_items) do
        junkItems[_player][getName(item)] = nil
        item = getItem(item)
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
           if not junkItems[self.player][getName(item)] then 
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
    local junk = JSON:decode(text)
    if reader then reader:close() end

    for player, contents in pairs(junk) do
        player = tonumber(player)
        for name, value in pairs(contents) do
            local clone = instanceItem(name)
            clone:setType(value)
            SmashAndGrabQuickLoot.trash[player]:AddItem(clone)
            junkItems[player][name] = clone:getType()
        end
    end
end

function SmashAndGrabQuickLoot.saveConfig()
    if not junkItems then return end
    local text = JSON:encode(junkItems)
    local writer = getModFileWriter("SmashAndGrab", configName, true, false)
    if not writer then 
        return 
    end
    writer:write(text)
    writer:close()
end

function SmashAndGrabQuickLoot.colorMarkedItems(self, doDragged)
    local y = 0
    for k, item in ipairs(self.itemslist) do
    	local isJunk = junkItems[self.player][getName(item)] 
    	local count = self.collapsed[item.name] and 1 or #item.items

        for n = 1, count do
            if isJunk then
                self:drawRect(1, (y * self.itemHgt) + 16, self:getWidth(), self.itemHgt, 0.10, 0.5, 0.25, 0.25)
            end
            y = y + 1
    	end
   end
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
SmashAndGrabCustomEvent.addListener("ISInventoryPane:renderdetails")

Events.OnFillInventoryObjectContextMenu.Add(SmashAndGrabQuickLoot.createMenu)
Events.OnSave.Add(SmashAndGrabQuickLoot.saveConfig)
Events.OnGameStart.Add(SmashAndGrabQuickLoot.loadConfig)
Events.precreateWorld.Add(SmashAndGrabQuickLoot.getSaveName)
Events.postLoadGameScreen_clickPlay.Add(SmashAndGrabQuickLoot.getConfigLoadedName)
Events.postISInventoryTransferAction_perform.Add(SmashAndGrabQuickLoot.addXPForTransferring)
Events.preISInventoryPage_createChildren.Add(SmashAndGrabQuickLoot.addQuickLootButton)
Events.preMainScreen_continueLatestSave.Add(SmashAndGrabQuickLoot.getContinuedSaveName)
Events.postISInventoryPane_renderdetails.Add(SmashAndGrabQuickLoot.colorMarkedItems)
Events.OnKeyPressed.Add(SmashAndGrabQuickLoot.lootAll)


function SmashAndGrabQuickLoot.doButtons(self, y)
    if self.inventory == SmashAndGrabQuickLoot.trash[self.player] then
		self.contextButton1:setVisible(true)
		self.contextButton1:setTitle("Unmark")
        self.contextButton1.mode = "Unmark Loot"
    	self.contextButton2:setVisible(false)
	else 
		if self.contextButton2.mode ~= "Unmark Loot" and self.contextButton2.mode ~= "Mark Loot" then
			self.contextButton3:setVisible(true)
		  	self.contextButton3:setTitle(self.contextButton2:getTitle())
          	self.contextButton3.mode = self.contextButton2.mode
		end
		
		self.contextButton2:setVisible(true)
		if junkItems[self.player][getName(self.items[y])] then
		  self.contextButton2:setTitle("Unmark")
          self.contextButton2.mode = "Unmark Loot"
		else
		  self.contextButton2:setTitle("Mark")
          self.contextButton2.mode = "Mark Loot"
		end
    end
end
SmashAndGrabCustomEvent.addListener("ISInventoryPane:doButtons")
SmashAndGrabCustomEvent.addListener("ISInventoryPane:onContext")

function SmashAndGrabQuickLoot.markContext(self, button)
	local markables = {self.items[self.buttonOption]}
    if button.mode == "Mark Loot" then
		SmashAndGrabQuickLoot.onMarkItem(markables, self.player)
    end

    if button.mode == "Unmark Loot" then
		SmashAndGrabQuickLoot.onUnmarkItem(markables, self.player)
    end
end

Events.postISInventoryPane_onContext.Add(SmashAndGrabQuickLoot.markContext)
Events.postISInventoryPane_doButtons.Add(SmashAndGrabQuickLoot.doButtons)
