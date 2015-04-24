-- Problems: http://kodomo.fbb.msu.ru/wiki/Main/LuaAndC/cw

local sh = require("sh")
local pf = string.format
local rr = math.random

math.randomseed(os.time())

local genname = require('helpers').genname
local shuffle = require('helpers').shuffle
local find_number = require('helpers').find_number
local match_number = require('helpers').match_number
local match_numbers = require('helpers').match_numbers
local match_numbers_no_order =
    require('helpers').match_numbers_no_order
local match_str = require('helpers').match_str
local match_strs = require('helpers').match_strs
local match_strs_no_order = require('helpers').match_strs_no_order
local match_choice = require('helpers').match_choice
local bool_wrapper = require('helpers').bool_wrapper
local one_of = require('helpers').one_of
local unPack = require('helpers').unPack
local copy_list = require('helpers').copy_list
local read_file = require('helpers').read_file
local get_tests = require('helpers').get_tests
local ifile = require('helpers').ifile
local ofile = require('helpers').ofile

local h = require('helpers')

local cw = {}

local add_test = function(name, func)
    local add_test0 = require('helpers').add_test
    add_test0(cw, name, func)
end

local checkpy = require('checkpy')

add_test('cubes2', function()
    local a = rr(1, 5)
    local b = rr(1, 5)
    local c = rr(1, 5)
    local colored = function(i, j, k)
        local result = 0
        local add_if = function(cond)
            if cond then
                result = result + 1
            end
        end
        add_if(i == 1)
        add_if(i == a)
        add_if(j == 1)
        add_if(j == b)
        --add_if(k == 1)
        add_if(k == c)
        return result
    end
    local tt = {}
    for i = 1, a do
        for j = 1, b do
            for k = 1, c do
                local cc = colored(i, j, k)
                if tt[cc] == nil then
                    tt[cc] = 0
                end
                tt[cc] = tt[cc] + 1
            end
        end
    end
    local expected = {}
    for cc = 0, 6 do
        if tt[cc] ~= nil then
            table.insert(expected, cc)
            table.insert(expected, tt[cc])
        end
    end
    local task = pf('%i\n%i\n%i', a, b, c)
    return task, match_numbers(unPack(expected))
end)

local tr_abc = function(a, b, c)
    local abc = {a, b, c}
    abc = shuffle(abc)
    a, b, c = unPack(abc)
    return pf('%f\n%f\n%f', a, b, c)
end

local tr_choices = {'degenerate', 'right', 'acute', 'obtuse'}

add_test('triangle', function()
    local a = rr(1, 20)
    local b = rr(1, 20)
    local c = a + b
    return tr_abc(a, b, c),
        match_choice('degenerate', tr_choices)
end)

add_test('triangle', function()
    -- https://en.wikipedia.org/wiki/Pythagorean_triple#Generating_a_triple
    local n = rr(1, 1000)
    local m = n + rr(1, 1000)
    local a = m^2 - n^2
    local b = 2 * m * n
    local c = m^2 + n^2
    return tr_abc(a, b, c),
        match_choice('right', tr_choices)
end)

add_test('triangle', function()
    local a = rr(1, 100)
    local b = rr(1, 100)
    local hyp = (a^2 + b^2) ^ 0.5
    local a_plus_b = a + b
    local c = (a_plus_b + hyp) / 2
    return tr_abc(a, b, c),
        match_choice('obtuse', tr_choices)
end)

add_test('triangle', function()
    local a = rr(1, 100)
    local b = rr(1, 100)
    local hyp = (a^2 + b^2) ^ 0.5
    local a_max_b = math.max(a, b)
    local c = (a_max_b + hyp) / 2
    return tr_abc(a, b, c),
        match_choice('acute', tr_choices)
end)

add_test('max', function()
    local a = rr(1, 100)
    return a .. '\n' .. a, match_number(a)
end)

add_test('max', function()
    local a = rr(1, 100)
    local b = rr(1, 100)
    return a .. '\n' .. b, match_number(math.max(a, b))
end)

local function examCheck(nExp, nMax)
    return function(out)
        local numbers = {}
        for i in out:gmatch('%d+') do
            table.insert(numbers, tonumber(i))
        end
        local n = table.remove(numbers, 1)
        if n ~= #numbers then
            return false, ([[Неправильное число элементов в
                списке студентов. Задекларировано %d, а
                получено %d]]):format(n, #numbers)
        end
        if n ~= nExp then
            return false, ([[Неправильное число студентов.
                Задекларировано %d, а ожидалось %d]])
                :format(n, nExp)
        end
        local seen = {}
        for _, stud in ipairs(numbers) do
            if stud < 1 or stud > nMax then
                return false, ([[Недопустимый номер студента:
                    %d]]):format(stud)
            end
            if seen[stud] then
                return false, ([[Студент с номером %d
                    указан дважды]]):format(stud)
            end
            seen[stud] = true
        end
        for i = 2, n do
            if math.abs(numbers[i] - numbers[i - 1]) <= 1 then
                return false, ([[Студенты с номерами %d и %d
                    имеют номера %d и %d - слишком близкие]])
                    :format(i - 1, i,
                    numbers[i - 1], numbers[i])
            end
        end
        return true
    end
end

add_test('exam', function()
    return 1, examCheck(1, 1)
end)

add_test('exam', function()
    return 2, examCheck(1, 2)
end)

add_test('exam', function()
    return 3, examCheck(2, 3)
end)

add_test('exam', function()
    return 4, examCheck(4, 4)
end)

add_test('exam', function()
    local n = math.random(5, 5000)
    return n, examCheck(n, n)
end)

add_test('path', function()
    return [[5 6
    4 2]], match_number(26)
end)

add_test('path', function()
    return [[10 10
    10 0]], match_number(100)
end)

local function findMaxDistance(v1, v2, t, d)
    local v_1 = math.min(v1, v2)
    local v_2 = math.max(v1, v2)
    if t == 2 then
        assert(v_2 - v_1 <= d)
        return v_1 + v_2
    else
        return v_1 + findMaxDistance(v_1 + d, v_2, t - 1, d)
    end
end

add_test('path', function()
    local v1 = math.random(1, 100)
    local t = math.random(2, 100)
    local d = math.random(0, 10)
    local max_v2 = math.min(100, v1 + (t-1) * d)
    local min_v2 = math.max(1, v1 - (t-1) * d)
    local v2 = math.random(min_v2, max_v2)
    return ([[%d %d
    %d %d]]):format(v1, v2, t, d),
        match_number(findMaxDistance(v1, v2, t, d))
end)

add_test('staircase', function()
    return [[3
    1 3 1]], match_number(2)
end)

add_test('staircase', function()
    return [[1
    5]], match_number(5)
end)

add_test('staircase', function()
    return [[2
    1 7]], match_number(7)
end)

local function solveStaircase(price)
    local ans = {price[1], price[2]}
    for i = 3, #price do
        ans[i] = math.min(ans[i-1], ans[i-2]) + price[i]
    end
    return ans[#price]
end

add_test('staircase', function()
    local n = math.random(1, 100)
    local price = {}
    for i = 1, n do
        table.insert(price, math.random(1, 100))
    end
    local result = solveStaircase(price)
    return ("%d\n%s"):format(n, table.concat(price, ' ')),
        match_number(result)
end)

add_test('staircase2', function()
    return [[9 3
    100 100 4 200 300 6 55 10 1]], match_number(11)
end)

local function solveStaircase2(price, m)
    local binaryheap = require 'binaryheap'
    local h = binaryheap.minUnique()
    h:insert(0, 0)
    for i = 1, #price do
        local removed_step = i - m - 1
        if removed_step >= 0 then
            assert(h:remove(removed_step))
        end
        local min = h:peek()
        h:insert(min + price[i], i)
    end
    local last_pos = h.reverse[#price]
    return h.value[last_pos]
end

add_test('staircase2', function()
    local n = math.random(1000000, 2000000)
    local m = math.random(100000, 200000)
    local price = {}
    for i = 1, n do
        table.insert(price, math.random(1, 100))
    end
    local result = solveStaircase2(price, m)
    return ("%d %d\n%s"):format(n, m,
            table.concat(price, ' ')),
        match_number(result)
end)

add_test('clique', function()
    return [[4
    2 3
    3 1
    6 1
    0 2]], match_number(3)
end)

local function right(x, w, index)
    return x[index] + w[index]
end

local function left(x, w, index)
    return x[index] - w[index]
end

local function solveClique(x, w)
    assert(#x == #w)
    local n = #x
    -- numbers of points
    local numbers = {}
    for i = 1, n do
        table.insert(numbers, i)
    end
    -- sort indices of points by right boundary
    table.sort(numbers, function(i, j)
        return right(x, w, i) < right(x, w, j)
    end)
    -- greedy algorithm
    local ans = 1
    local index = 1
    for i = 2, n do
        if left(x, w, numbers[i]) >=
                right(x, w, numbers[index]) then
            index = i
            ans = ans + 1
        end
    end
    return ans
end

add_test('clique', function()
    local n = math.random(1, 20000)
    local x = {}
    local w = {}
    local as_text = {}
    for i = 1, n do
        local xi = math.random(1, 1000000000)
        local wi = math.random(1, 1000000000)
        table.insert(x, xi)
        table.insert(w, wi)
        table.insert(as_text, ("%d %d"):format(xi, wi))
    end
    local result = solveClique(x, w)
    return ("%d\n%s"):format(n, table.concat(as_text, '\n')),
        match_number(result)
end)

return cw
