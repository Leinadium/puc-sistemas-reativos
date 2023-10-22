local mqtt = require("mqtt_library")

M = {}

Client = {
    meuid = "jogo-genius-oailsudhlas",
    topico = "genius",
    host = "10.1.1.113",
    -- host = "139.82.100.100",
    port = 1883,              -- 7981,
    m = {},
    cb = nil
}

function Client:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Client:init()
    mqtt.Utility.set_debug(true)
    self.m = mqtt.client.create(
        self.host, 
        self.port, 
        function (topic, msg) self:callback(msg) end
    )

    local x = self.m:connect(self.meuid)
    print(x)
    self.m:subscribe({self.topico})
end

function Client:callback(msg)
    if self.cb ~= nil then
        self.cb(msg)
    end
end

function Client:addcbclient(cb)
    self.cb = cb
end

function Client:handler()
    if self.m.connected then
        self.m:handler()
    end
end

M.Client = Client

return M