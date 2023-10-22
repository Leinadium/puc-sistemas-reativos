require "coroutine"

local M = {}

Queue = {
    -- diz qual o intervalo de chamadas da corotina
    limitseg = 0,
    -- implementacao da fila de corotinas
    queue = {},
    -- implementacao da fila de callbacks
    callbacks = {},
    -- flag para saber se existe uma coritina executando
    isexecuting = false,
    -- indice da corotina atual
    current = 0,
    -- tamanho da fila
    size = 0,
    -- buffer de tempo
    timebuffer = 0,
}

-- cria uma nova fila
function Queue:new(limit)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.limitseg = limit
    return o
end

-- reseta a fila
function Queue:reset()
    self.queue = {}
    self.callbacks = {}
    self.isexecuting = false
    self.current = 0
    self.size = 0
    self.timebuffer = 0
end

-- adiciona uma nova corotina e callback associado
-- se a fila estiver vazia, executa a corotina
function Queue:add(co, cb)
    self.size = self.size + 1
    table.insert(self.queue, self.size, co)
    table.insert(self.callbacks, self.size, cb)
    if not self.isexecuting then
        self:marknext()
    end
end

function Queue:marknext()
    self.isexecuting = true
    self.current = self.current + 1
    self.timebuffer = self.limitseg + 1
end

-- atualiza as corotinas
function Queue:update(dt)
    if self.size == 0 or not self.isexecuting then return end

    self.timebuffer = self.timebuffer + dt
    if self.timebuffer > self.limitseg then
        -- se passou do limite, executa
        self.timebuffer = 0
        coroutine.resume(self.queue[self.current])
    
        if coroutine.status(self.queue[self.current]) == "dead" then
            -- se a corotina acabou, chama o callback
            local cb = self.callbacks[self.current]
            if cb ~= nil then cb() end
            self.isexecuting = false
            -- verifica se tem alguma corotina na fila, e insere
            -- na fila de execucao
            if self.current ~= self.size then
                self:marknext()
            end            
        end

    end
end

M.Queue = Queue

return M