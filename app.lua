local lapis = require("lapis")
local app = lapis.Application()

app.layout = require("views.layout")

app:get("/", function()
    return {render = 'form'}
end)

app:post("send", "/send", function(self)
    local file = self.params.uploaded_file
    if not file or not file.filename or
            file.filename == '' then
        return 'No Python file uploaded'
    end
    local fname = '/tmp/' .. file.filename
    fname = fname:gsub('%s', '')
    local f = io.open(fname, 'w')
    f:write(file.content)
    f:close()
    --
    local r = io.popen('luajit checkone.lua ' .. fname, 'r')
    local result = r:read('*a')
    r:close()
    return ([[<h2>Файл %s</h2>
    <button onclick="window.history.back()">Go back</button>
    <pre>%s</pre>]]):format(file.filename, result)
end)

return app

