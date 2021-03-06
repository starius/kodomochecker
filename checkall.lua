local checkall = {}

local checkone = require('checkone').checkone
local excel_list = require('kurs1').excel_list

local sh = require('sh')

local unPack = unpack or table.unpack

local excel = {}

local fiseen = {}

local pr_name = ''

local add_to_report = function(stud, mnem, fi, py, report, mode)
    local key = stud .. '|' .. mnem .. '|' .. fi
    if not fiseen[key] then
        fiseen[key] = true
        local fname
        if py then
            fname = py .. '.txt'
        else
            fname = string.format('py/%s_%s_%s.txt',
                stud, pr_name, mnem)
        end
        local report_file = io.open(fname, mode)
        report_file:write(report .. '\n')
        report_file:close()
    end
end

local pep8ok = {}
local nopy = {}

checkall.set_result = function(stud, mnem, py, ok, report, fi)
    local key = stud .. '|' .. mnem
    if fi == 'nopy' then
        nopy[key] = true
    end
    local mode = 'a'
    if excel[key] == true and not ok then
        -- remove previous messages from log
        -- these messages must saying that the script is OK
        -- while it is not OK
        mode = 'w'
    end
    if excel[key] ~= false then
        excel[key] = ok
    end
    if excel[key] then
        local p8st = fi
        local p8rep = report
        pep8ok[key] = p8st
        if p8st == 0 then
            report = 'Скрипт работает, но есть серьёзные нарекания ' ..
            'к оформлению кода (см. ниже по-английски):' ..
            '\n\n' .. report
            add_to_report(stud, mnem, 'pep8', py, report, mode)
        end
        if p8st == 1 then
            report = 'Скрипт работает, но есть кое-какие нарекания ' ..
            'к оформлению кода (см. ниже по-английски):' ..
            '\n\n' .. report
            add_to_report(stud, mnem, 'pep8', py, report, mode)
        end
    end
    if not ok then
        add_to_report(stud, mnem, fi, py, report, mode)
    end
end

checkall.all_mnems = function(pr)
    local mnems_set = {}
    for _, mnem_and_task in ipairs(pr) do
        local mnem, task = unPack(mnem_and_task)
        mnems_set[mnem] = 1
    end
    local mnems = {}
    for mnem, _ in pairs(mnems_set) do
        table.insert(mnems, mnem)
    end
    return mnems
end

checkall.checkall = function(prac, N)
    local mnems = checkall.all_mnems(prac)
    for i = 1, N do
        io.stderr:write('Iteration ' .. i .. '\n')
        for _, stud in ipairs(excel_list) do
            for _, mnem in ipairs(mnems) do
                checkone(prac, stud, mnem,
                    checkall.set_result)
            end
        end
    end
end

checkall.score_of = function(stud, mnem)
    local key = stud .. '|' .. mnem
    local score = 0
    if not nopy[key] then
        score = 1
    end
    if excel[key] == true then
        score = 3 + pep8ok[key]
    end
    return score
end

checkall.print_results = function(prac)
    local header = 'login'
    for _, mnem_and_task in ipairs(prac) do
        local mnem, task = unPack(mnem_and_task)
        header = header .. '\t' .. mnem
    end
    print(header)
    for _, stud in ipairs(excel_list) do
        local line = stud
        for _, mnem_and_task in ipairs(prac) do
            local mnem, task = unPack(mnem_and_task)
            line = line .. '\t' .. checkall.score_of(stud, mnem)
        end
        print(line)
    end
end

-- http://stackoverflow.com/a/4521960
if not pcall(debug.getlocal, 4, 1) then
    pr_name = arg[1]
    local N = arg[2] or 30
    N = tonumber(N)
    local stud = arg[3]
    if stud then
        excel_list = {stud}
    end
    local prac = require(pr_name)
    checkall.checkall(prac, N)
    checkall.print_results(prac)
end

return checkall

