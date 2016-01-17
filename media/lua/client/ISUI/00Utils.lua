SmashAndGrabUtils = {}

SmashAndGrabUtils.removeValue = function( t, value )
    for i=#t,1,-1 do
        if t[i] == value then
            table.remove(t, value)
        end
    end
end

SmashAndGrabUtils.print_r = function( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
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
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
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
