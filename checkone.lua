local checkone = {}

local checkpy = require('checkpy').checkpy
local helpers = require('helpers')

local sh = require('sh')
local h = require('helpers')

local unPack = unpack or table.unpack

local pep8out_fname, pep8out_fname_d = h.tmp_file_and_deleter()
checkone.pep8out_fname_d = pep8out_fname_d

checkone.pep8 = function(py)
    if py:find('lua$') then
        return {2, ''}
    end
    if py:find('%.c$') then
        return {2, ''}
    end
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
        local pep_ok = 0
        if run_ok then
            pep_ok = 2
        elseif not pep8_report:find('%d: E%d') then
            pep_ok = 1
        end
        checkone.pep8res[py] = {pep_ok, pep8_report}
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
        local nField=1
        local nStart=1
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
            sh("find py | egrep '\\.(py|lua|c)$'"):split('\n')
    end
    mnem = mnem:gsub('%-', '%%%-')
    stud = stud:gsub('%-', '%%%-')
    for _, py in ipairs(checkone.all_files) do
        if py:match(stud .. '/') and
                (py:match('_' .. mnem .. '.py') or
                 py:match('_' .. mnem .. '.lua') or
                 py:match('_' .. mnem .. '.c')) then
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
        if not ok then
            local m = m1
            if m2 ~= 'none' then
                m = m .. '\nРазъяснение: ' .. m2
            end
            local report =
                pf(err, m, task_in, task_out)
            return false, report, fi
        end
    end
    local p8 = checkone.pep8(py)
    local p8st, p8rep = unPack(p8)
    return true, p8rep, p8st
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
    local N = arg[2] or 100
    N = tonumber(N)
    if not py then
        print('No Python script provided')
        error()
    end
    if not py then
        print('Wrong script name. Format: student_prac_task.py')
        error()
    end
    local py_pattern = '_(%w+)_([%w-]+).py$'
    local pr_name, mnem0 = py:match(py_pattern)
    if not pr_name then
        local lua_pattern = '_(%w+)_([%w-]+).lua$'
        pr_name, mnem0 = py:match(lua_pattern)
    end
    if not pr_name then
        local c_pattern = '_(%w+)_([%w-]+).c$'
        pr_name, mnem0 = py:match(c_pattern)
    end
    if pr_name ~= 'pr8' and pr_name ~= 'pr9'
            and pr_name ~= 'pr10' and pr_name ~= 'pr11'
            and pr_name ~= 'pr12' and pr_name ~= 'pr13'
            and pr_name ~= 'cw' then
        print('Unknown prac name')
        error()
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
        print('Unknown task name')
        error()
    end
    local ok = true
    local text = ''
    local pep8ok = 2
    local pep8text = ''
    local test_started = os.time()
    for i = 1, N do
        if os.difftime(os.time(), test_started) > 15 then
            -- test takes more than 15 seconds
            break
        end
        local status, report, fi = checkone.checkfile(py, task0)
        if not status then
            ok = false
            text = text .. '\n' .. report .. '\n'
        end
        local p8st = fi
        local p8rep = report
        pep8ok = math.min(pep8ok, p8st)
        if p8st == 0 then
            pep8text = 'Скрипт работает, но есть серьёзные нарекания ' ..
            'к оформлению кода (см. ниже по-английски):' ..
            '\n\n' .. report
        end
        if p8st == 1 then
            pep8text = 'Скрипт работает, но есть кое-какие нарекания ' ..
            'к оформлению кода (см. ниже по-английски):' ..
            '\n\n' .. report
        end
    end
    if ok and pep8ok == 2 then
        print([[Оценка 5, отлично!]])
    elseif ok and pep8ok == 1 then
        print('Оценка 4, хорошо\n\n' .. pep8text)
    elseif ok and pep8ok == 0 then
        print('Оценка 3, удовлетворительно\n\n' .. pep8text)
    else
        print('Оценка 1, неудовлетворительно\n\n' .. text)
    end
end

return checkone

