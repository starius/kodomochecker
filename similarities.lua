local sh = require 'sh'

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

unpack = unpack or table.unpack

local sims_str = sh([[sim_text -n */term1/block3/credits/*.py | grep -v 'File'|grep -v kurs1|grep -v 'Total:'|grep -v '^$']])

local sims = sims_str:split('\n')

for _, hit in ipairs(sims) do
    local a, b = unpack(hit:split('|'))
    if a and b then
        local a_name = a:split('/')[1]
        local b_name = b:split('/')[1]
        if a_name ~= b_name then
            local a_fname = a:split(':')[1]
            local b_fname = b:split(':')[1]
            print(a_fname)
            print(b_fname)
            print('')
        end
    end
end

