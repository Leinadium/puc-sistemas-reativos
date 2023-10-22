-- implementacao do jogo genius em lua/love
-- daniel guimaraes - 1910462
require "love"
require "os"
local game = require("game")
local controller = require("controller")

local g
local c

function love.load(arg)
    game.init()
    g = game.Game:new()
    g:setup()

    c = controller.Client:new()
    c:init()
    c:addcbclient(function(msg) g:controllercb(msg) end)

end

function love.draw()
    g:draw()
end

function love.update(dt)
    g:update(dt)
    c:handler()
end

function love.quit()
    love.window.close()
    os.exit(1)
end