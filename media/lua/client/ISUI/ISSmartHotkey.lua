ISSmartHotkey = {};

function ISSmartHotkey.onKeyPress (_keyPressed)
    if (_keyPressed ~= 19) then return; end
    local player = getSpecificPlayer(0);    -- Java: get player one
    if not player then return; end
    ISSmartHotkey.interact (player)
end

local function createIndex(_table)
    local index = {}
    for name, value in pairs(_table) do
        index[value] = name;
    end
    return index;
end

local neighbours = {
    IsoDirections.N,
    IsoDirections.NE,
    IsoDirections.E,
    IsoDirections.SE,
    IsoDirections.S,
    IsoDirections.SW,
    IsoDirections.W,
    IsoDirections.NW,
}

local neighboursIndex = createIndex(neighbours);

local function getNeighbours(direction, offset)
    local clockwise = (neighboursIndex[direction] + offset) % 9 or 1
    return neighbours[clockwise] 
end

local function getOffsets(direction)
    local yMod = 0;
    local xMod = 0;

    if (direction == IsoDirections.N or direction == IsoDirections.NE or direction == IsoDirections.NW) then
        yMod = -1;
    elseif (direction == IsoDirections.S or direction == IsoDirections.SE or direction == IsoDirections.SW) then
        yMod = 1;
    end

    if (direction == IsoDirections.E or direction == IsoDirections.NE or direction == IsoDirections.SE) then
        xMod = 1;
    elseif (direction == IsoDirections.W or direction == IsoDirections.NW or direction == IsoDirections.SW) then
        xMod = -1;
    end
    return xMod, yMod
end

local function getRelativeCell(_position, _direction)
    local currentX = _position:getX();
    local currentY = _position:getY();
    local currentZ = _position:getZ();
    local xMod, yMod = getOffsets(_direction)
    return getCell():getGridSquare(currentX + xMod, currentY + yMod, currentZ);
end

-- Gets an adjacency list where coordinates are relative to the direction of the player, north being where they are facing
function ISSmartHotkey.getAdjacentSquares (_player)
    local position = _player:getCurrentSquare();
    local direction = _player:getDir(); 

    local adjacent = {
        N = getRelativeCell(position, direction),
        NE = getRelativeCell(position, getNeighbours(direction, 1)),
        E = getRelativeCell(position, getNeighbours(direction, 2)),
        SE = getRelativeCell(position, getNeighbours(direction, 3)),
        S = getRelativeCell(position, getNeighbours(direction, 4)),
        SW = getRelativeCell(position, getNeighbours(direction, 5)),
        W = getRelativeCell(position, getNeighbours(direction, 6)),
        NW = getRelativeCell(position, getNeighbours(direction, 7)),
    }
    return adjacent;
end

function ISSmartHotkey.Aligned(square1, square2)
    return square1:getX() == square2:getX() or square1:getY() == square2:getY();
end

local function interactWithWindow(_player, _adjacent)
    local position = _player:getCurrentSquare();
    local window = position:getWindowTo(_adjacent["N"]);
    local cleanTime = 100 - 10 * _player:getPerkLevel(Perks.Nimble)
    if cleanTime <= 10 then
        cleanTime = 10
    end

    if window == nil or not ISSmartHotkey.Aligned(position, window) or window:getBarricade() ~= 0 then return false; end
    local targetSquare = position:Is(IsoFlagType.exterior) and window:getSquare() or window:getIndoorSquare();
    if not luautils.walkAdjWindowOrDoor(_player, targetSquare, window) then return false; end;

    if window:isSmashed() and not window:isGlassRemoved() then
        ISTimedActionQueue.add(ISRemoveBrokenGlass:new(_player, window, cleanTime));
        return true;
    elseif window:getZ() == 0 and window:canClimbThrough(_player) then
        _player:climbThroughWindow(window);
        return true;
    -- TODO: Else Add sheet rope if inventory contains sheet rope, window Z is >= 1 and window is open
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

local function interactWithSheetRope(_player)
    if _player:canClimbSheetRope(_player:getCurrentSquare()) then
        ISTimedActionQueue.add(ISClimbSheetRopeAction:new(_player, false))
        return true;
    elseif _player:canClimbDownSheetRope(_player:getCurrentSquare()) then
        ISTimedActionQueue.add(ISClimbSheetRopeAction:new(_player, true))
        return true;
    end
    return false;
end

-- Window, if second floor, missing sheetrope? add sheet rope
-- Window, if second floor, has sheet rope? climb down
-- Window, if interior add or remove sheet
-- Window, if closed smash
-- Window, if broken, remove glass
-- Window, if open (destroyed?) climb through
-- (TEST) SheetRope, climb sheet rope
-- (Failed) Zombie, check all squares to see if zombie is there then walk to and stomp? Already worked for infront, spinning and checking behind you just did weird things. Most of the zombie is further than one tile away
-- (TODO) Door, thump dooor? lockpick? crowbar?
function ISSmartHotkey.interact (_player)
    local adjacent = ISSmartHotkey.getAdjacentSquares(_player);
    return interactWithSheetRope(_player) or interactWithWindow(_player, adjacent);
end

ISSmartHotkey.oldRemoveGlass = ISSmartHotkey.oldRemoveGlass or ISRemoveBrokenGlass.perform
function ISRemoveBrokenGlass:perform()
    ISSmartHotkey.oldRemoveGlass(self)
    self.character:getXp():AddXP(Perks.Nimble, 5);
end

Events.OnKeyPressed.Add(ISSmartHotkey.onKeyPress);
