
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

helpers.all_numbers = function(t)
    local numbers = {}
    for w in string.gmatch(t, "%-?%d+%.?%d*") do
        table.insert(numbers, tonumber(w))
    end
    return numbers
end

helpers.find_number = function(t, n)
    local numbers = helpers.all_numbers(t)
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
assert(helpers.find_number('The 2 i', 2))

helpers.match_number = function(result)
    return function(out)
        if not helpers.find_number(out, result) then
            return false, 'выход не содержит правильный ответ ' .. result
        end
        return true
    end
end

helpers.find_numbers = function(out, nn)
    local nn_str = table.concat(nn, ', ')
    local numbers = helpers.all_numbers(out)
    local numbers_str = table.concat(numbers, ', ')
    if #nn ~= #numbers then
        return false, string.format([[
Выход содержит неправильное количество чисел.
Мы ожидали %i чисел: %s
В выходе вашей программы мы нашли %i чисел: %s]],
#nn, nn_str,
#numbers, numbers_str)
    end
    THRESHOLD = 0.001
    for i = 1, #nn do
        if math.abs(nn[i] - numbers[i]) > THRESHOLD then
            return false, string.format([[
Выход содержит неправильное число.
Мы ожидали числа: %s
В выходе вашей программы мы нашли числа: %s
Число с номером %i отличается. У нас %f, а у вас %f]],
nn_str,
numbers_str, i, nn[i], numbers[i])
        end
    end
    return true
end

assert(helpers.find_numbers('1 1.2\n3.67', {1, 1.2, 3.67}))
assert(not helpers.find_numbers('1 1.2\n3.67', {1, 1.2}))
assert(not helpers.find_numbers('1 1.1', {1, 1.2}))

helpers.match_numbers = function(...)
    local nn = {...}
    return function(out)
        return helpers.find_numbers(out, nn)
    end
end

helpers.match_str = function(result)
    return function(out)
        if not out:match(result) then
            return false,
                'выход не содержит правильный ответ ' ..
                result
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

