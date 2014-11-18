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
local otmp = os.tmpname()

add_test('find-orfs-in-frame',
ifile(itmp, ifasta(
ofile('output.fasta', ofasta(
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
    local argv = itmp .. ' ' .. frame .. ' ' .. min_length
    dna.cin = argv
    return dna, match_fasta(protein), argv, argv
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

return pr12

