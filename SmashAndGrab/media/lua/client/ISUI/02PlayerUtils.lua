SmashAndGrabPlayerUtils = {}

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

local neighboursIndex = SmashAndGrabUtils.createIndex(neighbours)

local function getNeighbours(direction, offset)
    local clockwise = (neighboursIndex[direction] + offset) % 9 or 1
    return neighbours[clockwise] 
end

local function getOffsets(direction)
    local yMod = 0
    local xMod = 0

    if (direction == IsoDirections.N or direction == IsoDirections.NE or direction == IsoDirections.NW) then
        yMod = -1
    elseif (direction == IsoDirections.S or direction == IsoDirections.SE or direction == IsoDirections.SW) then
        yMod = 1
    end

    if (direction == IsoDirections.E or direction == IsoDirections.NE or direction == IsoDirections.SE) then
        xMod = 1
    elseif (direction == IsoDirections.W or direction == IsoDirections.NW or direction == IsoDirections.SW) then
        xMod = -1
    end
    return xMod, yMod
end

local function getRelativeCell(_position, _direction)
    local currentX = _position:getX()
    local currentY = _position:getY()
    local currentZ = _position:getZ()
    local xMod, yMod = getOffsets(_direction)
    return getCell():getGridSquare(currentX + xMod, currentY + yMod, currentZ)
end

-- TODO: Future version should just tack a string N, W, S, E, NNW, NWW, WWN, and generate the final cell
-- Gets an adjacency list where coordinates are relative to the direction of the player, north being where they are facing
SmashAndGrabPlayerUtils.getAdjacentSquares = function (_player)
    local position = _player:getCurrentSquare()
    local direction = _player:getDir() 

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
    return adjacent
end

SmashAndGrabPlayerUtils.Aligned = function(square1, square2)
    return square1:getX() == square2:getX() or square1:getY() == square2:getY()
end
