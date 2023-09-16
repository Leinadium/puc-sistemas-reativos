local discos = { {}, {}, {} }

local function desenha()
  local larg, alt = love.graphics.getDimensions()
  local x, y
  for i = 1, 3 do
    x = i*larg/5 + larg/10
    y = alt
    for j = 1, #discos[i] do
      love.graphics.setColor(1,1,1)
      love.graphics.rectangle ("line", x - discos[i][j]/2, y - alt/15, discos[i][j], alt/15)
      y = y - alt/15
    end
  end
end

local function move (origem, destino)
  local tam = table.remove (discos[origem])
  table.insert (discos[destino], tam)
end

local function hanoi (origem, destino, auxiliar, quantos)
  if (quantos > 0) then
    -- primeira recursao
    hanoi(origem, auxiliar, destino, quantos - 1)
    -- faz o yield para desenhar
    coroutine.yield()
    move(origem, destino)
    -- segunda recursao
    hanoi(auxiliar, destino, origem, quantos - 1)
  end
end

local function criapilha(from, n)
-- cria pilha com até 10 discos
  for i = 1, n do
    discos[from][i] = 100 - 10*i
  end
end

local totaltempoexib = 1 -- tempo entre trocas
local tempofalta -- conta tempo restante para troca
local co

function love.load(arg)
  love.window.setMode (800, 400)
  criapilha(1, 5)
  tempofalta = totaltempoexib
  -- cria a coroutine
  co = coroutine.create (hanoi)
  -- inicia a coroutine
  coroutine.resume (co, 1, 3, 2, 5)
end

function love.draw()
  love.graphics.setBackgroundColor(0,0,0)
  desenha()
end

function love.update (dt)
  tempofalta = tempofalta - dt
  if tempofalta < 0 then
    -- continua a coroutine
    coroutine.resume (co)
    tempofalta = totaltempoexib
  end
  -- hanoi(1, 3, 2, 5)
end

function love.quit ()
  os.exit()
end
