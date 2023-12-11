local mqtt = require("mqtt")
local gpio = require("gpio")
local pwm = require("pwm")
local tmr = require("tmr")

Client = {
    meuid = "controle-asteroid-",
    topico = 'asteroid',
    host = '139.82.100.100',    -- 139.82.100.100
    port = 7981,            -- 7981
    m = mqtt.Client,
    ident = '',
}

function Client:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Client:init()
    -- gera um ident aleatorio
    math.randomseed(tmr.time())
    self.ident = tostring(math.random(1000000))

    self.m = mqtt.Client("clientid " .. self.meuid .. self.ident, 120)

    self.m:connect(
        self.host, 
        self.port, 
        false, 
        function (c) print("conectado") end,
        function (c, reason) print("failed reason: "..reason) end
    )
end

function Client:publish(text, state)
    local msg = self.ident .. ',' .. text .. ',' .. tostring(state)

    self.m:publish(self.topico, msg, 0, 0,
        function(c) print("mandou!") end
    )
end


Controle = {
    buzzer = 7,
    debaucingTime = 50,
    bt = {},
    cbclient = nil,
    mapping = {
        [1] = 'left',       -- UL
        [2] = 'right',      -- UR
        [3] = 'up',         -- DL
        [4] = 'shot',       -- DR
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
        self.bt[tx].whatisdown=gpio.LOW
        self.bt[tx].pullup=gpio.PULLUP
    end
    self.bt[4].whatisdown=gpio.HIGH
    self.bt[4].pullup=gpio.FLOAT

    self.bt[1].pin=3 -- Internal PullUp: open = high
    self.bt[2].pin=4 -- Internal PullUp: open = high
    self.bt[3].pin=5 -- Internal PullUp: open = high
    self.bt[4].pin=8 -- Board PullDown: open = low

    -- callback dos botoes
    for tx=1, 4 do
        local bttx = self.bt[tx]
        gpio.mode(bttx.pin, gpio.INT, bttx.pullup)
        gpio.trig(bttx.pin, "both", function (level, when, count)
            if bttx.enabled then

                bttx.enabled = false
                tmr.create():alarm(self.debaucingTime, tmr.ALARM_SINGLE, function(t) 
                    bttx.enabled = true
                    local state = gpio.read(bttx.pin)
                    self:cbbotao(tx, state == bttx.whatisdown)
                end)
                
                -- self:cbbotao(tx, level == bttx.whatisdown)
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

function Controle:cbbotao(tx, state)
    if self.cbclient ~= nil then
        self.cbclient:publish(self.mapping[tx], state)
    end
end

-- main
local controle = Controle:new()
controle:init()

local client = Client:new()
client:init()
controle:addcbclient(client)
