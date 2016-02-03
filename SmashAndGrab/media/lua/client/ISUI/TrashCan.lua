SmashAndGrabQuickLoot = SmashAndGrabQuickLoot or {}

SmashAndGrabQuickLoot.trashButton = nil
local function onDragToTrash(self, button)
	if ISMouseDrag.dragging ~= nil then
		SmashAndGrabQuickLoot.onMarkItem(ISMouseDrag.dragging, self.player)
    else
        for i,v in ipairs(self.backpacks) do
            v.backgroundColor.a = 0.0
        end
		SmashAndGrabQuickLoot.trashButton.backgroundColor = {r=0.7, g=0.7, b=0.7, a=1.0};
        self.inventoryPane.lastinventory = button.inventory
        self.inventoryPane.inventory = button.inventory
        self.inventoryPane.selected = {}

	    self.title = button.name
	    self.capacity = button.capacity
    end

	self.inventoryPane:refreshContainer();
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
		SmashAndGrabQuickLoot.trashButton.backgroundColor.a = 0.0
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
	if SmashAndGrabQuickLoot.trashButton then
		self:removeChild(SmashAndGrabQuickLoot.trashButton)
		SmashAndGrabQuickLoot.trashButton.backgroundColor.a = 0.0
	end
	SmashAndGrabQuickLoot.trashButton = ISButton:new(self.width-32, #self.backpacks * 32 + 15, 32, 32, "", self, onDragToTrash, ISInventoryPage.onBackpackMouseDown, true);
    SmashAndGrabQuickLoot.trashButton:setImage(self.conGarbage);
    SmashAndGrabQuickLoot.trashButton:forceImageSize(30, 30)
    SmashAndGrabQuickLoot.trashButton.anchorBottom = false
    SmashAndGrabQuickLoot.trashButton:setOnMouseOverFunction(ISInventoryPage.onMouseOverButton)
    SmashAndGrabQuickLoot.trashButton:setOnMouseOutFunction(ISInventoryPage.onMouseOutButton)
    SmashAndGrabQuickLoot.trashButton.anchorRight = true
    SmashAndGrabQuickLoot.trashButton.anchorTop = false
    SmashAndGrabQuickLoot.trashButton.anchorLeft = false
    SmashAndGrabQuickLoot.trashButton:initialise()
    SmashAndGrabQuickLoot.trashButton.borderColor.a = 0.0
    SmashAndGrabQuickLoot.trashButton.backgroundColor.a = 0.0
    SmashAndGrabQuickLoot.trashButton.backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=1.0}
    SmashAndGrabQuickLoot.trashButton.inventory = SmashAndGrabQuickLoot.trash[self.player]
    SmashAndGrabQuickLoot.trashButton.capacity = 0
    SmashAndGrabQuickLoot.trashButton.name = "Trash"
    self:addChild(SmashAndGrabQuickLoot.trashButton)

    self:updateScrollbars()
    self.inventory:setDrawDirty(false)
end

SmashAndGrabCustomEvent.addListener("ISInventoryPage:refreshBackpacks")
Events.postISInventoryPage_refreshBackpacks.Add(SmashAndGrabQuickLoot.addTrashBin)
