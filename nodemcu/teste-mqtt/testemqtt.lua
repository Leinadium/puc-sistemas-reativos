-- MUDAR meu id!!!!
local meuid = "A11"
local m = mqtt.Client("clientid " .. meuid, 120)

local led1 = 0
local led2 = 6
gpio.mode(led1, gpio.OUTPUT)
gpio.mode(led2, gpio.OUTPUT)
local debaucingTime=50 -- millisec.

local bt={}

for tx=1,2 do
  bt[tx]={}
  bt[tx].enabled=true
  bt[tx].trigType="down"
  bt[tx].pullup=gpio.PULLUP
end

bt[1].pin=3 -- Internal PullUp: open = high
bt[2].pin=4 -- Internal PullUp: open = high

local function btTrig(tx, when)
  print("Bt: " .. tx)
  publica(m, tostring(tx))
end

function publica(c, msg)
  c:publish("paraloveA11",msg,0,0, 
            function(client) print("mandou!") end)
end

function recebe(msg)
  if (msg == "1") then
    gpio.write(led1,((gpio.read(led1)==1) and 0) or 1) 
  elseif (msg == "2") then
    gpio.write(led1,((gpio.read(led2)==1) and 0) or 1)
  end
end

function novaInscricao (c)
  local msgsrec = 0
  function novamsg (c, t, m)
    print ("mensagem ".. msgsrec .. ", topico: ".. t .. ", dados: " .. m)
    recebe(m)
  end
  c:on("message", novamsg)
end

function conectado (client)
  -- publica(client)
  client:subscribe("paranodeA11", 0, novaInscricao)
end 

m:connect("139.82.100.100", 7981, false, 
             conectado,
             function(client, reason) print("failed reason: "..reason) end)

             
for tx=1,2 do
  gpio.mode(bt[tx].pin,gpio.INT,bt[tx].pullup)
  gpio.trig(bt[tx].pin,bt[tx].trigType,
       function(level,when,count)
         if bt[tx].enabled then
       bt[tx].enabled=false
           tmr.create():alarm(debaucingTime, tmr.ALARM_SINGLE, function(t) bt[tx].enabled=true end )
           btTrig(tx,when) 
         end 
       end) --  gpio.trig
end