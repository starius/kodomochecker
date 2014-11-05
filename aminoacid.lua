local aa = {}

aa.aas = {'A', 'R', 'N', 'D', 'C', 'Q', 'E', 'G', 'H',
    'I', 'L', 'K', 'M', 'F', 'P', 'S', 'T', 'W', 'Y', 'V'}

aa.classes = {}

aa.classes['non-polar'] = {'C', 'V', 'I', 'L', 'M', 'F',
    'Y', 'W', 'H', 'K', 'A', 'G'}

aa.classes.small = {'C', 'V', 'A', 'G', 'D', 'P',
    'S', 'T', 'N'}

aa.classes.tiny = {'G', 'S', 'T', 'C', 'A'}

aa.classes.aliphatic = {'I', 'V', 'L'}

aa.classes.aromatic = {'F', 'Y', 'W', 'H'}

aa.classes.polar = {'C', 'S', 'T', 'N', 'D',
    'Y', 'W', 'H', 'K', 'R', 'E', 'Q'}

aa.classes.positive = {'H', 'K', 'R'}

aa.classes.charged = {'H', 'K', 'R', 'D', 'E'}

aa.aa2props = {}

for cl, aas in pairs(aa.classes) do
    for _, a in ipairs(aas) do
        if aa.aa2props[a] == nil then
            aa.aa2props[a] = {}
        end
        table.insert(aa.aa2props[a], cl)
    end
end

return aa

