
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
        local name = shortrand() .. i
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
        local name = shortrand() .. i
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

local seq_descr = function()
    local d = {}
    local n = rr(0, 5)
    for i = 1, n do
        table.insert(d, shortrand())
    end
    return table.concat(d, ' ')
end

-- translation
add_test('translation',
ifile('input.fasta', ifasta(
ofile('output.fasta', ofasta(
function()
    local n = rr(1, 10)
    local dna = h.new_fasta()
    local protein = h.new_fasta()
    for i = 1, n do
        local dna_name = shortrand() .. i
        local protein_name = dna_name .. '_protein'
        local description = seq_descr()
        local triplets = rr(1, 100)
        local dna_seq = ''
        local protein_seq = ''
        for j = 1, triplets do
            local triplet = atgc_rand(3)
            local aa = translation[triplet]
            dna_seq = dna_seq .. triplet
            protein_seq = protein_seq .. aa
        end
        dna.name2seq[dna_name] = dna_seq
        dna.name2desc[dna_name] = description
        protein.name2seq[protein_name] = protein_seq
        protein.name2desc[protein_name] = description
        table.insert(dna.names, dna_name)
        table.insert(protein.names, protein_name)
    end
    return dna, match_fasta(protein)
end)))))

-- translation-in-frame
add_test('translation-in-frame',
ifile('input.fasta', ifasta(
ofile('output.fasta', ofasta(
function()
    local frame = rr(0, 2)
    local min_length = rr(20, 100)
    local n = rr(1, 10)
    local dna = h.new_fasta()
    dna.cin = frame .. ' ' .. min_length
    local protein = h.new_fasta()
    for i = 1, n do
        local dna_name = shortrand() .. i
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
    end
    return dna, match_fasta(protein)
end)))))

local itmp = os.tmpname()
local otmp = os.tmpname()

-- filter-palindrome
add_test('filter-palindrome',
ifile(itmp, ifasta(
ofile(otmp, ofasta(
function()
    local n = rr(1, 10)
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    dna2.names = nil -- unordered
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq = atgc_rand(rr(1, 30))
        local complement = h.complement(seq)
        if rr(1, 2) == 1 then
            -- palindrome
            seq = seq .. complement
            dna2.name2seq[name] = seq
            dna2.name2desc[name] = description
        else
            -- non palindrome
            seq = seq .. h.mutate(complement)
        end
        dna1.name2seq[name] = seq
        dna1.name2desc[name] = description
        table.insert(dna1.names, name)
    end
    dna1.cin = itmp .. '\n' .. otmp
    return dna1, match_fasta(dna2)
end)))))

-- circles
add_test('circles', function()
    local n = rr(1, 20)
    local result = math.pi * (n * (n + 1) / 2 - n / 4)
    return
    tostring(n),
    match_number(result)
end)

-- find-orfs
add_test('find-orfs',
ifile(itmp, ifasta(
ofile(otmp, ofasta(
function()
    local n = rr(1, 10)
    local target = rr(1, n)
    local target_name = shortrand() .. target
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    dna2.names = nil
    local min_dna_length = 60
    local add_orfs = function(seq)
        local add_orf
        local find_orfs = function()
            for i = 1, #seq - 2 do
                if seq:sub(i, i + 2) == 'ATG' then
                    local stop = i + 3
                    local last
                    while stop + 2 <= #seq do
                        local triplet = seq:sub(stop, stop + 2)
                        if translation[triplet] == '*' then
                            last = stop + 2
                            break
                        else
                            stop = stop + 3
                        end
                    end
                    if last and last - i + 1 >=
                            min_dna_length then
                        add_orf(i, last)
                    end
                end
            end
        end
        add_orf = function(first, last)
            local name = ('orf_%i_%i'):format(first, last)
            dna2.name2seq[name] = seq:sub(first, last)
            dna2.name2desc[name] = ''
        end
        find_orfs()
        seq = h.complement(seq)
        add_orf = function(first, last)
            local first1 = #seq - first + 1
            local last1 = #seq - last + 1
            local name = ('orf_%i_%i'):format(first1, last1)
            dna2.name2seq[name] = seq:sub(first, last)
            dna2.name2desc[name] = ''
        end
    end
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq = atgc_rand(rr(1000, 10000))
        if i == target then
            name = target_name
            add_orfs(seq)
        end
        dna1.name2seq[name] = seq
        dna1.name2desc[name] = description
        table.insert(dna1.names, name)
    end
    dna1.cin = itmp .. '\n' .. target_name .. '\n' .. otmp
    return dna1, match_fasta(dna2)
end)))))

return pr10

