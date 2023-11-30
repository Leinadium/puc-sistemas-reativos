local mqtt = require("mqtt")

local M = {}

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

M.Client = Client
return M