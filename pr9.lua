
local sh = require("sh")
local pf = string.format

math.randomseed(os.time())

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
local match_choice = require('helpers').match_choice
local bool_wrapper = require('helpers').bool_wrapper
local one_of = require('helpers').one_of
local unPack = require('helpers').unPack
local copy_list = require('helpers').copy_list
local read_file = require('helpers').read_file
local add_test = require('helpers').add_test
local get_tests = require('helpers').get_tests

local kurs1 = require('kurs1')

local tr_abc = function(a, b, c)
    local abc = {a, b, c}
    abc = shuffle(abc)
    a, b, c = unPack(abc)
    return pf('%f\n%f\n%f', a, b, c)
end

local tr_xyz = function(...)
    local abc = {...}
    ax,ay,bx,by,cx,cy = unPack(abc)
    return pf('%f %f\n%f %f\n%f %f', ax,ay,bx,by,cx,cy)
end

local tr_choices = {'degenerate', 'right', 'acute', 'obtuse'}

local pr9 = {

{'nucleobase', {
function()
    local nucleobase = one_of('A', 'T', 'G', 'C')
    local pp = {A = 'purine', G = 'purine',
                T = 'pyrimidine', C = 'pyrimidine'}
    return nucleobase, match_str(pp[nucleobase])
end}},

{'average', {
function()
    local ll_size = rr(1, 200)
    local ll = {}
    local sum = 0
    for i = 1, ll_size do
        local v = rr(-1000, 1000)
        table.insert(ll, tostring(v))
        sum = sum + v
    end
    local ll_str = table.concat(ll, ' ')
    local ll_avg = sum / ll_size
    return ll_str, match_number(ll_avg)
end}},

{'double-lunch', {
function()
    local ll_size = rr(1, 50)
    local ll = {}
    local seen = {}
    local double_seen = {}
    local double_seen_set = {}
    for i = 1, ll_size do
        local v = rr(1, 400)
        table.insert(ll, tostring(v))
        if seen[v] and not double_seen_set[v] then
            table.insert(double_seen, v)
            double_seen_set[v] = true
        end
        seen[v] = true
    end
    table.insert(ll, 'STOP')
    local ll_str = table.concat(ll, '\n')
    return ll_str, match_numbers_no_order(unPack(double_seen))
end}},

{'director-lunch', {
function()
    local ll_size = rr(10, 50)
    local ll = {}
    for i = 1, ll_size do
        local v = rr(3, 10)
        table.insert(ll, tostring(v))
    end
    local director = rr(0, 1)
    local booker = rr(0, 1)
    if director == 1 then
        local i = rr(1, #ll)
        table.insert(ll, i, 1)
    end
    if booker == 1 then
        local i = rr(1, #ll)
        table.insert(ll, i, 2)
    end
    local director_or_booker = math.min(director + booker, 1)
    local director_and_booker = director * booker
    local ll_str = table.concat(ll, ' ')
    return ll_str, bool_wrapper(
        match_numbers_no_order(
        director, booker,
        director_or_booker, director_and_booker))
end}},

{'all-lunch', {
function()
    local ll_size = rr(1, 5)
    local ll = {}
    for i = 1, ll_size do
        local v = shortrand()
        table.insert(ll, v)
    end
    local ll2 = copy_list(ll)
    ll2[#ll2] = 'Vasya'
    table.remove(ll2, 1)
    table.insert(ll2, 'and me')
    local ll_str = table.concat(ll, ', ')
    local ll2_str = table.concat(ll2, ', ')
    return ll_str, match_str(ll2_str)
end}},

{'menu', {
function()
    local ll_size = rr(1, 5)
    local ll = {}
    local ll2 = {}
    for i = 1, ll_size do
        local v = shortrand()
        table.insert(ll, v)
        table.insert(ll2, tostring(i))
        table.insert(ll2, v)
    end
    local ll_str = table.concat(ll, ', ')
    return ll_str, match_strs(unPack(ll2))
end}},

{'kurs1', {
function()
    local group = rr(1, 2)
    if group == 1 then
        return one_of(unPack(kurs1.group1)),
            match_numbers(101)
    else
        return one_of(unPack(kurs1.group2)),
            match_numbers(102)
    end
end}},

{'triangle', {

function()
    local a = rr(1, 20)
    local b = rr(1, 20)
    local c = a + b
    return tr_abc(a, b, c),
        match_choice('degenerate', tr_choices)
end,

function()
    -- https://en.wikipedia.org/wiki/Pythagorean_triple#Generating_a_triple
    local n = rr(1, 1000)
    local m = n + rr(1, 1000)
    local a = m^2 - n^2
    local b = 2 * m * n
    local c = m^2 + n^2
    return tr_abc(a, b, c),
        match_choice('right', tr_choices)
end,

function()
    local a = rr(1, 100)
    local b = rr(1, 100)
    local hyp = (a^2 + b^2) ^ 0.5
    local a_plus_b = a + b
    local c = (a_plus_b + hyp) / 2
    return tr_abc(a, b, c),
        match_choice('obtuse', tr_choices)
end,

function()
    local a = rr(1, 100)
    local b = rr(1, 100)
    local hyp = (a^2 + b^2) ^ 0.5
    local a_max_b = math.max(a, b)
    local c = (a_max_b + hyp) / 2
    return tr_abc(a, b, c),
        match_choice('acute', tr_choices)
end,

}},


{'prime', {

function()
    local prime = one_of(unPack(require('primes')))
    return tostring(prime), match_choice('YES', {'YES', 'NO'})
end,

function()
    local a = one_of(unPack(require('primes')))
    local b = one_of(unPack(require('primes')))
    return tostring(a * b), match_choice('NO', {'YES', 'NO'})
end,

function()
    return '1', match_choice('NO', {'YES', 'NO'})
end,

}},

{'cubes', {
function()
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
        add_if(k == 1)
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
end,

function()
    local task = pf('%i\n%i\n%i', 1, 1, 1)
    return task, match_numbers(6, 1)
end,
}},

{'cubes2', {
function()
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
end,

function()
    local task = pf('%i\n%i\n%i', 1, 1, 1)
    return task, match_numbers(5, 1)
end,
}},

{'triangle2', {
function()
    local ax = rr(1, 20)
    local ay = rr(1, 20)
    local bx = rr(1, 20)
    local by = rr(1, 20)
    local diffx = bx - ax
    local diffy = by - ay
    local f = rr(1, 5)
    local cx = bx + f * diffx
    local cy = by + f * diffy
    return tr_xyz(ax,ay,bx,by,cx,cy),
        match_choice('degenerate', tr_choices)
end,

function()
    local ax = rr(1, 20)
    local ay = rr(1, 20)
    local bx = rr(1, 20)
    local by = rr(1, 20)
    local diffx = bx - ax
    local diffy = by - ay
    local f = rr(1, 5)
    local cx = bx + f * diffy
    local cy = by - f * diffx
    return tr_xyz(ax,ay,bx,by,cx,cy),
        match_choice('right', tr_choices)
end,

function()
    local ax = rr(1, 20)
    local ay = rr(1, 20)
    local bx = rr(1, 20)
    local by = rr(1, 20)
    local midx = (bx + ax) / 2
    local midy = (by + ay) / 2
    local diffx = bx - ax
    local diffy = by - ay
    local f = rr(5, 10)
    local cx = midx + f * diffy
    local cy = midy - f * diffx
    return tr_xyz(ax,ay,bx,by,cx,cy),
        match_choice('acute', tr_choices)
end,

function()
    local ax = rr(1, 20)
    local ay = rr(1, 20)
    local bx = rr(1, 20)
    local by = rr(1, 20)
    local midx = (bx + ax) / 2
    local midy = (by + ay) / 2
    local diffx = bx - ax
    local diffy = by - ay
    local f = rr(5, 10) / 100
    local cx = midx + f * diffy
    local cy = midy - f * diffx
    return tr_xyz(ax,ay,bx,by,cx,cy),
        match_choice('obtuse', tr_choices)
end,

}},

{'gc', {
function()
    os.execute('rm input.fasta')
    local f = io.open('input.fasta', 'w')
    local seqs_n = rr(1, 3)
    local gc = 0
    local all_bp = 0
    local GC_score = {G = 1, C = 1, A = 0, T = 0,
        N = 0, ['-'] = 0}
    local ALL_score = {G = 1, C = 1, A = 1, T = 1,
        N = 0, ['-'] = 0}
    for i = 1, seqs_n do
        f:write(pf('>test%i\n', i))
        local lines_n = rr(1, 10)
        for j = 1, lines_n do
            for k = 1, 60 do
                local letter = one_of('A', 'T', 'G', 'C',
                    '-', 'N')
                f:write(letter)
                if i == 1 then
                    gc = gc + GC_score[letter]
                    all_bp = all_bp + ALL_score[letter]
                end
            end
            f:write('\n')
        end
    end
    f:close('\n')
    local gc_perc = math.floor(gc / all_bp * 100 + 0.5)
    return read_file('input.fasta'), match_numbers(gc_perc)
end}},

{'articles', {
function()
    local jorn_start = rr(1900, 2000)
    local doc_start = rr(1900, 2000)
    local doc_stop = doc_start + rr(0, 50)
    local result = 0
    for i = doc_start, doc_stop, 2 do
        if i > jorn_start and i < doc_stop then
            result = result + 1
        end
    end
    return pf('%i\n%i\n%i', jorn_start, doc_start, doc_stop),
        match_numbers(result)
end}},

{'sqrt', {
function()
    local result = rr(1, 50)
    local input = result ^ 2
    return pf('%i', input), match_number(result)
end,

function()
    local input = rr(-100, -5)
    return pf('%i', input), match_str('Error')
end,
}},

{'median', {
function()
    -- odd
    local ll_size = 1 + 2 * rr(0, 10)
    local last = 0
    local ll = {}
    for i = 1, ll_size do
        local v = last + rr(0, 2)
        table.insert(ll, v)
        last = v
    end
    local middle = (ll_size + 1) / 2
    local result = ll[middle]
    ll = shuffle(ll)
    local input = table.concat(ll, '\n')
    return input, match_number(result)
end,

function()
    -- even
    local ll_size = 2 * rr(1, 10)
    local last = 0
    local ll = {}
    for i = 1, ll_size do
        local v = last + rr(0, 2)
        table.insert(ll, v)
        last = v
    end
    local middle1 = ll_size / 2
    local middle2 = middle1 + 1
    local result = (ll[middle1] + ll[middle2]) / 2
    ll = shuffle(ll)
    local input = table.concat(ll, '\n')
    return input, match_number(result)
end,
}},

{'median2', {
function()
    -- odd
    local ll_size = 1 + 2 * rr(0, 10)
    local last = 0
    local ll = {}
    for i = 1, ll_size do
        local v = last + rr(0, 2)
        table.insert(ll, v)
        last = v
    end
    local middle = (ll_size + 1) / 2
    local result = ll[middle]
    local input = table.concat(ll, '\n')
    return ll_size .. '\n' .. input, match_number(result)
end,

function()
    -- even
    local ll_size = 2 * rr(1, 10)
    local last = 0
    local ll = {}
    for i = 1, ll_size do
        local v = last + rr(0, 2)
        table.insert(ll, v)
        last = v
    end
    local middle1 = ll_size / 2
    local middle2 = middle1 + 1
    local result = (ll[middle1] + ll[middle2]) / 2
    local input = table.concat(ll, '\n')
    return ll_size .. '\n' .. input, match_number(result)
end,
}},

{'nucleobase2', {
function()
    local nucleobase = one_of('A', 'T', 'G', 'C', 'U')
    local pp = {A = 'purine', G = 'purine',
                T = 'pyrimidine', C = 'pyrimidine', U = 'pyrimidine'}
    return nucleobase, match_str(pp[nucleobase])
end}},

}

local aas = require('aminoacid').aas
local aa2props = require('aminoacid').aa2props
for _, aa in ipairs(aas) do
    add_test(pr9, 'aminoacid', function()
        return aa, match_strs(aas.aa2props[aa])
    end)
end

table.insert(pr9, {'all-lunch2', get_tests(pr9, 'all-lunch')})

return pr9

