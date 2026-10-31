local DIR_SEP = package.config:sub(1, 1)
local yue = require("yue")
local chunk, error = yue.loadfile("src" .. DIR_SEP .. "conf.yue")
if chunk then
    chunk()
end