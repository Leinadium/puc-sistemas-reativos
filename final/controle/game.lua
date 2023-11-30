local tmr = require("tmr")
local note = require("note")

local M = {}

Game = {
    active = false,
    currentbeat = 0,
    period = 0,
    notes = {},
    pressed = {false, false, false, false},
    tmr = {},
    tmr2 = {},

    hitcb = function(slot) end,
    misscb = function(slot) end,
    beatcb = function() end
}

function Game:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Game:addcbs(hitcb, misscb, beatcb)
    self.hitcb = hitcb
    self.misscb = misscb
    self.beatcb = beatcb
end

function Game:reset(notesstr, period, timestamp)
    self.notes = self:decodepayload(notesstr)
    self.currentbeat = 0
    self.period = period
    self.pressed = {false, false, false, false}

    -- timestamp é o timestamp em segundos do inicio do jogo
    -- calcula o tempo de espera para o inicio do jogo
    local now = tmr.time()
    local wait = timestamp - now
    if wait < 0 then
        wait = 0
    end

    -- cria o timer para o start
    self.tmr:register(
        wait * 1000,
        tmr.ALARM_SINGLE,
        function() self:start() end
    )
    
end

-- o jogo recebe as notas na seguinte decodificacao:
-- notesencoded é uma string, em que cada caracter representa uma nota
-- o caracter é um byte na forma 0bXXXXXXTT, onde:
-- XXXXXX é o offset da nota em relacao a ultima nota (em beats)
-- TT é o slot da nota (0 a 3 em binario)
function Game:decodepayload(notesencoded)
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
end

function Game:processbeat()
    self.currentbeat = self.currentbeat + 1

    -- atualiza as notas
    local newnotes = {}
    for i, n in ipairs(self.notes) do

        -- se esta no beat atual
        if n:isbeat(self.currentbeat) then
            if self.pressed[n.slot] then
                self.hitcb(n.slot)
            end

        -- se ja passou do beat
        elseif n:isafterbeat(self.currentbeat) then
            self.misscb(n.slot)

        -- se nao aconteceu nada ainda
        else
            table.insert(newnotes, n)
        end

    end
    self.notes = newnotes
end

function Game:start()
    self.active = true
    self.currentbeat = 0
    self.pressed = {false, false, false, false}

    -- cria o timer para o processbeat
    self.tmr = tmr:create()
    self.tmr:register(
        self.period,
        tmr.ALARM_AUTO,
        function() self:processbeat() end
    )
    -- cria o timer para o setpressed
    self.tmr2 = tmr:create()
end

function Game:stop()
    self.active = false
    self.tmr:stop()
    self.tmr:unregister()
end

function Game:setpressed(slot)
    self.pressed[slot] = true

    -- cria o timer para o reset do pressed
    -- com tempo de release de metade do periodo
    self.tmr2:register(
        self.period / 2,
        tmr.ALARM_SINGLE,
        function() self.pressed[slot] = false end
    )
    self.tmr2:start()
end