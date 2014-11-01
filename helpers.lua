
local helpers = {}

helpers.shortrand = function()
    local t = {}
    local l = math.random(3, 7)
    for i = 1, l do
        table.insert(t, math.random(65, 90)) -- A-Z
    end
    local unPack = unpack or table.unpack
    return string.char(unPack(t))
end

helpers.genname = function()
    return helpers.shortrand() .. helpers.shortrand():lower()
end

helpers.float1 = function(x)
    if x > 0 then
        return tostring(math.floor(x * 10) / 10)
    else
        return tostring(-(math.floor(-x * 10) / 10))
    end
end

helpers.find_number = function(t, n)
    local numbers = {}
    for w in string.gmatch(t, "%d+") do
        table.insert(numbers, tonumber(w))
    end
    for w in string.gmatch(t, "%d+%.%d") do
        table.insert(numbers, tonumber(w))
    end
    for _, n1 in ipairs(numbers) do
        if math.abs(n - n1) < 0.001 then
            return true
        end
    end
    return false
end

helpers.match_number = function(result)
    return function(out)
        if not helpers.find_number(out, result) then
            return false, 'выход не содержит правильный ответ ' .. result
        end
        return true
    end
end

return helpers

