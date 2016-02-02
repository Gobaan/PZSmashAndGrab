SmashAndGrabQuickLoot = SmashAndGrabQuickLoot or {}

SmashAndGrabQuickLoot.oldMouseUp = ISInventoryPane.onMouseUp
function ISInventoryPane:onMouseUp(x, y)
	if ISMouseDrag.dragging ~= nil and ISMouseDrag.draggingFocus ~= nil then
		if ISMouseDrag.draggingFocus ~= self and self.inventory == SmashAndGrabQuickLoot.trash[self.player] then
			SmashAndGrabQuickLoot.onMarkItem(ISMouseDrag.dragging, self.player) 
			return
        elseif self.inventory ~= SmashAndGrabQuickLoot.trash[self.player] and ISMouseDrag.draggingFocus.inventory == SmashAndGrabQuickLoot.trash[self.player] then
            print ("Moving from SmashAndGrabQuickLoot.trash to inventory")
			SmashAndGrabQuickLoot.onUnmarkItem(ISMouseDrag.dragging, self.player) 
			return
		end
	end

	SmashAndGrabQuickLoot.oldMouseUp(self, x, y)
end

SmashAndGrabQuickLoot.oldDoButtons = ISInventoryPane.doButtons
function ISInventoryPane:doButtons(y)
    -- TODO: add Unmark button
    if self.inventory ~= SmashAndGrabQuickLoot.trash[self.player] then
        SmashAndGrabQuickLoot.oldDoButtons(self, y)
    end
end

SmashAndGrabQuickLoot.oldSelectContainer = ISInventoryPage.selectContainer
function ISInventoryPage:selectContainer(button)
    if ISMouseDrag.dragging ~= nil and self.inventoryPane.inventory == SmashAndGrabQuickLoot.trash[self.player] then
        print ("dragging from trash")
        SmashAndGrabQuickLoot.onUnmarkItem(ISMouseDrag.dragging, self.player) 
    else
        print ("just kidding")
        SmashAndGrabQuickLoot.oldSelectContainer(self, button)
    end
end


local function onDragToTrash(self, button)
	if ISMouseDrag.dragging ~= nil then
		SmashAndGrabQuickLoot.onMarkItem(ISMouseDrag.dragging, self.player)
    else
        for i,v in ipairs(self.backpacks) do
            print (i, v.backgroundColor.a)
            v.backgroundColor.a = 0.0
        end
		button.backgroundColor = {r=0.7, g=0.7, b=0.7, a=1.0};
        self.inventoryPane.lastinventory = button.inventory
        self.inventoryPane.inventory = button.inventory
        self.inventoryPane.selected = {}

	    self.title = button.name
	    self.capacity = button.capacity
    end

	self.inventoryPane:refreshContainer();
end

function SmashAndGrabQuickLoot.addTrashBin(self)
    print ("Adding bin")
    if not self.onCharacter then
        return
    end

    -- click target self
    -- onclick  selectContainer
    -- onmousedown onBackpackMouseDown
    local containerButton = ISButton:new(self.width-32, #self.backpacks * 32 + 15, 32, 32, "", self, onDragToTrash, ISInventoryPage.onBackpackMouseDown, true);
    containerButton:setImage(self.conGarbage);
    containerButton:forceImageSize(30, 30)
    containerButton.anchorBottom = false
    containerButton:setOnMouseOverFunction(ISInventoryPage.onMouseOverButton)
    containerButton:setOnMouseOutFunction(ISInventoryPage.onMouseOutButton)
    containerButton.anchorRight = true
    containerButton.anchorTop = false
    containerButton.anchorLeft = false
    containerButton:initialise()
    containerButton.borderColor.a = 0.0
    containerButton.backgroundColor.a = 0.0
    containerButton.backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=1.0}
    containerButton.inventory = SmashAndGrabQuickLoot.trash[self.player]
    containerButton.capacity = 999999
    containerButton.name = "Trash"
    self:addChild(containerButton)
    self.backpacks[#self.backpacks + 1] = containerButton

    self:updateScrollbars()
    self.inventory:setDrawDirty(false)
end

SmashAndGrabCustomEvent.addListener("ISInventoryPage:refreshBackpacks")
Events.postISInventoryPage_refreshBackpacks.Add(SmashAndGrabQuickLoot.addTrashBin)
