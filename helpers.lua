
local helpers = {}

local translation = require 'translation'

helpers.unPack = unpack or table.unpack

helpers.shortrand = function()
    local t = {}
    local l = math.random(3, 7)
    for i = 1, l do
        table.insert(t, math.random(65, 90)) -- A-Z
    end
    return string.char(helpers.unPack(t))
end

helpers.genname = function()
    return helpers.shortrand() .. helpers.shortrand():lower()
end

helpers.all_numbers = function(t)
    local numbers = {}
    for w in string.gmatch(t, "%-?%d+%.?[%de%-]*") do
        table.insert(numbers, tonumber(w))
    end
    return numbers
end

helpers.find_number = function(t, n)
    local numbers = helpers.all_numbers(t)
    for _, n1 in ipairs(numbers) do
        if math.abs(n - n1) < 0.001 then
            return true
        end
    end
    return false
end

assert(helpers.find_number('\n0.04 KOH', 0.039999999999999))
assert(helpers.find_number('0\n0.07\n7.2', 0.069999999999999))
assert(helpers.find_number('The vertix is (2.655;-11.489025)', 2.655))
assert(helpers.find_number('The vertix is (2.655;-11.489025)', -11.489025))
assert(helpers.find_number('The 2 i', 2))

helpers.match_number = function(result)
    return function(out)
        if not helpers.find_number(out, result) then
            return false, 'выход не содержит правильный ответ ' .. result
        end
        return true
    end
end

THRESHOLD = 0.001
local arr_find_num = function(arr, num, start)
    for i = start, #arr do
        if math.abs(arr[i] - num) <= THRESHOLD then
            return i
        end
    end
end

helpers.find_numbers = function(out, nn, order)
    if order == nil then
        order = true
    end
    local numbers = helpers.all_numbers(out)
    if not order then
        table.sort(nn)
        table.sort(numbers)
    end
    local nn_str = table.concat(nn, ', ')
    local numbers_str = table.concat(numbers, ', ')
    if #numbers < #nn then
        return false, string.format([[
Выход содержит недостаточное количество чисел.
Мы ожидали %i чисел: %s
В выходе вашей программы мы нашли %i чисел: %s]],
#nn, nn_str,
#numbers, numbers_str)
    end
    if #numbers > #nn * 2 then
        return false, string.format([[
Выход содержит слишком много чисел.
Мы ожидали %i чисел: %s
В выходе вашей программы мы нашли %i чисел: %s]],
#nn, nn_str,
#numbers, numbers_str)
    end
    local start = 1
    for i = 1, #nn do
        local hit = arr_find_num(numbers, nn[i], start)
        if not hit then
            return false, string.format([[
Выход не содержит правильное число.
Мы ожидали числа: %s
В выходе вашей программы мы нашли числа: %s
Не могу найти число %f в выходе]],
nn_str, numbers_str, nn[i])
        end
        start = hit + 1
    end
    return true
end

assert(helpers.find_numbers('1 1.2\n3.67', {1, 1.2, 3.67}))
assert(helpers.find_numbers('1 1.2\n3.67', {1, 1.2}))
assert(helpers.find_numbers('1 4 1.2\n3.67', {1, 1.2}))
assert(not helpers.find_numbers('1 1.1', {1, 1.2}))

assert(helpers.find_numbers('1 2 1.1', {1.1, 1, 2}, false))
assert(not helpers.find_numbers('1 2 1.1', {1.1, 1, 2}, true))
assert(not helpers.find_numbers('1 2 1.9', {1.1, 1, 2}, false))

helpers.match_numbers = function(...)
    local nn = {...}
    return function(out)
        return helpers.find_numbers(out, nn, true)
    end
end

helpers.match_numbers_no_order = function(...)
    local nn = {...}
    return function(out)
        return helpers.find_numbers(out, nn, false)
    end
end

helpers.bool_wrapper = function(f)
    return function(out)
        out = out:gsub('[Tt]rue', 1)
        out = out:gsub('[Ff]alse', 0)
        return f(out)
    end
end

helpers.match_str = function(result)
    return function(out)
        if not out:find(result, 1, true) then
            return false,
                'выход не содержит правильный ответ ' ..
                result
        end
        return true
    end
end

helpers.match_choice = function(result, choices)
    return function(out)
        if not out:find(result, 1, true) then
            return false,
                'выход не содержит правильный ответ ' ..
                result
        end
        for _, choice in ipairs(choices) do
            if choice ~= result and
                    out:find(choice, 1, true) then
                return false,
                    'выход содержит неправильный ответ ' ..
                    choice
            end
        end
        return true
    end
end

helpers.find_strs = function(out, nn, order)
    if order == nil then
        order = true
    end
    local nn_str = table.concat(nn, ', ')
    local start = 1
    for i, word in ipairs(nn) do
        if not order then
            start = 1
        end
        local a, b = out:find(word, start, true)
        if not a then
            return false, string.format([[
Выход не содержит фразы %s.
Мы ожидали увидеть в выходе такие фразы: %s]],
word, nn_str)
        end
        start = a
    end
    return true
end

assert(helpers.find_strs('1 1.2\n3.67', {'1', '1.2', '3.67'}))
assert(not helpers.find_strs('1 1.1', {'1', '1.2'}))

helpers.match_strs = function(...)
    local nn = {...}
    return function(out)
        return helpers.find_strs(out, nn, true)
    end
end

helpers.match_strs_no_order = function(...)
    local nn = {...}
    return function(out)
        return helpers.find_strs(out, nn, false)
    end
end

if _VERSION == 'Lua 5.2' then
    helpers.execute = os.execute
elseif _VERSION == 'Lua 5.1' then
    helpers.execute = function(...)
        local status = os.execute(...)
        return status == 0
    end
end

helpers.one_of = function(...)
    local t = {...}
    return t[math.random(1, #t)]
end

helpers.copy_list = function(ll)
    local ll2 = {}
    for _, e in ipairs(ll) do
        table.insert(ll2, e)
    end
    return ll2
end

helpers.shuffle = function(t)
    local t2 = {}
    while #t > 0 do
        table.insert(t2, table.remove(t, math.random(1, #t)))
    end
    return t2
end

helpers.read_file = function(fname)
    local f = io.open(fname)
    local t = f:read('*a')
    f:close()
    return t
end

helpers.write_file = function(fname, text)
    local f = io.open(fname, 'w')
    f:write(text)
    f:close()
    return t
end

helpers.add_test = function(prac, name0, func)
    for _, v in pairs(prac) do
        name, funcs = helpers.unPack(v)
        if name == name0 then
            table.insert(funcs, func)
            return
        end
    end
    table.insert(prac, {name0, {func}})
end

helpers.get_tests = function(prac, name0)
    for _, v in pairs(prac) do
        name, funcs = helpers.unPack(v)
        if name == name0 then
            return funcs
        end
    end
end

helpers.ifile = function(fname, f)
    return function()
        local data, checker, _1, _2 = f()
        local text, cin
        if type(data) == 'string' then
            text = data
            cin = ''
        elseif type(data) == 'table' then
            text = data.text
            cin = data.cin
        else
            error()
        end
        helpers.write_file(fname, text)
        return cin, checker, text .. '\n\n' .. cin, _2
    end
end

helpers.ofile = function(fname, f)
    return function()
        local text, checker, _1, _2 = f()
        return text, function()
            local out = helpers.read_file(fname)
            local ok, message = checker(out)
            return ok, message, out
        end, _1, _2
    end
end

helpers.atgc_rand = function(n)
    local t = ''
    for i = 1, n do
        t = t .. helpers.one_of('A', 'T', 'G', 'C')
    end
    return t
end

-- class fasta:
-- * name2seq
-- * name2desc - optional
-- * names - optional

helpers.new_fasta = function()
    local fasta = {}
    fasta.name2seq = {}
    fasta.name2desc = {}
    fasta.names = {}
    return fasta
end

helpers.get_names = function(name2seq)
    local names = {}
    for name, seq in pairs(name2seq) do
        table.insert(names, name)
    end
    return names
end

helpers.write_fasta = function(fasta)
    local width = math.random(40, 65)
    local name2seq = fasta.name2seq
    local name2desc = fasta.name2desc
    local names = fasta.names
    if names == nil then
        names = helpers.get_names(name2seq)
    end
    local lines = {}
    for _, name in ipairs(names) do
        local descr = name2desc[name]
        descr = descr and #descr > 0 and (' ' .. descr) or ''
        table.insert(lines, '>' .. name .. descr)
        local seq = name2seq[name]
        assert(seq ~= nil)
        local pos = 1
        while pos <= #seq do
            table.insert(lines, seq:sub(pos, pos + width - 1))
            pos = pos + width
        end
    end
    return table.concat(lines, '\n')
end

function string.trim(self)
    local text = self:gsub("%s+$", "")
    text = text:gsub("^%s+", "")
    return text
end

helpers.read_fasta = function(text)
    local fasta = helpers.new_fasta()
    local name0
    for line0 in text:gmatch('([^\n]+)') do
        local line = line0:trim()
        if line:sub(1, 1) == '>' then
            local name, descr = line:match('>([%w%p]+) *(.*)')
            name0 = name
            fasta.name2desc[name] = descr
            fasta.name2seq[name] = ''
            table.insert(fasta.names, name)
        elseif name0 then
            line = line:gsub('%s', '')
            fasta.name2seq[name0] = fasta.name2seq[name0] ..
                line
        else
            -- junk before first sequence => stop
            break
        end
    end
    return fasta
end

helpers.array_equal = function(t1, t2)
    if #t1 ~= #t2 then
        return false, 'Число элементов отличается'
    end
    for i = 1, #t1 do
        if t1[i] ~= t2[i] then
            return false, 'Элемент с номером ' .. i ..
                ' отличается: "' .. t1[i] .. '", "' ..
                t2[i] .. '"'
        end
    end
    return true
end

helpers.fasta_equal = function(fasta1, fasta2)
    local name2seq1 = fasta1.name2seq
    local name2desc1 = fasta1.name2desc or {}
    local names1 = fasta1.names
    local name2seq2 = fasta2.name2seq
    local name2desc2 = fasta2.name2desc
    local names2 = fasta2.names
    if not name2desc2 then
        name2desc2 = name2desc1
    end
    local sort = (not names1) or (not names2)
    if names1 == nil then
        names1 = helpers.get_names(name2seq1)
    end
    if names2 == nil then
        names2 = helpers.get_names(name2seq2)
    end
    if sort then
        table.sort(names1)
        table.sort(names2)
    end
    local ae, message = helpers.array_equal(names1, names2)
    if not ae then
        return false, 'Разный набор последовательностей. ' ..
            message
    end
    for _, name in ipairs(names1) do
        if name2seq1[name] ~= name2seq2[name] then
            return false, 'Последовательность ' .. name ..
                ' отличается'
        end
        if name2desc1[name] ~= name2desc2[name] then
            return false, 'Описание последовательности ' ..
                name .. ' отличается'
        end
    end
    return true
end

helpers.ifasta = function(f)
    return function()
        local fasta, checker, _1, _2 = f()
        local data = {}
        data.text = helpers.write_fasta(fasta)
        data.cin = fasta.cin or ''
        return data, checker,
            data.text .. '\n\n' .. data.cin, _2
    end
end

helpers.ofasta = function(f)
    return function()
        local text, checker, _1, _2 = f()
        return text, function(out)
            local fasta = helpers.read_fasta(out)
            local ok, message = checker(fasta)
            return ok, message, out
        end, _1, _2
    end
end

helpers.match_fasta = function(fasta0)
    return function(fasta)
        local fe, message = helpers.fasta_equal(fasta, fasta0)
        if not fe then
            return false,
string.format([[FASTA-файлы не соответствуют.
Сообщение об ошибке: %s
Мы ожидали получить такой файл:
%s]], message, helpers.write_fasta(fasta0))
        end
        return true
    end
end

local rename_fasta = function(fasta)
    fasta.names = nil
    fasta.name2desc = nil
    local seqs = {}
    for _, seq in pairs(fasta.name2seq) do
        table.insert(seqs, seq)
    end
    table.sort(seqs)
    fasta.name2seq = {}
    for i, seq in ipairs(seqs) do
        fasta.name2seq['seq' .. i] = seq
    end
end

helpers.match_fasta_no_names = function(fasta0)
    rename_fasta(fasta0)
    return function(fasta)
        rename_fasta(fasta)
        return match_fasta(fasta0)(fasta)
    end
end

helpers.junk_triplet = function(can_include_atg)
    local triplet
    while not triplet or translation[triplet] == '*'
            or (not can_include_atg and triplet == 'ATG') do
        triplet = helpers.atgc_rand(3)
    end
    return triplet
end

helpers.junk_triplets = function(n, can_include_atg)
    local tt = {}
    for i = 1, n do
        table.insert(tt, helpers.junk_triplet(can_include_atg))
    end
    return table.concat(tt)
end

helpers.stop_codon = function()
    return helpers.one_of('TAA', 'TAG', 'TGA')
end

helpers.orf = function(protein_length, can_include_atg)
    local dna = {}
    table.insert(dna, 'ATG')
    for i = 1, protein_length - 1 do
        table.insert(dna, helpers.junk_triplet(can_include_atg))
    end
    table.insert(dna, helpers.stop_codon())
    local protein = {}
    for _, triplet in ipairs(dna) do
        table.insert(protein, translation[triplet])
    end
    return table.concat(dna), table.concat(protein)
end

helpers.complement = function(seq)
    return seq:reverse():gsub('%w',
        {A='T', T='A', G='C', C='G'})
end

assert(helpers.complement('AATG') == 'CATT')

helpers.mutate = function(seq)
    local i = math.random(1, #seq)
    local prev = seq:sub(i, i)
    local curr = prev
    while curr == prev do
        curr = helpers.atgc_rand(1)
    end
    return seq:sub(1, i - 1) .. curr .. seq:sub(i + 1)
end

helpers.find_palindromes = function(seq, min_length)
    local c_dict = {A='T', T='A', G='C', C='G'}
    local at = function(i)
        return seq:sub(i, i)
    end
    local in_range = function(i)
        return i >= 1 and i <= #seq
    end
    local compl = function(i, j)
        return in_range(i) and in_range(j) and
            c_dict[at(i)] == at(j)
    end
    local find_palindrome = function(left_middle)
        for i = 0, #seq do
            local first = left_middle - i
            local last = left_middle + 1 + i
            if not compl(first, last) then
                -- return previous good palindrome or ''
                return seq:sub(fisrt + 1, last - 1)
            end
        end
        return ''
    end
    local palindromes = {}
    for left_middle = 1, #seq do
        local palindrome = find_palindrome(left_middle)
        if #palindrome >= min_length then
            table.insert(palindromes, palindrome)
        end
    end
    table.sort(palindromes, function(a, b)
        return #b < #a
    end)
    local palindromes2 = {}
    local is_inclusion = function(palindrome)
        for _, palindrome0 in ipairs(palindromes2) do
            if palindrome0:match(palindrome) then
                return true
            end
        end
        return false
    end
    for _, palindrome in ipairs(palindromes) do
        if not is_inclusion(palindrome) then
            table.insert(palindromes2, palindrome)
        end
    end
    return palindromes2
end

helpers.seq_descr = function()
    local d = {}
    local n = math.random(0, 5)
    for i = 1, n do
        table.insert(d, helpers.shortrand())
    end
    return table.concat(d, ' ')
end

return helpers

