-- daniel guimarães - 1910462 - adaptado do código fornecido em aula

local meusblips
local player
local state = "game"  -- "game" , "win", "lose"

local function newblip (vel, initialx)
  local x = initialx or 0
  local y = 0
  local tam = 40
  local laps = 0
  local isimortal = false
  local isdead = false
  return {
    update = function (dt, cbimortal, cbunimortal)
      if isdead then return end

      local width, _ = love.graphics.getDimensions( )
      x = x+(vel+1)*dt*40
      if x > width then
        -- volta para a esquerda da janela
        x = 0
        laps = laps + 1
        if laps == 3 then 
          isimortal = true
          cbimortal()
        elseif laps >= 5 then
          isimortal = false
          laps = 0
          cbunimortal()
        end
      end
    end,
    affected = function (pos)
      if isimortal or isdead then return false end

      if pos>x and pos<x+tam then
      -- "pegou" o blip
        return true
      else
        return false
      end
    end,
    kill = function ()
      isdead = true
    end,
    draw = function ()
      if isdead then return end
      if isimortal then love.graphics.setColor(255, 0, 0, 255) end
      love.graphics.rectangle("line", x, y, tam, 10)
      if isimortal then love.graphics.setColor(255, 255, 255, 255) end
    end
  }
end

local function newplayer ()
  local x, y = 0, 200
  local tam = 30
  local width, height = love.graphics.getDimensions( )
  local isimortal = false

  return {
    try = function ()
      return x + tam/2
    end,
    update = function (dt)
      x = x - 5 * 30 * dt
      if x < 0 then
        x = width - tam
      end

    end,
    draw = function ()
      love.graphics.rectangle("line", x, y, tam, 10)
    end
  }
end

local function newblips ()
  local blips = {}
  local qimortals = 0
  local qkills = 0

  -- INIT
  -- gera os blips
  for i = 1, 10 do
    blips[i] = newblip(
      5 + love.math.random() * 7,
      love.math.random() * 400
    )
  end

  local function cbimortal()
    qimortals = qimortals + 1
  end

  local function cbunimortal()
    qimortals = qimortals - 1
  end

  return {
    update = function (dt)
      if qkills == #blips then
        state = "win"
        return
      elseif qimortals == #blips - qkills then 
        state = "lose"
        return
      end

      for i = 1, #blips do blips[i].update(dt, cbimortal, cbunimortal) end
    end,
    affected = function (pos)
      for i = 1, #blips do
        if blips[i].affected(pos) then
          blips[i].kill()
          qkills = qkills + 1
        end
      end
    end,
    draw = function ()
      for i = 1, #blips do blips[i].draw() end
      love.graphics.print(tostring(qkills), 300, 300)
      love.graphics.print(tostring(qimortals), 350, 300)
    end
  }
end

function drawstate ()
  if state == "win" then
    love.graphics.print("winner", 400, 300)
  elseif state == "lose" then
    love.graphics.print("loser", 400, 300)
  end
end

function love.keypressed (key)
  if state == "game" then
    if key == 'space' then
      pos = player.try()
      meusblips.affected(pos)
    end
  else
    if key == 'space' then
      state = "game"
      player = newplayer()
      meusblips = newblips()
    end
  end
end

function love.load()
  player =  newplayer()
  meusblips = newblips()
end

function love.draw()
  if state ~= "game" then
    drawstate()
  else
    player.draw()
    meusblips.draw()
  end
end

function love.update(dt)
  if state == "game" then
    player.update(dt)
    meusblips.update(dt)
  end
end
  
function love.quit ()
  love.window.close()
  os.exit()
end