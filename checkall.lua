local checkall = {}

local checkpy = require('checkpy').checkpy
local pr8 = require('pr8')
local excel_list = require('kurs1').excel_list

local sh = require('sh')

local unPack = unpack or table.unpack

-- based on http://lua-users.org/wiki/SplitJoin
function string:split(sep, nMax, plain)
    if not sep then
        sep = '%s+'
    end
    assert(sep ~= '')
    assert(nMax == nil or nMax >= 1)
    local aRecord = {}
    if self:len() > 0 then
        nMax = nMax or -1
        local nField=1 nStart=1
        local nFirst,nLast = self:find(sep, nStart, plain)
        while nFirst and nMax ~= 0 do
            aRecord[nField] = self:sub(nStart, nFirst-1)
            nField = nField+1
            nStart = nLast+1
            nFirst,nLast = self:find(sep, nStart, plain)
            nMax = nMax-1
        end
        aRecord[nField] = self:sub(nStart)
    end
    return aRecord
end

local pf = string.format

checkall.find_py = function(stud, mnem)
    if not checkall.all_files then
        checkall.all_files =
            sh("find py | grep '\\.py$'"):split('\n')
    end
    mnem = mnem:gsub('%-', '%%%-')
    for _, py in ipairs(checkall.all_files) do
        if py:match(stud) and py:match(mnem .. '.py') then
            return py
        end
    end
end

excel = {}

local err = [[Ой, ошибка!
Ваш скрипт не работает или работает неправильно.
Исправьте ваш скрипт, пожалуйста.

Немного информации о проблеме:

Сообщение об ошибке: %s

Что вводили в программу (вход):
%s

Что выдала программа (выход):
%s

===========================
]]

local fiseen = {}

checkall.set_result = function(stud, mnem, py, ok, report, fi)
    if excel[stud .. '|' .. mnem] ~= false then
        excel[stud .. '|' .. mnem] = ok
    end
    if not ok and not fiseen[stud .. '|' .. mnem .. '|' .. fi] then
        fiseen[stud .. '|' .. mnem .. '|' .. fi] = true
        local fname
        if py then
            fname = py .. '.txt'
        else
            fname = 'py/' .. stud .. '_pr8_' .. mnem .. '.txt'
        end
        local report_file = io.open(fname, 'a')
        report_file:write(report .. '\n')
        report_file:close()
    end
end

checkall.N = 10

checkall.checkall = function()
    for _, stud in ipairs(excel_list) do
        for _, mnem_and_task in ipairs(pr8) do
            local mnem, task = unPack(mnem_and_task)
            local py = checkall.find_py(stud, mnem)
            if not py then
                checkall.set_result(stud, mnem, py, false,
                    'No Python file found!', 'nopy')
            else
                for fi, func in ipairs(task) do
                    for i = 1, checkall.N do
                        local ok, m1, m2, task_in, task_out = checkpy(func, py)
                        if ok then
                            checkall.set_result(stud, mnem, py, true)
                        else
                            local m = m1
                            if m2 ~= 'none' then
                                m = m .. '\nРазъяснение: ' .. m2
                            end
                            local report = pf(err, m, task_in, task_out)
                            checkall.set_result(stud, mnem, py, false,
                                report, fi)
                        end
                    end
                end
            end
        end
    end
end

checkall.print_results = function()
    local header = 'login'
    for _, mnem_and_task in ipairs(pr8) do
        local mnem, task = unPack(mnem_and_task)
        header = header .. '\t' .. mnem
    end
    print(header)
    for _, stud in ipairs(excel_list) do
        local line = stud
        for _, mnem_and_task in ipairs(pr8) do
            local mnem, task = unPack(mnem_and_task)
            local score = 0
            if excel[stud .. '|' .. mnem] == true then
                score = 1
            end
            line = line .. '\t' .. score
        end
        print(line)
    end
end

checkall.checkall()
checkall.print_results()

return checkall

