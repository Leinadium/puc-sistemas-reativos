local note = require("note")

local M = {}

Console = {
    -- TODO
}

function Console:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Console:notesencoded(notes)
    local lastbeat = 0
    local notesencoded = ""
    for i, n in ipairs(notes) do
        local offset = n.beat - lastbeat
        lastbeat = n.beat
        local byte = offset * 4 + n.slot
        notesencoded = notesencoded .. string.char(byte)
    end
    return notesencoded
end

M.Console = Console
return M