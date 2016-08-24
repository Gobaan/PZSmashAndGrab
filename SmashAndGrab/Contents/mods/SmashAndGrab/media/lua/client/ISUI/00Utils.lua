SmashAndGrabUtils = {}

SmashAndGrabUtils.removeValue = function(t, value)
    for i=#t,1,-1 do
        if t[i] == value then
            table.remove(t, value)
        end
    end
end

SmashAndGrabUtils.printKeys = function (t)
    for k, v in ipairs(t) do
        print (k, v)
    end
end

SmashAndGrabUtils.printR = function(t, depth)  
      if not depth then 
        depth = 1
    end

    local printR_cache={}
    local function subPrintR(t, indent, depth)
        if depth == 0 then
            print (indent, 'max depth reached')
            return
        end
 
        if (printR_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            printR_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        subPrintR(val,indent..string.rep(" ",string.len(pos)+8), depth - 1)
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        subPrintR(t,"  ", depth)
        print("}")
    else
        subPrintR(t,"  ", depth)
    end
    print()
end

SmashAndGrabUtils.pack = function (...)
    return { n = select("#", ...), ... }
end

SmashAndGrabUtils.createIndex = function(_table)
    local index = {}
    for name, value in pairs(_table) do
        index[value] = name
    end
    return index
end

SmashAndGrabUtils.defaultDict = function (defaultValueFactory)
    local t = {}
    local metatable = {}
    metatable.__index = function(t, key)
        if not rawget(t, key) then
            rawset(t, key, defaultValueFactory(key))
        end
        return rawget(t, key)
    end
    return setmetatable(t, metatable)
end

SmashAndGrabUtils.getItem = function(_item)
    if instanceof(_item, "InventoryItem") then
        return _item
    elseif type(_item) == "table" then
        return _item.items[2]
    end
end

SmashAndGrabUtils.getName = function(_item)
    item = SmashAndGrabUtils.getItem(_item)
    return item:getModule() .. "." .. item:getType()
end
