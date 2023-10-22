require "love"
require "coroutine"
local board = require("board")

local M = {}

-- Game
Game = {
    state = "menu",     -- "menu", "computer", "player", "gameover"
    board = board.Board:new(),
    temp = 0,
}

function Game:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self     -- TODO: estudar o que significa isso
    return o
end

function Game:setstate(newstate)
    if newstate == self.state then return end
    if newstate == "menu" then
        self.board:reset()
    elseif newstate =="computer" then
        self.board:dosequence(
            function () self:setstate("player") end
        )
    end

    self.state = newstate
end

function Game:handleselection(status)
    -- se retornou nulo, só continua o jogo normalmente
    if status == nil then 
        return
    -- se retorn true, vai para o computador
    elseif status then 
        self:setstate("computer")
    else 
        self:setstate("gameover")
    end
end

function Game:buttonhandler(button)
    -- button = UL, UR, DL, DR
    self.temp = self.temp + 1
    if self.state == "menu" then
        self.board:nextlevel()       -- gera o primeiro nivel
        self:setstate("computer")    -- mostra a sequencia

    elseif self.state == "player" and button ~= nil then
        self:handleselection(self.board:select(button))
    elseif self.state == "gameover" then
        self:setstate("menu")
    end
end

function Game:update(dt)
    self.board:update(dt)
end

function Game:draw()
    love.graphics.push()
    love.graphics.setColor(1, 1, 1)
    if self.state == "menu" then
        love.graphics.print("Genius", 10, 20, 0, 1.5, 1.5)
        love.graphics.print("Pressione [SPACE] para iniciar o jogo", 10, 40, 0, 1.5, 1.5)
    elseif self.state == "computer" then
        love.graphics.print("Computador", 10, 20, 0, 1.5, 1.5)
        local l, s = self.board:getinfo()
        love.graphics.print(s .. "/" .. l, 10, 40, 0, 1.5, 1.5)
    elseif self.state == "player" then
        love.graphics.print("Sua vez", 10, 20, 0, 1.5, 1.5)
        local l, s = self.board:getinfo()
        love.graphics.print(s-1 .. "/" .. l, 10, 40, 0, 1.5, 1.5)
    else
        love.graphics.print("Fim de jogo", 10, 20, 0, 1.5, 1.5)
        local l, s = self.board:getinfo()
        love.graphics.print("Pontuação: " .. l-1, 10, 40, 0, 1.5, 1.5)
    end
    love.graphics.pop()


    self.board:draw()
end

function Game:controllercb(msg)
    if self.state == "menu" then
        self:buttonhandler(nil)
    else
        self:buttonhandler(msg)
    end
end

-- temporario
function Game:setup()
    function love.keypressed(key, scancode, isrepeat)
        if key == "1" or key == "2" or key == "3" or key == "4" then
            self:buttonhandler(tonumber(key))
        -- se for um espaco, manda um nulo
        elseif key == "space" then
            self:buttonhandler(nil)
        end
    end
end

M.Game = Game

M.init = function()
    board.init()
end

return M
