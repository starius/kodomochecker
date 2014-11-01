
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

helpers.find_number = function(t, n)
    local numbers = {}
    for w in string.gmatch(t, "%-?%d+") do
        table.insert(numbers, tonumber(w))
    end
    for w in string.gmatch(t, "%-?%d+%.%d+") do
        table.insert(numbers, tonumber(w))
    end
    for _, n1 in ipairs(numbers) do
        if math.abs(n - n1) < 0.001 then
            return true
        end
    end
    return false
end

assert(helpers.find_number('\n0.04 KOH', 0.039999999999999))
assert(helpers.find_number('0\n0.07\n7.2', 0.069999999999999))
assert(helpers.find_number('The vertix is (2.655;-11.489025)', 2.655))
assert(helpers.find_number('The vertix is (2.655;-11.489025)', -11.489025))

helpers.match_number = function(result)
    return function(out)
        if not helpers.find_number(out, result) then
            return false, 'выход не содержит правильный ответ ' .. result
        end
        return true
    end
end

if _VERSION == 'Lua 5.2' then
    helpers.execute = os.execute
elseif _VERSION == 'Lua 5.1' then
    helpers.execute = function(...)
        local status = os.execute(...)
        return status == 0
    end
end

return helpers

