require "love"
require "coroutine"

local M = {}

local swidth, sheight

local colors = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {1, 1, 0}}

Board = {
    level = 0,
    sequence = {},
    step = 0,
    current = {false, false, false,false},
    timebuffer = 0,
    currentco = nil,
    gamecb = nil,
}

function Board:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self     -- TODO: estudar o que significa isso
    return o
end

-- Reinicia o tabuleiro
function Board:reset()
    self.sequence = {false, false, false, false}
    self.level = 0
    self.step = 0
end

-- Avanca de nivel
function Board:nextlevel()
    self.level = self.level + 1
    table.insert(self.sequence, math.random(1, 4))
    self.step = 0
end

-- Cria a corotina da sequencia
-- e salva o callback do jogo para quando ela acabar
function Board:dosequence(finishcb)    
    self.currentco = coroutine.create(function ()
        for i = 1, #self.sequence do
            self.current[i] = true
            coroutine.yield()
            self.current[i] = false
            coroutine.yield()
        end
    end)
    self.gamecb = finishcb
end

-- Cria a corotina de erro
function Board:doerror(wrong, right)
    self.currentco = coroutine.create(function ()
        self.current[wrong] = true
        while true do
            self.current[right] = true
            coroutine.yield()
            self.current[right] = false
            coroutine.yield()
        end
    end)
end

-- Cria a corotina de seleção
function Board:doselection(selection)
    self.currentco = coroutine.create(function ()
        self.current[selection] = true
        coroutine.yield()
        self.current[selection] = false
        -- coroutine.yield()
    end)
end

-- Seleciona o botão x
--   Retorna `true` se acabou a sequencia
--   Retorna `false` se errou a sequencia
--   Retorna `nil` se ainda nao acabou
function Board:select(x)
    -- se tiver uma corotina rodando, ignora
    if self.currentco ~= nil then return end
    -- se for certo, mostra usando a corotina de selecao
    if self.sequence[self.step] == x then
        self:doselection(x)
        self.step = self.step + 1
        -- verifica se acabou
        if self.step > #self.sequence then
            self:nextlevel()
            return true
        end
    -- se for errado, mostra usando a corotina do erro
    else
        self:doerror(x, self.sequence[self.step])
        return false
    end
end

-- Atualiza o tabuleiro
function Board:update(dt)
    if self.currentco ~= nil then
        -- adiciona o tempo ao buffer
        self.timebuffer = self.timebuffer + dt
        if self.timebuffer > 0.5 then
            -- se passou mais de meio segundo, executa a corotina
            self.timebuffer = 0
            if not coroutine.resume(self.currentco) then
                -- se acabou a corotina, limpa as variaveis
                -- e chama o callback do game
                self.currentco = nil
                if self.gamecb ~= nil then self:gamecb() end
                self.gamecb = nil
            end
        end
    end
end

-- Desenha o tabuleiro
function Board:draw()
    local x, y = swidth / 2, sheight / 2
    local radius = 200
    local angle = 0
    local astep = 2 * math.pi / 4

    for i = 1, 4 do
        -- fundo
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.arc("fill", x, y, radius + 10, angle, angle + astep)
        
        -- botao
        if self.current[i] then
            love.graphics.setColor(colors[i][1], colors[i][2], colors[i][3])
        else
            love.graphics.setColor(colors[i][1] * 0.5, colors[i][2] * 0.5, colors[i][3] * 0.5)
        end
        love.graphics.arc("fill", x, y, radius, angle, angle + astep)
        angle = angle + astep
    end

    -- prints de debug
    love.graphics.print("level " .. tostring(self.level), 10, 30)
    -- love.graphics.print("sequence " .. tostring(sequence), 10, 50)
    for i = 1, #self.sequence do
        love.graphics.print(tostring(self.sequence[i]), 10*i, 150)
    end
    love.graphics.print("currentco " .. tostring(self.currentco), 10, 70)
    love.graphics.print("timebuffer " .. tostring(self.timebuffer), 10, 90)
end


-- Game
Game = {
    state = "menu",     -- "menu", "computer", "player", "gameover"
    board = Board:new(),
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
        self.board:dosequence(function () self:setstate("player") end)
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
    -- button = 1, 2, 3 ou 4
    self.temp = self.temp + 1
    if self.state == "menu" then
        self.board:nextlevel()       -- gera o primeiro nivel
        self:setstate("computer")    -- mostra a sequencia

    elseif self.state == "player" then
        self:handleselection(self.board:select(button))
    end
end

function Game:update(dt)
    self.board:update(dt)
end

function Game:draw()
    love.graphics.print("state: " .. self.state, 10, 10)
    love.graphics.print("temp: " .. tostring(self.temp), 10, 110)
    self.board:draw()
end

-- temporario
function Game:setup()
    function love.keypressed(key, scancode, isrepeat)
        if key == "1" or key == "2" or key == "3" or key == "4" then
            self:buttonhandler(tonumber(key))
        end
    end
end

function M.init()
    swidth, sheight = love.graphics.getDimensions()
end

M.Game = Game
M.Board = Board

return M
