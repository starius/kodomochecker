
local math = require("math")

local sh = require("sh")
local pf = string.format

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

local rr = math.random

local genname = function()
    return shortrand() .. shortrand():lower()
end

local pr8 = {}

pr8.hello = {
function()
    local name = genname()
    return name, function(out)
        if not out:lower():match('hello') then
            return false, 'в выходе нет "hello"'
        end
        if not out:match(name) then
            return false, 'в выходе нет имени, введённого пользователем'
        end
        return true
    end
end
}

local find_number = function(t, n)
    return t:match('^' .. n .. '$') or
           t:match('%D' .. n .. '$') or
           t:match('^' .. n .. '%D') or
           t:match('%D' .. n .. '%D')
end

local match_number = function(result)
    return function(out)
        if not find_number(out, result) then
            return false, 'выход не содержит правильный ответ ' .. result
        end
        return true
    end
end

pr8['protein-length'] = {
function()
    local start = rr(100, 1000)
    local result = rr(10, 100)
    local stop = start + (result + 1) * 3 - 1
    return start .. '\n' .. stop, match_number(result)
end
}

pr8['number-length'] = {
function()
    local a = rr(10, 100)
    local b = rr(10, 100)
    local result = sh(pf('python -c "print(len(str(%i ** %i)))"', a, b))
    return a .. '\n' .. b, match_number(result)
end
}

pr8['hypotenuse'] = {
function()
    local a = rr(10, 100) / 10
    local b = rr(10, 100) / 10
    local result = (a^2 + b^2) ^ 0.5
    return a .. '\n' .. b, match_number(result)
end
}

pr8['last-digit'] = {
function()
    local a = rr(1000, 9999)
    local result = a % 10
    return a, match_number(result)
end
}

pr8['repeat'] = {
function()
    local t = shortrand()
    local n = rr(3, 7)
    local result = t .. string.rep(',' .. t, n - 1)
    return t .. '\n' .. n, function(out)
        if not out:match(result) then
            return false, 'выход не содержит правильный ответ ' .. result
        end
        local start, stop = out:find(result)
        if start > 1 and out:sub(start - 1, start - 1) == t:sub(-1,-1) then
            return false, [[выход содержит что-то лишнее рядом с
                правильным ответом ]] .. result
        end
        if start > 1 and out:sub(start - 1, start - 1) == ',' then
            return false, [[выход содержит что-то лишнее рядом с
                правильным ответом ]] .. result
        end
        if out:sub(stop + 1, stop + 1) == ',' then
            return false, [[выход содержит что-то лишнее рядом с
                правильным ответом ]] .. result
        end
        if out:sub(stop + 1, stop + 1) == t:sub(1,1) then
            return false, [[выход содержит что-то лишнее рядом с
                правильным ответом ]] .. result
        end
        return true
    end
end
}

return pr8
