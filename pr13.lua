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
local aminoacid = require('aminoacid')
local aa_charge = require('aa_charge')

local h = require('helpers')

local pr13 = {}

local add_test = function(name, func)
    local add_test0 = require('helpers').add_test
    add_test0(pr13, name, func)
end

local checkpy = require('checkpy')
local itmp = checkpy.tmp_dir() .. '/pr13i-' .. shortrand()

add_test('find-subseqs',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local prot1 = h.new_fasta()
    local n = rr(10, 100)
    local seqs = {}
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq
        if rr(1, 2) == 1 or i < 5 then
            local _, prot_seq = h.orf(rr(15, 30))
            seq = prot_seq:sub(1, -4)
        elseif rr(1, 2) == 1 then
            seq = one_of(unPack(seqs))
        else
            local s1 = one_of(unPack(seqs))
            local s2 = one_of(unPack(seqs))
            seq = s1 .. s2
        end
        prot1:add_seq(name, seq, description)
        table.insert(seqs, seq)
    end
    local prot2 = h.new_fasta()
    for _, name in ipairs(prot1.names) do
        local seq = prot1.name2seq[name]
        local good = true
        for _, seq1 in ipairs(seqs) do
            if seq1:find(seq) and seq1 ~= seq then
                good = false
            end
        end
        if good then
            -- only me
            prot2:add_seq(name, seq, prot1.name2desc[name])
        end
    end
    local argv = itmp
    prot1.cin = argv
    return prot1, match_fasta(prot2), argv, argv
end)))))

add_test('count-hits',
ifile(itmp, ifasta(
function()
    local pattern = atgc_rand(rr(6, 16))
    local dna = h.new_fasta()
    local n = rr(10, 100)
    local result = 0
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq
        if rr(1, 2) == 1 then
            local prefix = atgc_rand(rr(0, 20))
            local suffix = atgc_rand(rr(0, 20))
            seq = prefix .. pattern .. suffix
        else
            seq = atgc_rand(rr(10, 50))
        end
        if seq:find(pattern) then
            result = result + 1
        end
        dna:add_seq(name, seq, description)
    end
    local argv = itmp .. ' ' .. pattern
    dna.cin = argv
    return dna, match_number(result), argv, argv
end)))

add_test('clean-seq',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    local name = shortrand()
    local description = seq_descr()
    local seq1 = {}
    local seq2 = {}
    local length = rr(10, 100)
    for i = 1, length do
        if rr(1, 10) > 1 then
            local nucl = one_of('A', 'T', 'G', 'C', 'N')
            table.insert(seq1, nucl)
            table.insert(seq2, nucl)
        else
            local nucl = one_of('$', '-', '*', '~', ' ')
            table.insert(seq1, nucl)
        end
    end
    dna1:add_seq(name, table.concat(seq1), description)
    dna2:add_seq(name, table.concat(seq2), description)
    local argv = itmp
    dna1.cin = argv
    return dna1, match_fasta(dna2), argv, argv
end)))))

add_test('calc-charge',
ifile(itmp, ifasta(
function()
    local prot = h.new_fasta()
    local name = shortrand()
    local description = seq_descr()
    local seq = {}
    local length = rr(10, 100)
    local total_charge = 0
    for i = 1, length do
        local aa = one_of(unPack(aminoacid.aas))
        local charge = aa_charge[aa] or 0
        total_charge = total_charge + charge
        table.insert(seq, aa)
    end
    prot:add_seq(name, table.concat(seq), description)
    local argv = itmp
    prot.cin = argv
    return prot, match_number(total_charge), argv, argv
end)))

add_test('complement',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    local name = shortrand()
    local description = seq_descr()
    local seq1 = atgc_rand(rr(10, 20))
    local seq2 = h.complement(seq1)
    dna1:add_seq(name, seq1, description)
    dna2:add_seq(name, seq2, description)
    local argv = itmp
    dna1.cin = argv
    return dna1, match_fasta(dna2), argv, argv
end)))))

add_test('count-word',
ifile(itmp, ifasta(
function()
    local pattern = atgc_rand(rr(4, 6))
    local n = rr(0, 5)
    local seq = {}
    table.insert(seq, atgc_rand(rr(5, 10)))
    for i = 1, n do
        table.insert(seq, pattern)
        table.insert(seq, atgc_rand(rr(5, 10)))
    end
    seq = table.concat(seq)
    local result = 0
    for i = 1, #seq - #pattern + 1 do
        local slice = seq:sub(i, i + #pattern - 1)
        if slice == pattern then
            result = result + 1
        end
    end
    local dna = h.new_fasta()
    local name = shortrand()
    local description = seq_descr()
    dna:add_seq(name, seq, description)
    local argv = itmp .. ' ' .. pattern
    dna.cin = argv
    return dna, match_number(result), argv, argv
end)))

add_test('find-most-frequent-word',
ifile(itmp, ifasta(
function()
    local word_length = rr(4, 6)
    local seq = atgc_rand(rr(100, 1000))
    if rr(1, 2) == 1 then
        seq = 'ACAATCGCATGCGCCTAAAGAGATGAGTCATCCTATTG' ..
            'AGCCTTGTCCGATGGTATGGGTCAACGAAC'
    end
    local word2count = {}
    for i = 1, #seq - word_length + 1 do
        local slice = seq:sub(i, i + word_length - 1)
        word2count[slice] = (word2count[slice] or 0) + 1
    end
    local max_count = 0
    for word, count in pairs(word2count) do
        if count > max_count then
            max_count = count
        end
    end
    local result = {}
    for word, count in pairs(word2count) do
        if count == max_count then
            table.insert(result, word .. '\n')
        end
    end
    local dna = h.new_fasta()
    local name = shortrand()
    local description = seq_descr()
    dna:add_seq(name, seq, description)
    local argv = itmp .. ' ' .. word_length
    dna.cin = argv
    return dna, match_strs_no_order(unPack(result)), argv, argv
end)))

add_test('delete-matching',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    local pattern = atgc_rand(rr(10, 20))
    local n = rr(10, 15)
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq
        if rr(1, 2) == 1 then
            local prefix = atgc_rand(rr(0, 20))
            local suffix = atgc_rand(rr(0, 20))
            seq = prefix .. pattern .. suffix
        else
            seq = atgc_rand(rr(40, 50))
        end
        dna1:add_seq(name, seq, description)
        if not seq:find(pattern) then
            dna2:add_seq(name, seq, description)
        end
    end
    local argv = itmp .. ' ' .. pattern
    dna1.cin = argv
    return dna1, match_fasta(dna2), argv, argv
end)))))

add_test('per-seq-gc',
ifile(itmp, ifasta(
function()
    local dna1 = h.new_fasta()
    local n = rr(10, 15)
    local result = {}
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq = atgc_rand(rr(10, 15))
        dna1:add_seq(name, seq, description)
        local gc_only = seq:gsub('[AT]', '')
        local gc = #gc_only / #seq
        table.insert(result, gc)
    end
    local argv = itmp
    dna1.cin = argv
    return dna1, match_numbers(unPack(result)), argv, argv
end)))

add_test('per-seq-matching',
ifile(itmp, ifasta(
function()
    local pattern = atgc_rand(rr(10, 20))
    local dna1 = h.new_fasta()
    local n = rr(5, 10)
    local result = {}
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq
        if rr(1, 2) == 1 then
            seq = atgc_rand(rr(1, 50)) .. pattern .. atgc_rand(rr(1, 50))
        else
            seq = atgc_rand(rr(10, 100))
        end
        dna1:add_seq(name, seq, description)
        local yesno = seq:find(pattern, 1, true) and 'yes' or 'no'
        table.insert(result, name)
        table.insert(result, yesno)
    end
    local argv = itmp .. ' ' .. pattern
    dna1.cin = argv
    return dna1, match_strs(unPack(result)), argv, argv
end)))

add_test('filter-long',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    local min_protein = rr(20, 40)
    local n = rr(5, 10)
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq
        if rr(1, 2) == 1 then
            seq = h.orf(rr(min_protein, min_protein * 2))
            dna2:add_seq(name, seq, description)
        else
            seq = h.orf(rr(min_protein - 10, min_protein - 1))
        end
        dna1:add_seq(name, seq, description)
    end
    local argv = itmp .. ' ' .. min_protein
    dna1.cin = argv
    return dna1, match_fasta(dna2), argv, argv
end)))))

add_test('count-atgc',
ifile(itmp, ifasta(
function()
    local dna1 = h.new_fasta()
    local atgc = {A = 0, T = 0, G = 0, C = 0}
    local name = shortrand()
    local seq = atgc_rand(rr(4, 40))
    for j = 1, #seq do
        local letter = seq:sub(j, j)
        atgc[letter] = atgc[letter] + 1
    end
    dna1:add_seq(name, seq)
    local argv = itmp
    dna1.cin = argv
    return dna1,
        match_numbers_no_order(atgc.A, atgc.T, atgc.G, atgc.C),
        argv, argv
end)))

add_test('max-minus-min',
ifile(itmp, ifasta(
function()
    local dna1 = h.new_fasta()
    local n = rr(5, 10)
    local MAX = 30
    local MIN = 10
    local min = MAX
    local max = MIN
    for i = 1, n do
        local name = shortrand() .. i
        local l = rr(MIN, MAX)
        min = math.min(min, l)
        max = math.max(max, l)
        local seq = atgc_rand(l)
        dna1:add_seq(name, seq)
    end
    local argv = itmp
    dna1.cin = argv
    return dna1, match_number(max - min), argv, argv
end)))

return pr13

