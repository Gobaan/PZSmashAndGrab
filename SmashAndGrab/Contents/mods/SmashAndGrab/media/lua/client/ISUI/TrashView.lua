-- This file deals with rendering the trash and junk items state and providing an interface for users to
-- update and view the state
SmashAndGrabQuickLoot = SmashAndGrabQuickLoot or {}

local grabHotkey = 34 -- 'g'
local markTrashHotkey = 20 -- 't'
local trashButton = nil

local function markAll(self)
    local items = self.inventory:getItems()
    local itemTable = {}
	for i=0, items:size() - 1 do
        itemTable[i + 1] = items:get(i)
	end
	SmashAndGrabQuickLoot.onMarkItem(itemTable, self.player)
end

local function onDragToTrash(self, button)
    if ISMouseDrag.dragging ~= nil then
        SmashAndGrabQuickLoot.onMarkItem(ISMouseDrag.dragging, self.player)
    else
        for i,v in ipairs(self.backpacks) do
            v.backgroundColor.a = 0.0
        end
        trashButton.backgroundColor = {r=0.7, g=0.7, b=0.7, a=1.0};
        self.inventoryPane.lastinventory = button.inventory
        self.inventoryPane.inventory = button.inventory
        self.inventoryPane.selected = {}

        self.title = button.name
        self.capacity = button.capacity
    end

    self.inventoryPane:refreshContainer();
end

function SmashAndGrabQuickLoot.colorMarkedItems(self, doDragged)
    local y = 0
    for k, item in ipairs(self.itemslist) do
        local isJunk = SmashAndGrabQuickLoot.junkItems[self.player][SmashAndGrabUtils.getName(item)] 
        local count = self.collapsed[item.name] and 1 or #item.items

        for n = 1, count do
            if isJunk then
                self:drawRect(1, (y * self.itemHgt) + 16, self:getWidth(), self.itemHgt, 0.10, 0.5, 0.25, 0.25)
            end
            y = y + 1
        end
   end
end

SmashAndGrabQuickLoot.oldMouseUp = ISInventoryPane.onMouseUp
function ISInventoryPane:onMouseUp(x, y)
    if ISMouseDrag.dragging ~= nil and ISMouseDrag.draggingFocus ~= nil then
        if ISMouseDrag.draggingFocus ~= self and self.inventory == SmashAndGrabQuickLoot.trash[self.player] then
            SmashAndGrabQuickLoot.onMarkItem(ISMouseDrag.dragging, self.player) 
            return
        elseif self.inventory ~= SmashAndGrabQuickLoot.trash[self.player] and ISMouseDrag.draggingFocus.inventory == SmashAndGrabQuickLoot.trash[self.player] then
            SmashAndGrabQuickLoot.onUnmarkItem(ISMouseDrag.dragging, self.player) 
            return
        end
    end

    SmashAndGrabQuickLoot.oldMouseUp(self, x, y)
end

SmashAndGrabQuickLoot.oldSelectContainer = ISInventoryPage.selectContainer
function ISInventoryPage:selectContainer(button)
    if ISMouseDrag.dragging ~= nil and self.inventoryPane.inventory == SmashAndGrabQuickLoot.trash[self.player] then
        SmashAndGrabQuickLoot.onUnmarkItem(ISMouseDrag.dragging, self.player) 
    else
        trashButton.backgroundColor.a = 0.0
        SmashAndGrabQuickLoot.oldSelectContainer(self, button)
    end
end

function SmashAndGrabQuickLoot.addTrashBin(self)
    if not self.onCharacter then
        return
    end

    -- TODO: this will not be compatible with other mods that use backpack placement to add buttons 
    -- since the number of backpacks isn't incremented. in the future maybe look at the inventory page and try to calculate where to place things
    -- Really PZ should decouple backpack placement logic from functionality, but this quick hack allows us to create a backpack that does not affect crafting
    if trashButton then
        self:removeChild(trashButton)
        trashButton.backgroundColor.a = 0.0
        trashButton:setY(#self.backpacks * 32 + 15)
    else 
        trashButton = ISButton:new(self.width-32, #self.backpacks * 32 + 15, 32, 32, "", self, onDragToTrash, ISInventoryPage.onBackpackMouseDown, true);
        trashButton:setImage(self.conGarbage);
        trashButton:forceImageSize(30, 30)
        trashButton.anchorBottom = false
        trashButton:setOnMouseOverFunction(ISInventoryPage.onMouseOverButton)
        trashButton:setOnMouseOutFunction(ISInventoryPage.onMouseOutButton)
        trashButton.anchorRight = true
        trashButton.anchorTop = false
        trashButton.anchorLeft = false
        trashButton:initialise()
        trashButton.borderColor.a = 0.0
        trashButton.backgroundColor.a = 0.0
        trashButton.backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=1.0}
        trashButton.inventory = SmashAndGrabQuickLoot.trash[self.player]
        trashButton.capacity = 0
        trashButton.name = "Trash"
    end

    self:addChild(trashButton)
    self:updateScrollbars()
    self.inventory:setDrawDirty(false)
end

function SmashAndGrabQuickLoot.doButtons(self, y)
    local ypos = ((y-1)*self.itemHgt) + self.headerHgt
    ypos = ypos + self:getYScroll()

    if self.inventory == SmashAndGrabQuickLoot.trash[self.player] then
        self.contextButton1:setVisible(true)
        self.contextButton1:setTitle("Unmark")
        self.contextButton1:setWidthToTitle()
        self.contextButton1:setX(self.column3)
        self.contextButton1:setY(ypos)
        self.contextButton1.mode = "Unmark Loot"
        self.contextButton2:setVisible(false)
        self.contextButton3:setVisible(false)
        return
    end

    self.contextButton2:setX(self.contextButton1:getRight() + 1)
    self.contextButton2:setY(ypos)

    local foundSecondButton = self.contextButton2.mode ~= "Unmark Loot" and self.contextButton2.mode ~= "Mark Loot" 
    if foundSecondButton then
        self.contextButton3:setTitle(self.contextButton2:getTitle())
        self.contextButton3.mode = self.contextButton2.mode
    end

    if SmashAndGrabQuickLoot.junkItems[self.player][SmashAndGrabUtils.getName(self.items[y])] then
      self.contextButton2:setTitle("Unmark")
      self.contextButton2.mode = "Unmark Loot"
    else
      self.contextButton2:setTitle("Mark")
      self.contextButton2.mode = "Mark Loot"
    end

    self.contextButton2:setVisible(true)
    self.contextButton2:setWidthToTitle()

    if foundSecondButton then
        self.contextButton3:setVisible(true)
        self.contextButton3:setWidthToTitle()       
        self.contextButton3:setX(self.contextButton2:getRight() + 1)
        self.contextButton3:setY(ypos)
    end
end

function SmashAndGrabQuickLoot.markContext(self, button)
    local markables = {self.items[self.buttonOption]}
    if button.mode == "Mark Loot" then
        SmashAndGrabQuickLoot.onMarkItem(markables, self.player)
    end

    if button.mode == "Unmark Loot" then
        SmashAndGrabQuickLoot.onUnmarkItem(markables, self.player)
    end
end

function SmashAndGrabQuickLoot.lootAll(_keyPressed)
    local lootWindow = ISLayoutManager.windows["loot".."0"]
    if not lootWindow or not lootWindow.target.javaObject:isVisible() then
        return
    end

    if (_keyPressed == grabHotkey) then 
        lootWindow.funcs.lootAll()
    elseif (_keyPressed == markTrashHotkey) then 
        local dummyPage = {inventory = lootWindow.target.inventory, player = 0}
        markAll(dummyPage)
    end
end

function SmashAndGrabQuickLoot.createMenu(_player, _context, _items)
    if not _items then return end
    local trashContainer = SmashAndGrabQuickLoot.trash[_player]
    local playerInv = getPlayerInventory(_player).inventory;

    for _, entry in ipairs(_items) do
        if (entry.invPanel and entry.invPanel.inventory == trashContainer or entry.getContainer and entry:getContainer() == trashContainer) then
            _context:clear()
        end

        if not SmashAndGrabQuickLoot.junkItems[_player][SmashAndGrabUtils.getName(entry)] then
            _context:addOption("Mark As Junk", _items, SmashAndGrabQuickLoot.onMarkItem, _player)
            return
        end
    end

    _context:addOption("Unmark As Junk", _items, SmashAndGrabQuickLoot.onUnmarkItem, _player)
end

function SmashAndGrabQuickLoot.addMarkAll(self)
    if self.onCharacter then
        return
    end

    self.markAll = ISButton:new(self.toggleStove:getX(), -1, 50, 14, "Mark All", self, markAll);
    self.markAll:initialise();
    self.markAll.borderColor.a = 0.0;
    self.markAll.backgroundColor.a = 0.0;
    self.markAll.backgroundColorMouseOver.a = 0.7;
    self:addChild(self.markAll);
    self.markAll:setVisible(true);

	self.toggleStove:setX(55 + 
		getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_invpage_Loot_all")) +
		getTextManager():MeasureStringX(UIFont.Small, "Mark All"))
end


SmashAndGrabCustomEvent.addListener("ISInventoryPane:doButtons")
SmashAndGrabCustomEvent.addListener("ISInventoryPane:onContext")
SmashAndGrabCustomEvent.addListener("ISInventoryPage.createChildren")
SmashAndGrabCustomEvent.addListener("ISInventoryPage:refreshBackpacks")
SmashAndGrabCustomEvent.addListener("ISInventoryPane:renderdetails")

Events.postISInventoryPage_refreshBackpacks.Add(SmashAndGrabQuickLoot.addTrashBin)
Events.postISInventoryPane_renderdetails.Add(SmashAndGrabQuickLoot.colorMarkedItems)
Events.postISInventoryPage_createChildren.Add(SmashAndGrabQuickLoot.addMarkAll)
Events.postISInventoryPane_onContext.Add(SmashAndGrabQuickLoot.markContext)
Events.postISInventoryPane_doButtons.Add(SmashAndGrabQuickLoot.doButtons)
Events.OnKeyPressed.Add(SmashAndGrabQuickLoot.lootAll)
Events.OnFillInventoryObjectContextMenu.Add(SmashAndGrabQuickLoot.createMenu)
