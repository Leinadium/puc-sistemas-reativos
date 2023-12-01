local gpio = require("gpio")
local pwm = require("pwm")
local tmr = require("tmr")

local M = {}

Botoes = {
    buzzer = 7,
    debaucingTime = 100,
    bt = {},
    cbclient = nil,
    mapping = {
        [1] = 2, -- UL,
        [2] = 3, -- UR,
        [3] = 1, -- DL,
        [4] = 4, -- DR,
    }
}

function Botoes:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Botoes:init()
    -- configuracao basica dos botoes
    for tx = 1, 4 do
        self.bt[tx] = {}
        self.bt[tx].enabled = true
        self.bt[tx].trigType = "down"
        self.bt[tx].pullup = gpio.PULLUP
    end
    self.bt[4].trigType = "up"
    self.bt[4].pullup = gpio.FLOAT

    self.bt[1].pin = 3 -- Internal PullUp: open = high
    self.bt[2].pin = 4 -- Internal PullUp: open = high
    self.bt[3].pin = 5 -- Internal PullUp: open = high
    self.bt[4].pin = 8 -- Board PullDown: open = low

    -- callback dos botoes
    for tx = 1, 4 do
        local bttx = self.bt[tx]
        gpio.mode(bttx.pin, gpio.INT, bttx.pullup)
        gpio.trig(bttx.pin, bttx.trigType, function (level, when, count)
            if bttx.enabled then
                bttx.enabled = false
                tmr.create():alarm(self.debaucingTime, tmr.ALARM_SINGLE, function(t) bttx.enabled = true end)
                self:cbbotao(tx)
            end
        end)
    end
end

function Botoes:beep(freq, duration)
    pwm.stop(self.buzzer)
    pwm.setup(self.buzzer, freq, 512)
    pwm.start(self.buzzer)
    tmr.create():alarm(duration, tmr.ALARM_SINGLE, function() pwm.stop(self.buzzer) end)
end

function Botoes:addcbclient(cbclient)
    self.cbclient = cbclient
end

function Botoes:cbbotao(tx)
    if self.cbclient ~= nil then
        self.cbclient(self.mapping[tx])
    end
end

M.Botoes = Botoes
return M