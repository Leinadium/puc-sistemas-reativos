local mqtt = require("mqtt")
local gpio = require("gpio")
local pwm = require("pwm")
local tmr = require("tmr")

Client = {
    meuid = "controle-genius",
    topico = 'genius',
    host = '10.1.1.113',    -- 139.82.100.100
    port = 1883,            -- 7981
    m = mqtt.Client,
}

function Client:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Client:init()
    self.m = mqtt.Client("clientid " .. self.meuid, 120)

    self.m:connect(
        self.host, 
        self.port, 
        false, 
        function (client) print("conectado") end,
        function (client, reason) print("failed reason: "..reason) end
    )
end

function Client:publish(msg)
    self.m:publish(self.topico, msg, 0, 0, 
        function(client) print("mandou!") end
    )
end


Controle = {
    buzzer = 7,
    debaucingTime = 200,
    bt = {},
    cbclient = nil,
    mapping = {
        [1] = 'UL',
        [2] = 'UR',
        [3] = 'DL',
        [4] = 'DR',
    }
}

function Controle:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Controle:init()
    -- configuracao basica dos botoes
    for tx=1, 4 do
        self.bt[tx]={}
        self.bt[tx].enabled=true
        self.bt[tx].trigType="down"
        self.bt[tx].pullup=gpio.PULLUP
    end
    self.bt[4].trigType="up"
    self.bt[4].pullup=gpio.FLOAT

    self.bt[1].pin=3 -- Internal PullUp: open = high
    self.bt[2].pin=4 -- Internal PullUp: open = high
    self.bt[3].pin=5 -- Internal PullUp: open = high
    self.bt[4].pin=8 -- Board PullDown: open = low

    -- callback dos botoes
    for tx=1, 4 do
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

function Controle:beep(freq, duration)
    pwm.stop(self.buzzer)
    pwm.setup(self.buzzer, freq, 512)
    pwm.start(self.buzzer)
    tmr.create():alarm(duration, tmr.ALARM_SINGLE, function() pwm.stop(self.buzzer) end)
end

function Controle:addcbclient(cbclient)
    self.cbclient = cbclient
end

function Controle:cbbotao(tx)
    print("Bt: " .. tx)
    self:beep(200 * tx, 500)
    if self.cbclient ~= nil then
        self.cbclient:publish(self.mapping[tx])
    end
end

-- main
local controle = Controle:new()
controle:init()

local client = Client:new()
client:init()
controle:addcbclient(client)
