-- luarocks install ansicolors
local colors = require 'ansicolors'

function string.trim(self)
    local text = self:gsub("%s+$", "")
    text = text:gsub("^%s+", "")
    return text
end

local a, b

local sims2 = io.open('sims2.txt', 'a')

sims2:write('\n\n=========\n\n')

local wdiff_cmd = 'wdiff %s %s | colordiff'
local sdiff_cmd = 'sdiff -dBWbEi --strip-trailing-cr %s %s'

local diff = function(a, b, cmd0)
    print('==========================')
    local cmd = string.format(cmd0, a, b)
    os.execute(cmd)
    print('')
end

local bold = function(text)
    return colors('%{bright red}' .. text:sub(1, 1) ..
           '%{reset}' .. text:sub(2))
end

local get_sol = function()
    local sol
    while not sol or not ('ynws'):find(sol) do
        print('')
        io.write(('similar? (%s/%s/%s/%s) '):format(
            bold('yess'), bold('no'),
            bold('wdiff'), bold('sdiff')))
        sol = io.read()
    end
    return sol
end

for line0 in io.lines('sims.txt') do
    local line = line0:trim()
    if #line >= 1 then
        if not a then
            a = line
        else
            b = line
            diff(a, b, wdiff_cmd)
            while true do
                local sol = get_sol()
                if sol == 'y' then
                    sims2:write(a .. '\n' .. b .. '\n\n')
                    sims2:flush()
                    break
                end
                if sol == 'n' then
                    break
                end
                if sol == 'w' then
                    diff(a, b, wdiff_cmd)
                end
                if sol == 's' then
                    diff(a, b, sdiff_cmd)
                end
            end
            a = nil
            b = nil
        end
    end
end

sims2:close()

