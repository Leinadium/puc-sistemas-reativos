local tmr = require("tmr")
local note = require("note")

local M = {}

Game = {
    active = false,
    currentbeat = 0,
    period = 0,
    notes = {},
}

function Game:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- o jogo recebe as notas na seguinte decodificacao:
-- notesencoded é uma string, em que cada caracter representa uma nota
-- o caracter é um byte na forma 0bXXXXXXTT, onde:
-- XXXXXX é o offset da nota em relacao a ultima nota (em beats)
-- TT é o slot da nota (0 a 3 em binario)
function Game:decodepayload(notesencoded, period)
    self.notes = {}
    local lastbeat = 0
    for i = 1, #notesencoded do
        local byte = string.byte(notesencoded, i)
        local offset = bit.band(byte, 0b11111100) / 4
        local slot = bit.band(byte, 0b00000011)
        local beat = lastbeat + offset
        lastbeat = beat
        table.insert(self.notes, note.Note:new(beat, slot))
    end
    self.period = period
end

