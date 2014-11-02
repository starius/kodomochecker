
local sh = require("sh")
local pf = string.format

math.randomseed(os.time())

local shortrand = require('helpers').shortrand
local rr = math.random
local genname = require('helpers').genname
local find_number = require('helpers').find_number
local match_number = require('helpers').match_number
local match_numbers = require('helpers').match_numbers
local match_numbers_no_order =
    require('helpers').match_numbers_no_order
local match_str = require('helpers').match_str
local match_strs = require('helpers').match_strs
local bool_wrapper = require('helpers').bool_wrapper
local one_of = require('helpers').one_of
local unPack = require('helpers').unPack
local copy_list = require('helpers').copy_list

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

}

return pr9

