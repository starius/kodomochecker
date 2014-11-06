local checkpy = {}

local helpers = require('helpers')

local pf = string.format

checkpy.checkpy = function(task, py)
    if not checkpy.tmpin_fname then
        checkpy.tmpin_fname = os.tmpname()
    end
    if not checkpy.tmpout_fname then
        checkpy.tmpout_fname = os.tmpname()
    end
    local task_in, task_check, task_in_repr = task()
    if not task_in_repr then
        task_in_repr = task_in
    end
    local tmpin = io.open(checkpy.tmpin_fname, 'w')
    tmpin:write(task_in .. '\n\n\n')
    tmpin:close()
    local cmd = pf('python %s < %s > %s 2>&1', py,
        checkpy.tmpin_fname, checkpy.tmpout_fname)
    local run_ok = helpers.execute(cmd)
    local tmpout = io.open(checkpy.tmpout_fname, 'r')
    local task_out = tmpout:read('*a')
    tmpout:close()
    if not run_ok then
        return false, 'ошибка в коде (python)', 'none',
            task_in_repr, task_out
    end
    local ok, message, task_out_repr = task_check(task_out)
    if not task_out_repr then
        task_out_repr = task_out
    end
    if not ok then
        return false, 'выход программы не принимается', message,
            task_in_repr, task_out_repr
    end
    return true
end

return checkpy

