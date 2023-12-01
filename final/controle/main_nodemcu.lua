-- local gpio = require("gpio")
-- local pwm = require("pwm")
-- local tmr = require("tmr")
-- local mqtt = require("mqtt")

-----------------------------------------------------------------------
Note = {
    beat = 0,
    slot = 0,
}

function Note:new(beat, slot)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.slot = slot
    o.beat = beat
    return o
end

function Note:isonbeat(beat)
    return self.beat == beat
end

function Note:isafterbeat(beat)
    return beat > self.beat
end

function Note:getslot()
    return self.slot
end

function Note:getbeat()
    return self.beat
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
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
        local offset = bit.band(byte, 0xFC) / 4
        local slot = bit.band(byte, 0x03)
        local beat = lastbeat + offset
        lastbeat = beat
        table.insert(self.notes, Note:new(beat, slot))
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
-----------------------------------------------------------------------
-----------------------------------------------------------------------
Client = {
    meuid = "controle-guitarhero",
    topico = 'guitarhero',
    host = '10.1.1.99',
    port = 1883,
    m = mqtt.Client,
    configcb = function(period, notes, timestamp) end,
    stopcb = function() end,
}

function Client:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Client:msgcb(client, topic, data)
    -- data é uma string, separada por uma virgula
    -- os possiveis comandos sao os seguintes:
    -- "config,[period],[notes],[timestamp]"
    --      period é o periodo comum em segundos de cada beats
    --      notes é uma string, em que cada caracter representa uma nota
    --      timestamp é o timestamp em segundos do inicio do jogo
    -- "stop"
    --      sinaliza que o jogo deve ser encerrado
    -- "heartbeat"
    --      pergunta se o controle esta vivo

    local cmd = string.sub(data, 1, string.find(data, ",") - 1)
    local args = string.sub(data, string.find(data, ",") + 1)

    if cmd == "config" then
        local period = string.sub(args, 1, string.find(args, ",") - 1)
        args = string.sub(args, string.find(args, ",") + 1)
        local notes = string.sub(args, 1, string.find(args, ",") - 1)
        args = string.sub(args, string.find(args, ",") + 1)
        local timestamp = string.sub(args, 1, string.find(args, ",") - 1)
        args = string.sub(args, string.find(args, ",") + 1)

        self.configcb(period, notes, timestamp)
        self:publish("config_ok")

    elseif cmd == "stop" then
        self.stopcb()
        self:publish("stop_ok")
    
    elseif cmd == "heartbeat" then
        self:publish("heartbeat")
    end

end

function Client:init(
    configcb, -- callback de configuracao
    stopcb -- callback de parada
)
    self.configcb = configcb
    self.stopcb = stopcb
    self.m = mqtt.Client("clientid " .. self.meuid, 120)

    local function onconnect(client)
        client:subscribe(
            self.topico,
            0, 
            function(client)
                client:on("message", self.msgcb)
            end
        )
    end

    self.m:connect(
        self.host, 
        self.port, 
        false, 
        onconnect,
        function (client, reason) print("failed reason: "..reason) end
    )
end

function Client:publish(msg)
    -- o client manda as msgs no seguinte formato:

    -- "config_ok"
    -- sinaliza que recebeu a configuracao e vai iniciar 

    -- "stop_ok"
    -- sinaliza que recebeu o stop e vai parar

    -- "hit,[slot]"
    -- sinaliza que a nota do slot foi acertada

    -- "miss,[slot]"
    -- sinaliza que a nota do slot foi errada

    -- "heartbeat"
    -- sinaliza que o controle esta vivo

    self.m:publish(self.topico, msg, 0, 0, 
        function(client) print("mandou!") end
    )
end

function Client:hit(slot)
    self:publish("hit," .. slot)
end

function Client:miss(slot)
    self:publish("miss," .. slot)
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
Botoes = {
    buzzer = 7,
    debaucingTime = 100,
    bt = {},
    cbclient = function() end,
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

function Botoes:addcb(cb)
    self.cbclient = cb
end

function Botoes:cbbotao(tx)
    if self.cbclient ~= nil then
        self.cbclient(self.mapping[tx])
    end
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- daniel guimaraes - 1910462
-- controle do guitar hero
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- criando as variaveis
local function main()
    local game = Game:new()
    local client = Client:new()
    local botoes = Botoes:new()

    -- ligando os callbacks
    game:addcbs(
        function(slot) client:hit(slot) end,        -- hitcb
        function(slot) client:miss(slot) end,       -- misscb
        function() botoes:beep(440, 0.1) end        -- beatcb
    )

    botoes:addcb(
        function(slot) game:setpressed(slot) end    -- cbbotao
    )

    client:init(
        function(period, notes, timestamp) game:reset(notes, period, timestamp) end, -- configcb
        function() game:stop() end                                                  -- stopcb
    )
end

main()
