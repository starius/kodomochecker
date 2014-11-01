
local math = require("math")

local sh = require("sh")
local pf = string.format

math.randomseed(os.time())

local shortrand = require('helpers').shortrand
local rr = math.random
local genname = require('helpers').genname
local find_number = require('helpers').find_number
local match_number = require('helpers').match_number

local pr8 = {

{'hello', {
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
}},

{'protein-length', {
function()
    local start = rr(100, 1000)
    local result = rr(10, 100)
    local stop = start + (result + 1) * 3 - 1
    return start .. '\n' .. stop, match_number(result)
end
}},

{'number-length', {
function()
    local a = rr(10, 100)
    local b = rr(10, 100)
    local result = sh(pf('python -c "print(len(str(%i ** %i)))"', a, b))
    return a .. '\n' .. b, match_number(result)
end
}},

{'hypotenuse', {
function()
    local a = rr(10, 100) / 10
    local b = rr(10, 100) / 10
    local result = (a^2 + b^2) ^ 0.5
    return a .. '\n' .. b, match_number(result)
end
}},

{'last-digit', {
function()
    local a = rr(1000, 9999)
    local result = a % 10
    return a, match_number(result)
end
}},

{'repeat', {
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
}},

{'exp', {
function()
    local a = rr(1, 20)
    local result = math.floor(math.exp(a) + 0.5)
    return a, match_number(result)
end
}},

{'parabola', {
function()
    local b = rr(-1000, 1000) / 100
    local c = rr(-1000, 1000) / 100
    local x = -b/2
    local y = x^2 + b * x + c
    return b .. '\n' .. c, function(out)
        if find_number(out, x) and find_number(out, y) then
            return true
        else
            return false, pf([[выдача вашей программы
                не содержит верных чисел
                %s и %s]], x, y)
        end
    end
end
}},

{'neutralization', {
function()
    local hcl = rr(0, 1000) / 100
    local koh = rr(0, 1000) / 100
    local kcl = math.min(hcl, koh)
    local hcl2 = hcl - kcl
    local koh2 = koh - kcl
    return hcl .. '\n' .. koh, function(out)
        if not out:match(kcl) then
            return false, pf([[выдача вашей программы
                не содержит верного количества KCl ]] .. kcl)
        elseif not out:match(hcl2) then
            return false, pf([[выдача вашей программы
                не содержит верного количества HCl ]] .. hcl2)
        elseif not out:match(koh2) then
            return false, pf([[выдача вашей программы
                не содержит верного количества KOH ]] .. koh2)
        end
        return true
    end
end
}},

{'pie', {
function()
    local a = rr(1, 20)
    local b = rr(0, 99)
    local n = rr(0, 10)
    return a .. '\n' .. b .. '\n' .. n, function(out)
        local pie_kop = a * 100 + b
        local all = pie_kop * n
        local rub = math.floor(all / 100)
        local kop = all % 100
        if not find_number(out, rub) then
            return false, pf([[выдача вашей программы
                не содержит верного количества рублей ]] .. rub)
        elseif not find_number(out, kop) then
            return false, pf([[выдача вашей программы
                не содержит верного количества копеек ]] .. kop)
        end
        return true
    end
end
}},

{'cookie', {
function()
    local a = rr(1, 20)
    local b = rr(0, 99)
    local c = rr(1, 20)
    local d = rr(0, 99)
    local n = math.floor((c * 100 + d) / (a * 100 + b))
    return a .. '\n' .. b .. '\n' .. c .. '\n' .. d,
        match_number(n)
end
}},

{'week', {
function()
    local jan1 = rr(1, 7)
    local day = rr(1, 365)
    local n = ((jan1 - 1) + (day - 1)) % 7 + 1
    return jan1 .. '\n' .. day, match_number(n)
end
}}

}

return pr8
