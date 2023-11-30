local mqtt = require("mqtt")

local M = {}

Client = {
    meuid = "controle-guitarhero",
    topico = 'guitarhero',
    host = '10.1.1.113',
    port = 1883,
    m = mqtt.Client,
}

function Client:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Client:init(msgcb)
    self.m = mqtt.Client("clientid " .. self.meuid, 120)

    local function onconnect(client)
        client:subscribe(
            self.topico,
            0, 
            function(client)
                client:on("message", msgcb)
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
    self.m:publish(self.topico, msg, 0, 0, 
        function(client) print("mandou!") end
    )
end

M.Client = Client
return M