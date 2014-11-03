local checkone = {}

local checkpy = require('checkpy').checkpy
local helpers = require('helpers')

local sh = require('sh')

local unPack = unpack or table.unpack

pep8out_fname = os.tmpname()

checkone.pep8 = function(py)
    if not checkone.pep8res then
        checkone.pep8res = {}
    end
    if not checkone.pep8res[py] then
        local cmd = ('pep8 -r --show-source ' ..
            '--ignore=W391,E251,E501,W292,W291,W293 ' .. py ..
            ' > ' .. pep8out_fname)
        local run_ok = helpers.execute(cmd)
        local pep8out = io.open(pep8out_fname, 'r')
        local pep8_report = pep8out:read('*a')
        pep8out:close()
        checkone.pep8res[py] = {run_ok, pep8_report}
    end
    return checkone.pep8res[py]
end

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

checkone.find_py = function(stud, mnem)
    if not checkone.all_files then
        checkone.all_files =
            sh("find py | grep '\\.py$'"):split('\n')
    end
    mnem = mnem:gsub('%-', '%%%-')
    for _, py in ipairs(checkone.all_files) do
        if py:match(stud) and
                py:match('_' .. mnem .. '.py') then
            return py
        end
    end
end

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

checkone.checkfile = function(py, task)
    for fi, func in ipairs(task) do
        local ok, m1, m2, task_in, task_out =
            checkpy(func, py)
        if ok then
            local p8 = checkone.pep8(py)
            local p8st, p8rep = unPack(p8)
            return true, p8rep, p8st
        else
            local m = m1
            if m2 ~= 'none' then
                m = m .. '\nРазъяснение: ' .. m2
            end
            local report =
                pf(err, m, task_in, task_out)
            return false, report, fi
        end
    end
end

checkone.checkone = function(prac, stud, mnem0, set_result)
    for _, mnem_and_task in ipairs(prac) do
        local mnem, task = unPack(mnem_and_task)
        if mnem == mnem0 then
            local py = checkone.find_py(stud, mnem)
            if not py then
                set_result(stud, mnem, py, false,
                    'No Python file found!', 'nopy')
            else
                local status, report, fi =
                    checkone.checkfile(py, task)
                set_result(stud, mnem, py, status, report, fi)
            end
        end
    end
end

-- http://stackoverflow.com/a/4521960
if not pcall(debug.getlocal, 4, 1) then
    local py = arg[1]
    if not py then
        error('No Python script provided')
    end
    local py_pattern = '(%w+)_(%w+)_(%w+).py$'
    local stud, pr_name, mnem0 = py:match(py_pattern)
    if not py then
        error('Wrong script name. Format: student_prac_task.py')
    end
    if pr_name ~= 'pr8' and pr_name ~= 'pr9' then
        error('Unknown prac name')
    end
    local prac = assert(require(pr_name))
    local task0
    for _, mnem_and_task in ipairs(prac) do
        local mnem, task = unPack(mnem_and_task)
        if mnem == mnem0 then
            task0 = task
        end
    end
    if not task0 then
        error('Unknown task name')
    end
    local ok = true
    local text = ''
    local pep8ok = true
    local pep8text = ''
    for i = 1, 100 do
        local status, report, fi = checkone.checkfile(py, task0)
        if not status then
            ok = false
            text = text .. '\n' .. report .. '\n'
        end
        local p8st = fi
        local p8rep = report
        if not p8st then
            pep8text = 'Скрипт работает, но есть нарекания ' ..
            'к оформлению кода (см. ниже по-английски):' ..
            '\n\n' .. report
            pep8ok = false
        end
    end
    if ok and pep8ok then
        print([[Оценка 5, превосходно!]])
    elseif ok and not pep8ok then
        print('Оценка 3\n\n' .. pep8text)
    else
        print('Оценка 0\n\n' .. text)
    end
end

return checkone

