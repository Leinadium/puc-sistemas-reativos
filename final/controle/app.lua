-- daniel guimaraes - 1910462
-- controle do guitar hero

local game = require "game"
local client = require "client"
local botoes = require "botoes"

-- criando as variaveis
local game = game.Game:new()
local client = client.Client:new()
local botoes = botoes.Botoes:new()

-- ligando os callbacks
game:addcbs(
    function(slot) client:hit(slot) end,        -- hitcb
    function(slot) client:miss(slot) end,       -- misscb
    function() botoes:beep(440, 0.1) end        -- beatcb
)

botoes:addcbclient(
    function(slot) game:setpressed(slot) end    -- cbbotao
)

client:init(
    function(period, notes, timestamp) game:reset(notes, period, timestamp) end, -- configcb
    function() game:stop() end                                                  -- stopcb
)