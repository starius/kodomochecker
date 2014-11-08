
local sh = require("sh")
local pf = string.format

math.randomseed(os.time())

local map1to3 = require('map1to3')
local shortrand = require('helpers').shortrand
local shuffle = require('helpers').shuffle
local rr = math.random
local genname = require('helpers').genname
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
local atgc_rand = require('helpers').atgc_rand

local pr10 = {}

local add_test = function(name, func)
    local add_test0 = require('helpers').add_test
    add_test0(pr10, name, func)
end

local all_aaa = {}
local all_a = {}

for a, aaa in pairs(map1to3) do
    table.insert(all_aaa, aaa)
    table.insert(all_a, a)
end

-- one2three
for a, aaa in pairs(map1to3) do
    add_test('one2three', function()
        return a:lower(), match_choice(aaa, all_aaa)
    end)
    add_test('one2three', function()
        return a:upper(), match_choice(aaa, all_aaa)
    end)
end

-- three-and-one
for a, aaa in pairs(map1to3) do
    add_test('three-and-one', function()
        return a:upper(), match_choice(aaa, all_aaa)
    end)
    add_test('three-and-one', function()
        return aaa, match_choice(a, all_a)
    end)
end

-- quadrants
add_test('quadrants', ifile('input.txt', ofile('output.txt',
function()
    local n = rr(10, 50)
    local points = {}
    local results = {}
    for i = 1, n do
        local r = one_of('0', '1', '2', '3', '4', 'OX', 'OY')
        table.insert(results, r)
        local x, y
        if r == '0' then
            x = 0
            y = 0
        elseif r == '1' then
            x = 5.5 + rr(1, 10)
            y = 5.5 + rr(1, 10)
        elseif r == '2' then
            x = -5.5 - rr(1, 10)
            y = 5.5 + rr(1, 10)
        elseif r == '3' then
            x = -5.5 - rr(1, 10)
            y = -5.5 - rr(1, 10)
        elseif r == '4' then
            x = 5.5 + rr(1, 10)
            y = -5.5 - rr(1, 10)
        elseif r == 'OX' then
            x = 5.5 + rr(1, 10)
            y = 0
        elseif r == 'OY' then
            x = 0
            y = 5.5 + rr(1, 10)
        end
        local point
        if rr(1, 2) == 1 then
            point = pf('%i %i', x, y)
        else
            point = pf('%f %f', x, y)
        end
        table.insert(points, point)
    end
    return table.concat(points, '\n'),
        match_strs(unPack(results))
end)))

-- sequences
add_test('sequences', ifile('input.fasta',
function()
    local n = rr(1, 10)
    local lines = {}
    local results = {}
    for i = 1, n do
        local name = shortrand()
        local description = ''
        if rr(1, 2) == 1 then
            description = ' ' .. shortrand()
        end
        if rr(1, 2) == 1 then
            description = description .. ' ' .. shortrand()
        end
        local line = '>' .. name .. description
        table.insert(lines, line)
        table.insert(results, name)
        local seq_lines = rr(1, 5)
        for j = 1, seq_lines do
            local length = 60
            if j == seq_lines then
                length = rr(20, 55)
            end
            local line = atgc_rand(length)
            table.insert(lines, line)
        end
    end
    return table.concat(lines, '\n'),
        match_strs_no_order(unPack(results))
end))

-- sequence-len
add_test('sequence-len', ifile('input.fasta',
function()
    local n = rr(1, 10)
    local lines = {}
    local results = {}
    for i = 1, n do
        local name = shortrand()
        local description = ''
        if rr(1, 2) == 1 then
            description = ' ' .. shortrand()
        end
        if rr(1, 2) == 1 then
            description = description .. ' ' .. shortrand()
        end
        local line = '>' .. name .. description
        table.insert(lines, line)
        local total_length = 0
        local seq_lines = rr(1, 5)
        for j = 1, seq_lines do
            local length = 60
            if j == seq_lines then
                length = rr(20, 55)
            end
            local line = atgc_rand(length)
            table.insert(lines, line)
            total_length = total_length + length
        end
        table.insert(results, name)
        table.insert(results, tostring(total_length))
    end
    return table.concat(lines, '\n'),
        match_strs(unPack(results))
end))

-- circles
add_test('circles', function()
    local n = rr(1, 20)
    local result = math.pi * (n * (n + 1) / 2 - n / 4)
    return
    tostring(n),
    match_number(result)
end)

return pr10

