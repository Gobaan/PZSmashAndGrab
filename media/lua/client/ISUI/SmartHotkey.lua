SmashAndGrabSmartHotkey = {};
local hotkey = 19 -- 'r'

function SmashAndGrabSmartHotkey.onKeyPress (_keyPressed)
    if (_keyPressed ~= hotkey) then return; end
    local player = getSpecificPlayer(0);    -- Java: get player one
    if not player then return; end
    SmashAndGrabSmartHotkey.interact (player)
end

local function canAddSheetRope(_player, _position, _window)
    return _window ~= nil and _window:canAddSheetRope() and _position:getZ() > 0 and _window:getBarricade() == 0 and (_player:getInventory():getNumberOfItem("SheetRope") >= _window:countAddSheetRope() or _player:getInventory():getNumberOfItem("Rope") >= _window:countAddSheetRope()) and _player:getInventory():contains("Nails") 
end

local function interactWithSheetRope(_player, _adjacent)
    local position = _player:getCurrentSquare();
    local window = position:getWindowTo(_adjacent["N"]);

    if window and window:haveSheetRope() then
        _player:climbThroughWindow(window);
        return true;
    elseif _player:canClimbSheetRope(position) then
        ISTimedActionQueue.add(ISClimbSheetRopeAction:new(_player, false))
        return true;
    end
    return false;
end

local function interactWithWindow(_player, _adjacent)
    local position = _player:getCurrentSquare();
    local window = position:getWindowTo(_adjacent["N"]);
    local cleanTime = 100 - 10 * _player:getPerkLevel(Perks.Nimble)
    if cleanTime <= 10 then
        cleanTime = 10
    end

    if window == nil or not SmashAndGrabPlayerUtils.Aligned(position, window) or window:getBarricade() ~= 0 then return false; end
    local targetSquare = position:Is(IsoFlagType.exterior) and window:getSquare() or window:getIndoorSquare()
    if not luautils.walkAdjWindowOrDoor(_player, targetSquare, window) then 
        return false
    end

    if window:isSmashed() and not window:isGlassRemoved() then
        ISTimedActionQueue.add(ISRemoveBrokenGlass:new(_player, window, cleanTime));
        return true
    elseif window:getZ() == 0 and window:canClimbThrough(_player) then
        _player:climbThroughWindow(window);
        return true
    elseif canAddSheetRope(_player, position, window) then
        ISTimedActionQueue.add(ISAddSheetRope:new(_player, window));
        return true
    end

    if position:Is(IsoFlagType.exterior) and not window:isDestroyed() and not window:isSmashed() then
        _player:smashWindow(window);
        return true;
    elseif window:HasCurtains() then
        ISTimedActionQueue.add(ISOpenCloseCurtain:new(_player, window:HasCurtains(), 0));
        return true;
    elseif _player:getInventory():contains("Sheet") then
        ISTimedActionQueue.add(ISAddSheetAction:new(_player, window, 50));
        return true;
    end 
    return false;
end

-- Window, if floor > 1, missing sheetrope? add sheet rope
-- Window, if floor > 1, has sheet rope? climb down
-- Window, if closed and interior add or remove sheet
-- Window, if closed and outside smash
-- Window, if broken and outside, remove glass
-- Window, if open (destroyed?) climb through
-- SheetRope, climb sheet rope
-- (Failed) Zombie, check all squares to see if zombie is there then walk to and stomp? Already worked for infront,
--    spinning and checking behind you just did weird things. Most of the zombie is further than one tile away
-- (TODO) Investigate LUA Utils getNextTiles for zombie scanning
-- (TODO) Door, thump dooor? lockpick? crowbar?
function SmashAndGrabSmartHotkey.interact (_player)
    local adjacent = SmashAndGrabPlayerUtils.getAdjacentSquares(_player);
    return interactWithSheetRope(_player, adjacent) or interactWithWindow(_player, adjacent);
end

function SmashAndGrabSmartHotkey.removeBrokenGlass(self)
    self.character:getXp():AddXP(Perks.Nimble, 5);
end

SmashAndGrabCustomEvent.addListener("ISRemoveBrokenGlass:perform")
Events.preISRemoveBrokenGlass_perform.Add(SmashAndGrabSmartHotkey.removeBrokenGlass)
Events.OnKeyPressed.Add(SmashAndGrabSmartHotkey.onKeyPress);
