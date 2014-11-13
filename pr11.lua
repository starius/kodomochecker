
local sh = require("sh")
local pf = string.format

math.randomseed(os.time())

local map1to3 = require('map1to3')
local translation = require('translation')
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
local ifasta = require('helpers').ifasta
local ofasta = require('helpers').ofasta
local match_fasta = require('helpers').match_fasta
local atgc_rand = require('helpers').atgc_rand

local h = require('helpers')

local pr11 = {}

local add_test = function(name, func)
    local add_test0 = require('helpers').add_test
    add_test0(pr11, name, func)
end

add_test('trigonometry', function()
    local degrees = rr(-10000, 10000) / 10
    local radians = math.rad(degrees)
    return tostring(degrees),
        match_numbers(math.sin(radians), math.cos(radians))
end)

add_test('randomdna',
ofile('output.fasta', ofasta(
function()
    local nseqs = rr(1, 10)
    local min_len = rr(1, 10)
    local max_len = rr(min_len, min_len + 3)
    return pf('%i\n%i\n%i', nseqs, min_len, max_len),
    function(fasta)
        if #fasta.names ~= nseqs then
            return false,
                'Неправильное количество последовательностей'
        end
        for name, seq in pairs(fasta.name2seq) do
            if #seq < min_len then
                return false,
                    'Слишком короткая последовательность' ..
                    name
            end
            if #seq > max_len then
                return false,
                    'Слишком длинная последовательность' ..
                    name
            end
            seq = seq:upper():gsub('[ATGC]', '')
            if seq ~= '' then
                return false,
                    'Мусор в последовательности: ' .. seq
            end
        end
        return true
    end
end)))

add_test('urllib2', function()
    return 'http://google.com\ngoogle',
        match_choice('YES', {'YES', 'NO'})
end)

add_test('urllib2', function()
    return 'http://google.com\nyandex',
        match_choice('NO', {'YES', 'NO'})
end)

local pr10 = require('pr10')
local translation_in_frame = get_tests(pr10,
    'translation-in-frame')[1]
add_test(translation_in_frame)

add_test('fibonacci', function()
    local n = rr(6, 30)
    local ll = {0, 1}
    for i = 2, n do
        local a = ll[#ll]
        local b = ll[#ll - 1]
        table.insert(ll, a + b)
    end
    return tostring(n),
        match_numbers(unPack(ll))
end)

return pr11

