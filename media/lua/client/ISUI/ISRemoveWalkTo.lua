UIRemoveWalkTo = {};

-- See the OnFillWorldObjectContextMenu for event details
function UIRemoveWalkTo.removeWalkTo(_player, _context, _worldobjects, test)
    if test == true then return true; end
    UIRemoveWalkTo.removeOption(_context, getText("ContextMenu_Walk_to"))
end

function UIRemoveWalkTo.removeOption(_context, name)
    local menu = nil;
    local options = {};
    local numOptions = 1;
    
    -- all id's must be decremented if the option is found
    for i=1,_context.numOptions - 1 do
        if _context.options[i].name ~= name then
            options[numOptions] = _context.options[i];
	        options[numOptions].id = numOptions;
            numOptions = numOptions + 1
        else
            menu = _context.options[i]
        end 
    end
 
    -- replication of context.addOption
    _context.options = options;
    _context.numOptions = numOptions;
    _context:setHeight(((_context.numOptions-1) * _context.itemHgt) + _context.padTopBottom * 2);

    -- return the menu item if it was destroyed
    return menu;
end

Events.OnFillWorldObjectContextMenu.Add(UIRemoveWalkTo.removeWalkTo);
