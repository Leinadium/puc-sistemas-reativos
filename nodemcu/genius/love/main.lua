-- implementacao do jogo genius em lua/love
-- daniel guimaraes - 1910462
require "love"
require "os"
local game = require("game")

local g

function love.load(arg)
    game.init()
    g = game.getgame()
    g.setup()
end

function love.draw()
    g.draw()
end

function love.update(dt)
    g.update(dt)
end

function love.quit()
    love.window.close()
    os.exit(1)
end