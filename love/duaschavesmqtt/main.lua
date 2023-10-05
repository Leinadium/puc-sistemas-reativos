
local mqtt = require("mqtt_library")
local TAM = 400
local cores = {}
cores[1] = {
  {1,0,0},
  {0.6, 0, 0}
}
cores[2] = {
  {0.5,1,0},
  {0.35,0.4,0.2}
}
local botoes = {}
  
local function mqttcb (msg)
  print(msg)
  if (msg == "1") then
    mudaestado(1)
  elseif (msg == "2") then
    mudaestado(2)
  end
end

function love.load ()
  love.window.setMode(TAM,TAM)
  love.graphics.setBackgroundColor(0,0,0)

  for i = 1, 2 do
    botoes[i] = {cores = cores[i][1], x = i*TAM/3, y = TAM/2, r = TAM/8}
  end

  mqtt_client = mqtt.client.create("139.82.100.100", 7981, mqttcb)
  -- Trocar XX pelo ID da etiqueta do seu NodeMCU
  mqtt_client:connect("cliente love A11")
  mqtt_client:subscribe({"paraloveA11"})
end

local function nodisco (botao, mx, my)
  return math.sqrt((mx-botao.x)^2 + (my-botao.y)^2) < botao.r
end

local function mudaestado (i)
  if botoes[i].cores == cores[i][1] then
    botoes[i].cores = cores[i][2]
  else
    botoes[i].cores = cores[i][1]
  end
end

function love.mousepressed (mx, my)
  for i = 1, 2 do
    if nodisco (botoes[i], mx, my) then
      print ("no disco ", i)
      -- Trocar XX pelo ID da etiqueta do seu NodeMCU
      mqtt_client:publish("paranodeA11", i)
      mudaestado(i)
    end
  end
end

function love.update(dt)
  -- tem que chamar o handler aqui!
  mqtt_client:handler()
end

function love.draw ()
  for i = 1, 2 do
    love.graphics.setColor(botoes[i].cores[1], botoes[i].cores[2], botoes[i].cores[3])
    love.graphics.circle ("fill", botoes[i].x, botoes[i].y, botoes[i].r, 64)
  end
end

function love.quit()
  os.exit()
end
