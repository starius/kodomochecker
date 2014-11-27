
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
local seq_descr = require('helpers').seq_descr

local h = require('helpers')

local pr11 = {}

local add_test = function(name, func)
    local add_test0 = require('helpers').add_test
    add_test0(pr11, name, func)
end

add_test('trigonometry', function()
    local degrees = rr(-10000, 10000) / 10
    local radians = math.rad(degrees)
    return '',
        match_numbers(math.sin(radians), math.cos(radians)),
        tostring(degrees), tostring(degrees)
end)

add_test('randomdna',
ofile('output.fasta', ofasta(
function()
    local nseqs = rr(1, 10)
    local min_len = rr(1, 10)
    local max_len = rr(min_len, min_len + 3)
    local input = pf('%i %i %i', nseqs, min_len, max_len)
    return '',
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
    end, input, input
end)))

add_test('urllib2', function()
    local input = 'http://google.com google'
    return '', match_choice('YES', {'YES', 'NO'}),
        input, input
end)

add_test('urllib2', function()
    local input = 'http://google.com yandex'
    return '', match_choice('NO', {'YES', 'NO'}),
        input, input
end)

local itmp, itmp_d = h.tmp_file_and_deleter()
pr11.itmp_d = itmp_d
local otmp, otmp_d = h.tmp_file_and_deleter()
pr11.otmp_d = otmp_d

-- translation-in-frame
add_test('translation-in-frame-argv',
ifile(itmp, ifasta(
ofile(otmp, ofasta(
function()
    local frame = rr(0, 2)
    local min_length = rr(20, 100)
    local n = rr(1, 10)
    local dna = h.new_fasta()
    local protein = h.new_fasta()
    local dna_name = shortrand()
    local protein_name_base = dna_name .. '_protein_'
    local description = seq_descr()
    local dna_seq = ''
    local add_dna = function(t)
        dna_seq = dna_seq .. t
    end
    -- add junk to shift to target frame
    add_dna(atgc_rand(frame))
    local i = 1
    while true do
        local state = rr(1, 14)
        -- states:
        -- 1-10 - junk triplets
        -- 12 - long ORF
        -- 13 - short ORF
        -- 14 - broken ORF
        if state <= 10 then
            add_dna(h.junk_triplets(rr(5, 100)))
        elseif state == 12 then
            local l = rr(min_length, min_length * 2)
            local dna, aaa = h.orf(l, true)
            add_dna(dna)
            --
            local protein_name = protein_name_base .. i
            protein.name2seq[protein_name] = aaa
            protein.name2desc[protein_name] = ''
            table.insert(protein.names, protein_name)
            i = i + 1
        elseif state == 13 then
            local l = rr(1, min_length - 1)
            local dna, aaa = h.orf(l, true)
            add_dna(dna)
        elseif state == 14 then
            local l = rr(min_length, min_length * 2)
            local dna, aaa = h.orf(l, true)
            dna = dna:sub(1, #dna - rr(1, 3))
            add_dna(dna)
            break
        end
    end
    dna.name2seq[dna_name] = dna_seq
    dna.name2desc[dna_name] = description
    table.insert(dna.names, dna_name)
    local argv = itmp .. ' ' .. frame .. ' ' .. min_length ..
        ' ' .. otmp
    dna.cin = argv
    return dna, match_fasta(protein), argv, argv
end)))))

add_test('fibonacci', function()
    local n = rr(6, 30)
    local ll = {0, 1}
    for i = 2, n do
        local a = ll[#ll]
        local b = ll[#ll - 1]
        table.insert(ll, a + b)
    end
    return '', match_numbers(unPack(ll)),
        tostring(n), tostring(n)
end)

add_test('find-selfcomplement',
ifile(itmp, ifasta(
ofile(otmp, ofasta(
function()
    local min_length = 4
    local n = rr(1, 10)
    local target = rr(1, n)
    local target_name = shortrand() .. target
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    dna2.names = nil
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local big_palindromes = rr(0, 5)
        local parts = {}
        table.insert(parts, atgc_rand(rr(0, 100)))
        for k = 1, big_palindromes do
            table.insert(parts, atgc_rand(rr(0, 100)))
            table.insert(parts, h.make_palindrome(rr(2, 50)))
            table.insert(parts, atgc_rand(rr(0, 100)))
        end
        local seq = table.concat(parts)
        if i == target then
            name = target_name
            local pp = h.find_palindromes(seq, min_length)
            for j, p in ipairs(pp) do
                local name2 = shortrand() .. j
                dna2.name2seq[name2] = p
            end
        end
        dna1.name2seq[name] = seq
        dna1.name2desc[name] = description
        table.insert(dna1.names, name)
    end
    local argv = itmp .. ' ' .. target_name .. ' ' .. otmp
    dna1.cin = argv
    return dna1, h.match_fasta_no_names(dna2), '', argv
end)))))

return pr11

