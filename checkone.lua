local checkone = {}

local checkpy = require('checkpy').checkpy
local pr8 = require('pr8')

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

checkone.checkone = function(stud, mnem0, set_result)
    for _, mnem_and_task in ipairs(pr8) do
        local mnem, task = unPack(mnem_and_task)
        if mnem == mnem0 then
            local py = checkone.find_py(stud, mnem)
            if not py then
                set_result(stud, mnem, py, false,
                    'No Python file found!', 'nopy')
            else
                for fi, func in ipairs(task) do
                    local ok, m1, m2, task_in, task_out = checkpy(func, py)
                    if ok then
                        set_result(stud, mnem, py, true)
                    else
                        local m = m1
                        if m2 ~= 'none' then
                            m = m .. '\nРазъяснение: ' .. m2
                        end
                        local report = pf(err, m, task_in, task_out)
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
    local stud = arg[1]
    local mnem = arg[2]
    for i = 1, 100 do
        checkone.checkone(stud, mnem, function(...)
            local s, m, py, status = ...
            if not status then
                print(...)
            end
        end)
    end
end

return checkone

