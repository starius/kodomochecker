function string.trim(self)
    local text = self:gsub("%s+$", "")
    text = text:gsub("^%s+", "")
    return text
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

local a, b

print('digraph {')

for line0 in io.lines() do
    local line = line0:trim()
    if #line >= 1 then
        if not a then
            a = line
        else
            b = line
            local a_name = a:split('/')[1]:gsub('%.', '_')
            local b_name = b:split('/')[1]:gsub('%.', '_')
            print(string.format('%s -> %s;', a_name, b_name))
            a = nil
            b = nil
        end
    end
end

print('}')

