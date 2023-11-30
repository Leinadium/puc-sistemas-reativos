require("love")
local note = require("note")

local M = {}

Track = {
    notes = {},
    currentseg = 0,
    currentbeat = 0,
    period = 0,
}

function Track:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Track:reset(notes, period, hitcb, misscb)
    self.notes = notes
    self.currentseg = 0
    self.currentbeat = 0
    self.period = period
    self.pressed = {false, false, false, false}
end

function Track:setpressed(slot)
    self.pressed[slot] = true
end

function Track:update(dt)
    self.currentseg = self.currentseg + dt
    
    -- atualiza o beat
    if self.currentseg > self.period then
        -- self.currentseg = self.currentseg - self.period
        self.currentseg = self.currentseg - self.period
        self.currentbeat = self.currentbeat + 1
    
        -- atualiza as notas
        local newnotes = {}
        for i, n in ipairs(self.notes) do
            if not n:isafterbeat(self.currentbeat) then
                table.insert(newnotes, n)
            end
        end
        self.notes = newnotes
    
    end
end


function Track:draw()
    local distancebeats = 100
    local maxheight = love.graphics.getHeight()
    local maxwidth = love.graphics.getWidth()

    local function calcx(slot)
        return maxwidth / 5 * slot
    end

    local function calcy(beat)
        return maxheight - (beat - (self.currentbeat + self.currentseg / self.period)) * distancebeats
    end

    -- desenha os tracos verticais
    for i = 1, 4 do
        local x = calcx(i)
        love.graphics.line(x, 0, x, maxheight)
    end

    -- desenha as notas
    for i, n in ipairs(self.notes) do
        local x = calcx(n:getslot())
        local y = calcy(n:getbeat())
        love.graphics.circle("fill", x, y, 20)
    end

    -- debug
    love.graphics.print("currentbeat: " .. self.currentbeat, 10, 10)
    love.graphics.print("currentseg: " .. self.currentseg, 10, 30)
    love.graphics.print("period: " .. self.period, 10, 50)
end

M.Track = Track
return M