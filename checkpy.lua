local checkpy = {}

local helpers = require('helpers')
local h = helpers

local pf = string.format

checkpy.checkpy = function(task, py)
    if not checkpy.tmpdir_fname then
        local fname, d = h.tmp_file_and_deleter()
        checkpy.tmpdir_fname = fname
        checkpy.tmpdir_fname_d = d
        os.execute('rm ' .. fname)
        os.execute('mkdir ' .. fname)
        checkpy.tmpin_fname = fname .. '/' .. 'input.file'
        checkpy.tmpout_fname = fname .. '/' .. 'output.file'
    end
    local task_in, task_check, task_in_repr, argv = task()
    task_in_repr = task_in_repr or argv or task_in
    argv = argv or ''
    local tmpin = io.open(checkpy.tmpin_fname, 'w')
    tmpin:write(task_in .. '\n\n\n')
    tmpin:close()
    --
    local py_basename = py:gsub('.*/', '')
    local new_py
    if py:sub(1, 1) == '/' then
        -- py is absolute path
        new_py = py
    else
        -- py is relative path: prepend `pwd`
        new_py = helpers.pwd() .. '/' .. py
    end
    local interpreter = 'python'
    if new_py:find('lua$') then
        interpreter = 'luajit'
    end
    local cmd0 = pf('%s %s %s < %s > %s 2>&1',
        interpreter, new_py, argv,
        checkpy.tmpin_fname, checkpy.tmpout_fname)
    local cmd = pf('cd %s && %s', checkpy.tmpdir_fname, cmd0)
    local sh_script = checkpy.tmpdir_fname .. '/' .. '1.sh'
    h.write_file(sh_script, cmd)
    os.execute('chmod +x ' .. sh_script)
    local run_ok = helpers.execute(sh_script)
    --
    local tmpout = io.open(checkpy.tmpout_fname, 'r')
    local task_out = tmpout:read(1000000) -- max 1M
    tmpout:close()
    if not run_ok then
        return false, 'ошибка в программа', 'none',
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

