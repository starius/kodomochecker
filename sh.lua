return function(cmd)
    local f = io.popen(cmd, 'r')
    local out = f:read('*a')
    f:close()
    return out
end

