function string.trim(self)
    local text = self:gsub("%s+$", "")
    text = text:gsub("^%s+", "")
    return text
end

local a, b

local sims2 = io.open('sims2.txt', 'a')

sims2:write('\n\n=========\n\n')

for line0 in io.lines('sims.txt') do
    local line = line0:trim()
    if #line >= 1 then
        if not a then
            a = line
        else
            b = line
            print('==========================')
            local cmd = string.format(
                'wdiff %s %s | colordiff', a, b)
            os.execute(cmd)
            print('')
            local sol
            while sol ~= 'y' and sol ~= 'n' do
                print('')
                print('similar? (y/[n])')
                sol = io.read()
                if sol == '' then
                    sol = 'n'
                end
            end
            if sol == 'y' then
                sims2:write(a .. '\n' .. b .. '\n\n')
                sims2:flush()
            end
            a = nil
            b = nil
        end
    end
end

sims2:close()

