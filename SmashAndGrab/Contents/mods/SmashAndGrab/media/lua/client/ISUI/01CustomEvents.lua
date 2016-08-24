SmashAndGrabCustomEvent = {}
SmashAndGrabCustomEvent.registeredFunctions = {}
SmashAndGrabCustomEvent.prelisteners = {}
SmashAndGrabCustomEvent.postlisteners = {}

function SmashAndGrabCustomEvent.addListener(funcName)
    local name = string.gsub(funcName, ":", ".")
    local names = luautils.split(name, ".")
    local eventName = table.concat(names, "_")

    local function wrapper(...)
        local args = SmashAndGrabUtils.pack(...)
        local preargs = SmashAndGrabUtils.pack(...)
        local postargs = SmashAndGrabUtils.pack(...)
        local fn = SmashAndGrabCustomEvent.registeredFunctions[funcName]
        table.insert(preargs, 1, "pre" .. eventName) 
        table.insert(postargs, 1, "post" .. eventName) 

        triggerEvent(unpack(preargs))
        fn(unpack(args))
        triggerEvent(unpack(postargs))
    end

    local function assign(names, table)
        if not table[names[1]] then
            return
        end

        if names[2] then
            assign({ select(2, unpack(names)) }, table[names[1]])
        else
            SmashAndGrabCustomEvent.registeredFunctions[funcName] = table[names[1]]
            table[names[1]] = wrapper
        end
    end

    if not Events['pre' .. eventName] then
        assign(names, _G)
        LuaEventManager.AddEvent('pre' .. eventName)
        LuaEventManager.AddEvent('post' .. eventName)
    end
end
