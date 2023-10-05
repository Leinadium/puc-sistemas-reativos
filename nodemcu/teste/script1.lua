local debaucingTime=50 -- millisec.
local led1=0
local led2=6
local buzzer=7
local ldr=0 -- ADC A0
gpio.mode(led1,gpio.OUTPUT)
gpio.mode(led2,gpio.OUTPUT)

local bt={}

for tx=1,4 do
  bt[tx]={}
  bt[tx].enabled=true
  bt[tx].trigType="down"
  bt[tx].pullup=gpio.PULLUP
end
bt[4].trigType="up"
bt[4].pullup=gpio.FLOAT
bt[1].pin=3 -- Internal PullUp: open = high
bt[2].pin=4 -- Internal PullUp: open = high
bt[3].pin=5 -- Internal PullUp: open = high
bt[4].pin=8 -- Board PullDown: open = low

local function beep(freq,duration)
  pwm.stop(buzzer)
  pwm.setup(buzzer, freq, 512)
  pwm.start(buzzer)
  tmr.create():alarm(duration, tmr.ALARM_SINGLE, function() pwm.stop(buzzer) end)
end

local function btTrig(tx,when)
  beep(200*tx,1000)
  --print("Bt: ".. tx, when)
end

for tx=1,4 do
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

local function pisca()
  local lum=100-(adc.read(ldr)/10.24)
  local delay = (lum+1)*10
  print(lum,delay)
  tmr.create():alarm(delay, tmr.ALARM_SINGLE, 
                  function()
                    gpio.write(led1,((gpio.read(led1)==1) and 0) or 1) 
                    gpio.write(led2,((gpio.read(led1)==1) and 0) or 1) 
                    pisca() 
                  end)
end

pisca()
