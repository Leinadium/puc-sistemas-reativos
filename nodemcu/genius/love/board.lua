require "love"
require "coroutine"

local queue = require("queue")

local M = {}

local swidth, sheight

local colors = {
    {1, 0, 0},
    {0, 1, 0},
    {0, 0, 1},
    {1, 1, 0}
}

local mapping = {
    ['UL'] = 3,
    ['UR'] = 4,
    ['DL'] = 2,
    ['DR'] = 1,
}

Board = {
    level = 0,
    sequence = {},
    step = 0,
    current = {false, false, false,false},
    coqueue = queue.Queue:new(0.5),
    temp = '',
}

function Board:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self     -- TODO: estudar o que significa isso
    return o
end

-- Retorna o nivel e o passo atual
function Board:getinfo()
    return self.level, self.step
end

-- Reinicia o tabuleiro
function Board:reset()
    self.current = {false, false, false, false}
    self.sequence = {}
    self.level = 0
    self.step = 0
    self.coqueue:reset()
end

-- Avanca de nivel
function Board:nextlevel()
    self.level = self.level + 1
    table.insert(self.sequence, math.random(1, 4))
    self.step = 1
end

-- Cria um pequeno intervalo usando corotinas
function Board:dointerval()
    self.coqueue.add(
        coroutine.create(function () 
            coroutine.yield()
        end),
        nil
    )
end

-- Cria a corotina da sequencia
-- e salva o callback do jogo para quando ela acabar
function Board:dosequence(finishcb)    
    self.coqueue:add(
        coroutine.create(function ()
            self.step = 0
            coroutine.yield()   -- para dar um tempinho
            for i = 1, #self.sequence do
                coroutine.yield()
                self.step = i   -- atualiza o passo
                self.current[self.sequence[i]] = true
                coroutine.yield()
                self.current[self.sequence[i]] = false
            end
        end),
        function () 
            self.step = 1
            finishcb() 
        end
    )
end

-- Cria a corotina de erro
function Board:doerror(wrong, right)
    self.coqueue:add(
        coroutine.create(function ()
            self.current[wrong] = true
            while true do
                self.current[right] = true
                coroutine.yield()
                self.current[right] = false
                coroutine.yield()
            end
        end),
        nil
    )
end

-- Cria a corotina de seleção
function Board:doselection(selection)
    self.coqueue:add(
        coroutine.create(function ()
            self.current[selection] = true
            coroutine.yield()
            self.current[selection] = false
            -- coroutine.yield()
        end),
        nil
    )
end

-- Seleciona o botão x
--   Retorna `true` se acabou a sequencia
--   Retorna `false` se errou a sequencia
--   Retorna `nil` se ainda nao acabou
function Board:select(direction)
    -- converte a direcao para o botao
    local x = mapping[direction]
    self.temp = direction

    -- se tiver uma corotina rodando, ignora
    if self.coqueue.isexecuting then return nil end

    -- se for certo, mostra usando a corotina de selecao
    if self.sequence[self.step] == x then
        self:doselection(x)
        self.step = self.step + 1
        -- verifica se acabou
        if self.step > #self.sequence then
            self:nextlevel()
            return true
        end
        return nil
    -- se for errado, mostra usando a corotina do erro
    else
        self:doerror(x, self.sequence[self.step])
        return false
    end
    return nil
end

-- Atualiza o tabuleiro
function Board:update(dt)
    self.coqueue:update(dt)
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
            love.graphics.setColor(colors[i][1] * 0.3, colors[i][2] * 0.3, colors[i][3] * 0.3)
        end
        love.graphics.arc("fill", x, y, radius, angle, angle + astep)
        angle = angle + astep
    end

    -- prints de debug
    love.graphics.print("temp " .. tostring(self.temp), 10, 30)
    
    -- love.graphics.print("level " .. tostring(self.level), 10, 30)
    -- love.graphics.print("sequence " .. tostring(sequence), 10, 50)
    -- love.graphics.print("sequence " .. tostring(#self.sequence), 10, 150)
    -- for i = 1, #self.sequence do
    --     love.graphics.print(tostring(self.sequence[i]), 10*i + 100, 150)
    -- end
    -- love.graphics.print("currentco " .. tostring(self.currentco), 10, 70)
    -- love.graphics.print("timebuffer " .. tostring(self.timebuffer), 10, 90)
    -- love.graphics.print("step " .. tostring(self.step), 10, 170)
    -- love.graphics.print("#queue " .. tostring(self.coqueue.size) .. tostring(self.coqueue.current), 10, 190)
    -- love.graphics.print("#callbacks" .. tostring(#self.coqueue.callbacks), 10, 210)
    -- love.graphics.print("isexecuting " .. tostring(self.coqueue.isexecuting), 10, 230)
end

function M.init()
    swidth, sheight = love.graphics.getDimensions()
end

M.Board = Board

return M