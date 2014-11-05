
local helpers = {}

helpers.unPack = unpack or table.unpack

helpers.shortrand = function()
    local t = {}
    local l = math.random(3, 7)
    for i = 1, l do
        table.insert(t, math.random(65, 90)) -- A-Z
    end
    return string.char(helpers.unPack(t))
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

THRESHOLD = 0.001
local arr_find_num = function(arr, num, start)
    for i = start, #arr do
        if math.abs(arr[i] - num) <= THRESHOLD then
            return i
        end
    end
end

helpers.find_numbers = function(out, nn, order)
    if order == nil then
        order = true
    end
    local numbers = helpers.all_numbers(out)
    if not order then
        table.sort(nn)
        table.sort(numbers)
    end
    local nn_str = table.concat(nn, ', ')
    local numbers_str = table.concat(numbers, ', ')
    if #numbers < #nn then
        return false, string.format([[
Выход содержит недостаточное количество чисел.
Мы ожидали %i чисел: %s
В выходе вашей программы мы нашли %i чисел: %s]],
#nn, nn_str,
#numbers, numbers_str)
    end
    if #numbers > #nn * 2 then
        return false, string.format([[
Выход содержит слишком много чисел.
Мы ожидали %i чисел: %s
В выходе вашей программы мы нашли %i чисел: %s]],
#nn, nn_str,
#numbers, numbers_str)
    end
    local start = 1
    for i = 1, #nn do
        local hit = arr_find_num(numbers, nn[i], start)
        if not hit then
            return false, string.format([[
Выход не содержит правильное число.
Мы ожидали числа: %s
В выходе вашей программы мы нашли числа: %s
Не могу найти число %f в выходе]],
nn_str, numbers_str, nn[i])
        end
        start = hit + 1
    end
    return true
end

assert(helpers.find_numbers('1 1.2\n3.67', {1, 1.2, 3.67}))
assert(helpers.find_numbers('1 1.2\n3.67', {1, 1.2}))
assert(helpers.find_numbers('1 4 1.2\n3.67', {1, 1.2}))
assert(not helpers.find_numbers('1 1.1', {1, 1.2}))

assert(helpers.find_numbers('1 2 1.1', {1.1, 1, 2}, false))
assert(not helpers.find_numbers('1 2 1.1', {1.1, 1, 2}, true))
assert(not helpers.find_numbers('1 2 1.9', {1.1, 1, 2}, false))

helpers.match_numbers = function(...)
    local nn = {...}
    return function(out)
        return helpers.find_numbers(out, nn, true)
    end
end

helpers.match_numbers_no_order = function(...)
    local nn = {...}
    return function(out)
        return helpers.find_numbers(out, nn, false)
    end
end

helpers.bool_wrapper = function(f)
    return function(out)
        out = out:gsub('[Tt]rue', 1)
        out = out:gsub('[Ff]alse', 0)
        return f(out)
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

helpers.match_choice = function(result, choices)
    return function(out)
        if not out:match(result) then
            return false,
                'выход не содержит правильный ответ ' ..
                result
        end
        for _, choice in ipairs(choices) do
            if choice ~= result and out:match(choice) then
                return false,
                    'выход содержит неправильный ответ ' ..
                    choice
            end
        end
        return true
    end
end

helpers.find_strs = function(out, nn, order)
    if order == nil then
        order = true
    end
    local nn_str = table.concat(nn, ', ')
    local start = 1
    for i, word in ipairs(nn) do
        if not order then
            start = 1
        end
        local a, b = out:find(word, start, true)
        if not a then
            return false, string.format([[
Выход не содержит фразы %s.
Мы ожидали увидеть в выходе такие фразы: %s]],
word, nn_str)
        end
        start = a
    end
    return true
end

assert(helpers.find_strs('1 1.2\n3.67', {'1', '1.2', '3.67'}))
assert(not helpers.find_strs('1 1.1', {'1', '1.2'}))

helpers.match_strs = function(...)
    local nn = {...}
    return function(out)
        return helpers.find_strs(out, nn, true)
    end
end

helpers.match_strs_no_order = function(...)
    local nn = {...}
    return function(out)
        return helpers.find_strs(out, nn, false)
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

helpers.one_of = function(...)
    local t = {...}
    return t[math.random(1, #t)]
end

helpers.copy_list = function(ll)
    local ll2 = {}
    for _, e in ipairs(ll) do
        table.insert(ll2, e)
    end
    return ll2
end

helpers.shuffle = function(t)
    local t2 = {}
    while #t > 0 do
        table.insert(t2, table.remove(t, math.random(1, #t)))
    end
    return t2
end

helpers.read_file = function(fname)
    local f = io.open(fname)
    local t = f:read('*a')
    f:close()
    return t
end

helpers.add_test = function(prac, name0, func)
    for name, funcs in pairs(prac) do
        if name == name0 then
            table.insert(funcs, func)
            return
        end
    end
    table.insert(prac, {name, {func}})
end

return helpers

