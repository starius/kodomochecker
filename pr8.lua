
local math = require("math")

math.randomseed(os.time())

local shortrand = function()
    local t = {}
    local l = math.random(3, 7)
    for i = 1, l do
        table.insert(t, math.random(65, 90)) -- A-Z
    end
    local unPack = unpack or table.unpack
    return string.char(unPack(t))
end

local genname = function()
    return shortrand() .. shortrand():lower()
end

local pr8 = {}

pr8.hello = function()
    local name = genname()
    return name, function(out)
        if not out:lower():match('hello') then
            return false, 'no "hello" in output'
        end
        if not out:match(name) then
            return false, 'no desired name in output'
        end
        return true
    end
end

return pr8
