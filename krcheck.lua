local checkall = require('checkall')
local checkone = require('checkone')
local excel_list = require('kurs1').excel_list

local krcheck = {}

local pr_name = ''

local stud2tasks = {}

krcheck.read_tsv = function(tsv_fname)
    for line0 in io.lines(tsv_fname) do
        local line = line0:trim()
        local parts = line:split()
        local stud = parts[1]
        local tasks = {}
        for i = 2, #parts do
            local task = parts[i]
            table.insert(tasks, task)
        end
        stud2tasks[stud] = tasks
    end
end

krcheck.checkall = function(prac, N)
    for i = 1, N do
        io.stderr:write('Iteration ' .. i .. '\n')
        for _, stud in ipairs(excel_list) do
            local mnems = stud2tasks[stud]
            assert(mnems)
            for _, mnem in ipairs(mnems) do
                checkone.checkone(prac, stud, mnem,
                    checkall.set_result)
            end
        end
    end
end

krcheck.print_results = function(prac)
    for _, stud in ipairs(excel_list) do
        local line = stud
        local mnems = stud2tasks[stud]
        assert(mnems)
        for _, mnem in ipairs(mnems) do
            line = line .. '\t' .. checkall.score_of(stud, mnem)
        end
        print(line)
    end
end

-- http://stackoverflow.com/a/4521960
if not pcall(debug.getlocal, 4, 1) then
    pr_name = arg[1]
    local N = tonumber(arg[2] or 30)
    local tsv = arg[3] -- table "stud task1 task2"
    local stud = arg[4]
    if stud then
        excel_list = {stud}
    end
    local prac = require(pr_name)
    krcheck.read_tsv(tsv)
    krcheck.checkall(prac, N)
    krcheck.print_results(prac)
end

