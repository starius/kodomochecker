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
        if py:match(stud) and py:match(mnem .. '.py') then
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

checkone.checkone = function(prac, stud, mnem0, set_result)
    for _, mnem_and_task in ipairs(prac) do
        local mnem, task = unPack(mnem_and_task)
        if mnem == mnem0 then
            local py = checkone.find_py(stud, mnem)
            if not py then
                set_result(stud, mnem, py, false,
                    'No Python file found!', 'nopy')
            else
                for fi, func in ipairs(task) do
                    local ok, m1, m2, task_in, task_out =
                        checkpy(func, py)
                    if ok then
                        local p8 = checkone.pep8(py)
                        local p8st, p8rep = unPack(p8)
                        set_result(stud, mnem, py, true,
                            p8rep, p8st)
                    else
                        local m = m1
                        if m2 ~= 'none' then
                            m = m .. '\nРазъяснение: ' .. m2
                        end
                        local report =
                            pf(err, m, task_in, task_out)
                        set_result(stud, mnem, py, false,
                            report, fi)
                    end
                end
            end
        end
    end
end

-- http://stackoverflow.com/a/4521960
if not pcall(debug.getlocal, 4, 1) then
    local pr_name, stud, mnem = unPack(arg)
    local prac = require(pr_name)
    for i = 1, 100 do
        checkone.checkone(prac, stud, mnem, function(...)
            local s, m, py, status, report, fi = ...
            if not status then
                print(...)
            end
            if status and i == 1 and not fi then
                -- pep8
                print(...)
            end
        end)
    end
end

return checkone

