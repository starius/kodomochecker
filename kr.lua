-- run:
-- $ lua kr.lua pr12 2

local h = require 'helpers'
local kurs1 = require 'kurs1'

local pr_name = arg[1]
local ntasks_per_stud = tonumber(arg[2])

local pr = require(pr_name)
local tasks = h.get_tasks(pr)
local studs = kurs1.excel_list

local all_tasks = {}
while #all_tasks < #studs * ntasks_per_stud do
    for _, task in ipairs(tasks) do
        table.insert(all_tasks, task)
    end
end
for _, stud in ipairs(studs) do
    io.write(stud)
    local used = {}
    for i = 1, ntasks_per_stud do
        local task
        while not task do
            local j = math.random(1, #all_tasks)
            local task1 = all_tasks[j]
            if not used[task1] then
                used[task1] = true
                task = task1
                table.remove(all_tasks, j)
            end
        end
        io.write('\t' .. task)
    end
    io.write('\n')
end



