local lapis = require("lapis")
local app = lapis.Application()

app.layout = require("views.layout")

app:get("/", function()
    return {render = 'form'}
end)

app:post("send", "/send", function(self)
    local file = self.params.uploaded_file
    if not file or not file.filename then
        return 'No Python file uploaded'
    end
    local fname = '/tmp/' .. file.filename
    fname = fname:gsub('%s', '')
    local f = io.open(fname, 'w')
    f:write(file.content)
    f:close()
    --
    r = io.popen('luajit checkone.lua ' .. fname, 'r')
    local result = r:read('*a')
    r:close()
    return '<button onclick="window.history.back()">' ..
    'Go back</button>' ..
    '<pre>' .. result .. '</pre>'
end)

return app

