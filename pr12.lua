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

local pr12 = {}

local add_test = function(name, func)
    local add_test0 = require('helpers').add_test
    add_test0(pr12, name, func)
end


local itmp = os.tmpname()
local itmp2 = os.tmpname()
local otmp = os.tmpname()

add_test('find-orfs-in-frame',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local frame = rr(0, 2)
    local min_length = rr(20, 100)
    local n = rr(1, 10)
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    local dna1_name = shortrand()
    local dna2_name_base = dna1_name .. '_'
    local description = seq_descr()
    local dna1_seq = ''
    local add_dna = function(t)
        dna1_seq = dna1_seq .. t
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
            local dna2_name = dna2_name_base .. i
            dna2:add_seq(dna2_name, dna, '')
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
    dna1:add_seq(dna1_name, dna1_seq, description)
    local argv = itmp .. ' ' .. frame .. ' ' .. min_length
    dna1.cin = argv
    return dna1, match_fasta(dna2), argv, argv
end)))))

add_test('find-fixed-palindromes',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local half_length = rr(2, 10)
    local length = half_length * 2
    local dna = h.new_fasta()
    local dna2 = h.new_fasta()
    local dna_name = shortrand()
    local description = seq_descr()
    local dna_seq = ''
    local add_dna = function(t)
        dna_seq = dna_seq .. t
    end
    local groups = rr(1, 10)
    for i = 1, groups do
        local l = half_length + rr(-1, 1)
        add_dna(atgc_rand(rr(0, 100))) -- junk
        add_dna(h.make_palindrome(l))
        add_dna(atgc_rand(rr(0, 100))) -- junk
    end
    -- find palindromes
    local j = 1
    for i = 1, #dna_seq - length + 1 do
        local slice = dna_seq:sub(i, i + length - 1)
        if h.is_palindrome(slice) then
            local name = 'pal_' .. j
            dna2:add_seq(name, slice)
            j = j + 1
        end
    end
    dna:add_seq(dna_name, dna_seq, description)
    local argv = itmp .. ' ' .. length
    dna.cin = argv
    return dna, match_fasta(dna2), argv, argv
end)))))

add_test('filter-palindromes',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
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
    local argv = itmp
    dna1.cin = argv
    return dna1, match_fasta(dna2), argv, argv
end)))))

add_test('count-stop-codones',
ifile(itmp, ifasta(
function()
    local dna = h.new_fasta()
    local n = rr(10, 100)
    local stops = {}
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq = h.orf(rr(50, 100), true)
        local stop = seq:sub(-3, -1)
        stops[stop] = (stops[stop] or 0) + 1
        dna:add_seq(name, seq, description)
    end
    local stops_numbers = {
        (stops.TGA or 0),
        (stops.TAA or 0),
        (stops.TAG or 0),
    }
    local argv = itmp
    dna.cin = argv
    return dna,
        match_numbers(unPack(stops_numbers)),
        argv, argv
end)))

add_test('filter-orfs',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local n = rr(1, 10)
    local min_length_protein = rr(20, 60)
    local min_length_dna = min_length_protein * 3 + 3
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq, is_orf
        local choice = rr(1, 5)
        local l = min_length_protein
        if choice == 1 then
            seq = h.orf(rr(l, l * 2))
            is_orf = true
        end
        if choice == 2 then
            seq = h.orf(rr(5, l - 1))
        end
        if choice == 3 then
            local seq1 = h.orf(rr(l, l * 2))
            local seq2 = h.orf(rr(l, l * 2))
            seq = seq1 .. seq2
        end
        if choice == 4 then
            local seq1 = h.orf(rr(l, l * 2))
            local seq2 = atgc_rand(3 * rr(5, 10))
            seq = seq1 .. seq2
        end
        if choice == 5 then
            local seq2 = h.orf(rr(l, l * 2))
            local seq1 = atgc_rand(3 * rr(5, 10))
            seq = seq1 .. seq2
        end
        assert(seq)
        dna1:add_seq(name, seq, description)
        if is_orf then
            dna2:add_seq(name, seq, description)
        end
    end
    local argv = itmp
    dna1.cin = argv
    return dna1, match_fasta(dna2), argv, argv
end)))))

add_test('dna-consensus',
ifile(itmp, ifasta(
ofile('consensus.fasta', ofasta(
function()
    local prot_l = rr(20, 140)
    local dna_l = prot_l * 3 + 3
    local base_dna = h.orf(prot_l)
    local n = rr(5, 10)
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq = h.mutate_n(base_dna, dna_l / 10)
        dna1:add_seq(name, seq, description)
    end
    local consensus = dna1:consensus_dna()
    dna2:add_seq('consensus', consensus)
    local argv = itmp
    dna1.cin = argv
    return dna1, match_fasta(dna2), argv, argv
end)))))

add_test('protein-consensus',
ifile(itmp, ifasta(
ofile('consensus.fasta', ofasta(
function()
    local prot_l = rr(20, 140)
    local dna_l = prot_l * 3 + 3
    local _, base_prot = h.orf(prot_l)
    base_prot = base_prot:sub(1, -2) -- remove *
    local n = rr(5, 10)
    local prot1 = h.new_fasta()
    local prot2 = h.new_fasta()
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local seq = h.mutate_n(base_prot, prot_l / 10)
        prot1:add_seq(name, seq, description)
    end
    local consensus = prot1:consensus_protein()
    prot2:add_seq('consensus', consensus)
    local argv = itmp
    prot1.cin = argv
    return prot1, match_fasta(prot2), argv, argv
end)))))

add_test('reorigin',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    local name = shortrand()
    local description = seq_descr()
    local seq1 = atgc_rand(rr(100, 1000))
    local shift = rr(0, #seq1 - 1)
    local part1 = seq1:sub(shift + 1)
    local part2 = seq1:sub(1, shift)
    local seq2 = part1 .. part2
    dna1:add_seq(name, seq1, description)
    dna2:add_seq(name, seq2, description)
    local argv = itmp .. ' ' .. shift
    dna1.cin = argv
    return dna1, match_fasta(dna2), argv, argv
end)))))

add_test('translation-cmp',
ifile(itmp, ifasta(
function()
    local dna = h.new_fasta()
    local seq1 = h.orf(rr(20, 40))
    local seq2 = h.mutate_n(seq1, rr(1, 2))
    if rr(1, 3) == 1 then
        seq2 = seq1
    end
    local prot1 = h.translate(seq1)
    local prot2 = h.translate(seq2)
    local result = (prot1 == prot2) and 'YES' or 'NO'
    dna:add_seq('seq1', seq1)
    dna:add_seq('seq2', seq2)
    local argv = itmp
    dna.cin = argv
    return dna,
        match_choice(result, {'YES', 'NO'}),
        argv, argv
end)))

add_test('find-matrix',
ifile(itmp, ifasta(
function()
    local prot_l = rr(20, 40)
    local dna_l = prot_l * 3 + 3
    local base_dna, base_prot = h.orf(prot_l)
    local n = rr(5, 10)
    local target = rr(1, n)
    local target_name = shortrand() .. target
    local dna = h.new_fasta()
    local prot = h.new_fasta()
    local names = {}
    for i = 1, n do
        local name = shortrand() .. i
        local seq = base_dna
        if i == target then
            name = target_name
        else
            while h.translate(seq) == base_prot do
                seq = h.mutate(seq)
            end
        end
        local description = seq_descr()
        dna:add_seq(name, seq, description)
        table.insert(names, name)
    end
    prot:add_seq('protein', base_prot)
    h.write_file(itmp2, h.write_fasta(prot))
    local argv = itmp .. ' ' .. itmp2
    dna.cin = argv .. '\n\n' .. h.write_fasta(prot)
    return dna, match_choice(target_name, names), argv, argv
end)))

add_test('translate-orf',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local dna = h.new_fasta()
    local prot = h.new_fasta()
    local n = rr(1, 3)
    local prot_l = rr(20, 40)
    local dna_seq
    for i = n, 1, -1 do
        if not dna_seq then
            dna_seq = h.orf(prot_l)
        else
            local prefix = h.orf(prot_l):sub(1, -4)
            dna_seq = prefix .. dna_seq
        end
        local prot_seq = h.translate(dna_seq)
        prot:add_seq('prot_' .. i, prot_seq)
    end
    dna:add_seq(shortrand(), dna_seq)
    prot.names = {}
    for i = 1, n do
        table.insert(prot.names, 'prot_' .. i)
    end
    local argv = itmp
    dna.cin = argv
    return dna, match_fasta(prot), argv, argv
end)))))

add_test('untranslate',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local prot_l = rr(20, 40)
    local dna_l = prot_l * 3 + 3
    local _, base_prot = h.orf(prot_l)
    local name = shortrand()
    local description = seq_descr()
    local prot = h.new_fasta()
    prot:add_seq(name, base_prot, description)
    local argv = itmp
    prot.cin = argv
    return prot,
    function(dna)
        if #dna.names ~= 1 then
            return false, [[Хотели одну последовательность,
                а получили ]] .. #dna.names
        end
        if dna.names[1] ~= name then
            return false, [[Неправильно названа
                последовательность: ]] .. dna.names[1]
        end
        if dna.name2desc[name] ~= description then
            return false, [[Неправильное описание у
                последовательности: ]] .. dna.name2desc[name]
        end
        local prot1 =  h.translate(dna.name2seq[name])
        if prot1 ~= base_prot then
            return false, [[Ваша последовательность
                не транслируется в нужную последовательность
                белка. Из вашей последовательности
                получается ]] .. prot1
        end
        return true
    end, argv, argv
end)))))

add_test('find-substrings',
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
        local count = 0
        for _, seq1 in ipairs(seqs) do
            if seq1:find(seq) and seq1 ~= seq then
                count = count + 1
            end
        end
        if count >= 2 then
            -- 2 others + 1 me
            prot2:add_seq(name, seq, prot1.name2desc[name])
        end
    end
    local argv = itmp
    prot1.cin = argv
    return prot1, match_fasta(prot2), argv, argv
end)))))

add_test('find-repeats',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local length = rr(6, 10)
    local dna_seq = atgc_rand(rr(100, 1000))
    local dna1 = h.new_fasta()
    local dna2 = h.new_fasta()
    local dna_name = shortrand()
    local description = seq_descr()
    local j = 1
    local seen = {}
    for i = 1, #dna_seq - length + 1 do
        local slice = dna_seq:sub(i, i + length - 1)
        if seen[slice] == 1 then
            local name = 'rep_' .. j
            dna2:add_seq(name, slice)
            j = j + 1
        end
        seen[slice] = (seen[slice] or 0) + 1
    end
    dna1:add_seq(dna_name, dna_seq, description)
    local argv = itmp .. ' ' .. length
    dna1.cin = argv
    return dna1, match_fasta(dna2), argv, argv
end)))))

add_test('filter-non-polar',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
function()
    local polar = '[CVILMFYWA]'
    local n = rr(1, 10)
    local prot1 = h.new_fasta()
    local prot2 = h.new_fasta()
    for i = 1, n do
        local name = shortrand() .. i
        local description = seq_descr()
        local _, base_prot = h.orf(rr(15, 20))
        local base_prot1 = base_prot:gsub('%*', '')
        local polar_seq = base_prot1:gsub(polar, '')
        local nonpolar_length = #base_prot1 - #polar_seq
        local is_nonpolar = 2 * nonpolar_length >= #base_prot1
        prot1:add_seq(name, base_prot, description)
        if is_nonpolar then
            prot2:add_seq(name, base_prot, description)
        end
    end
    local argv = itmp
    prot1.cin = argv
    return prot1, match_fasta(prot2), argv, argv
end)))))

add_test('calc-mass',
ifile(itmp, ifasta(
function()
    local aa_masses = require 'aa_masses'
    local name = shortrand()
    local description = seq_descr()
    local _, base_prot = h.orf(rr(15, 20))
    local base_prot1 = base_prot:gsub('%*', '')
    local mass_total = 0
    for i = 1, #base_prot1 do
        local aa = base_prot1:sub(i, i)
        local aa_mass = aa_masses[aa]
        assert(aa_mass)
        mass_total = mass_total + aa_mass
    end
    local h2o = 18
    mass_total = mass_total - (#base_prot1 - 1) * h2o
    local prot1 = h.new_fasta()
    prot1:add_seq(name, base_prot, description)
    local argv = itmp
    prot1.cin = argv
    return prot1, match_number(mass_total), argv, argv
end)))

add_test('word-frequency',
ifile(itmp, ifasta(
function()
    local aas = {'A', 'R', 'N', 'D', 'C', 'Q', 'E', 'G', 'H',
        'I', 'L', 'K', 'F', 'P', 'S', 'T', 'Y', 'V'}
    local aa = one_of(unPack(aas))
    local name = shortrand()
    local description = seq_descr()
    local dna_seq = h.orf(rr(70, 100))
    local prot_length = #dna_seq / 3 - 1
    local codon2count = {}
    for codon, aa1 in pairs(translation) do
        if aa1 == aa then
            codon2count[codon] = 0
        end
    end
    for i = 1, prot_length do
        local dna_index = (i - 1) * 3 + 1 -- eh, lua
        local codon = dna_seq:sub(dna_index, dna_index + 2)
        local aa1 = translation[codon]
        assert(aa1)
        if aa1 == aa then
            codon2count[codon] = codon2count[codon] + 1
        end
    end
    local counts = {}
    for _, count in pairs(codon2count) do
        table.insert(counts, count)
    end
    local dna1 = h.new_fasta()
    dna1:add_seq(name, dna_seq, description)
    local argv = itmp .. ' ' .. aa
    dna1.cin = argv
    return dna1, match_numbers_no_order(unPack(counts)),
        argv, argv
end)))

return pr12

