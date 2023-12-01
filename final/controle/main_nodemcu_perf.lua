-- local gpio = require("gpio")
-- local pwm = require("pwm")
-- local tmr = require("tmr")
-- local mqtt = require("mqtt")

-----------------------------------------------------------------------
local function getnote(beat, slot)
    local mbeat = beat
    local mslot = slot

    return {
        getbeat = function () return mbeat end,
        getslot = function () return mslot end,
        isonbeat = function (b)
            return beat == b
        end,
        isafterbeat = function (b)
            return beat > b
        end,
    }
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
local function getgame()
    local mactive = false
    local mcurrentbeat = 0
    local mperiod = 0
    local mnotes = {}
    local mpressed = {false, false, false, false}
    local mtmr = {}
    local mtmr2 = {}
    local mhitcb = function(slot) end
    local mmisscb = function(slot) end
    local mbeatcb = function() end

    local function decodepayload(notesencoded)
        local notes = {}
        local lastbeat = 0
        for i = 1, #notesencoded do
            local byte = string.byte(notesencoded, i)
            local offset = bit.band(byte, 0xFC) / 4
            local slot = bit.band(byte, 0x03)
            local beat = lastbeat + offset
            lastbeat = beat
            table.insert(notes, getnote(beat, slot))
        end
        return notes
    end

    local function processbeat()
        mcurrentbeat = mcurrentbeat + 1

        -- atualiza as notas
        local newnotes = {}
        for i, n in ipairs(mnotes) do

            -- se esta no beat atual
            if n.isonbeat(mcurrentbeat) then
                if mpressed[n.getslot()] then
                    mhitcb(n.getslot())
                end

            -- se ja passou do beat
            elseif n.isafterbeat(mcurrentbeat) then
                mmisscb(n.getslot())

            -- se nao aconteceu nada ainda
            else
                table.insert(newnotes, n)
            end

        end
        mnotes = newnotes
    end

    local function start()
        mactive = true
        mcurrentbeat = 0
        mpressed = {false, false, false, false}

        -- cria o timer para o processbeat
        mtmr = tmr:create()
        mtmr:register(
            mperiod,
            tmr.ALARM_AUTO,
            function() processbeat() end
        )
        -- cria o timer para o setpressed
        mtmr2 = tmr:create()
    end

    local function stop()
        mactive = false
        mtmr:stop()
        mtmr:unregister()
    end

    local function setpressed(s)
        mpressed[s] = true

        -- cria o timer para o reset do pressed
        -- com tempo de release de metade do periodo
        mtmr2:register(
            mperiod / 2,
            tmr.ALARM_SINGLE,
            function() mpressed[s] = false end
        )
        mtmr2:start()
    end

    return {
        addcbs = function (hitcb, misscb, beatcb)
            mhitcb = hitcb
            mmisscb = misscb
            mbeatcb = beatcb
        end,

        reset = function (notesstr, period, timestamp)
            mnotes = decodepayload(notesstr)
            mcurrentbeat = 0
            mperiod = period
            mpressed = {false, false, false, false}

            -- timestamp é o timestamp em segundos do inicio do jogo
            -- calcula o tempo de espera para o inicio do jogo
            local now = mtmr.time()
            local wait = timestamp - now
            if wait < 0 then
                wait = 0
            end

            -- cria o timer para o start
            mtmr:register(
                wait * 1000,
                tmr.ALARM_SINGLE,
                function() start() end
            )

        end,
    }
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
local function getclient()
    local meuid = "controle-guitarhero"
    local topico = 'guitarhero'
    local host = '10.1.1.99'
    local port = 1883
    local m = mqtt.Client
    local configcb = function(period, notes, timestamp) end
    local stopcb = function() end

    local function publish(msg)
        m:publish(topico, msg, 0, 0,
            function(client) print("mandou!") end
        )
    end

    local function msgcb(client, topic, data)
        local cmd = string.sub(data, 1, string.find(data, ",") - 1)
        local args = string.sub(data, string.find(data, ",") + 1)

        if cmd == "config" then
            local period = string.sub(args, 1, string.find(args, ",") - 1)
            args = string.sub(args, string.find(args, ",") + 1)
            local notes = string.sub(args, 1, string.find(args, ",") - 1)
            args = string.sub(args, string.find(args, ",") + 1)
            local timestamp = string.sub(args, 1, string.find(args, ",") - 1)
            args = string.sub(args, string.find(args, ",") + 1)

            configcb(period, notes, timestamp)
            publish("config_ok")

        elseif cmd == "stop" then
            stopcb()
            publish("stop_ok")
        
        elseif cmd == "heartbeat" then
            publish("heartbeat")
        end
    end

    local function init(ccb, scb)
        configcb = ccb
        stopcb = scb
        m = mqtt.Client("clientid " .. meuid, 120)

        local function onconnect(client)
            client:subscribe(
                topico,
                0, 
                function(c)
                    c:on("message", msgcb)
                end
            )
        end

        m:connect(
            host, 
            port, 
            false, 
            onconnect,
            function (client, reason) print("failed reason: "..reason) end
        )
    end



    return {
        init = init,
        publish = publish,
        hit = function(s) publish("hit," .. s) end,
        miss = function(s) publish("miss," .. s) end,
    }

end


local function getbotoes()
    local buzzer = 7
    local debaucingTime = 100
    local bt = {}
    local cbclient = function(s) end
    local mapping = {
        [1] = 2, -- UL,
        [2] = 3, -- UR,
        [3] = 1, -- DL,
        [4] = 4, -- DR,
    }
    local function cbbotao(tx)
        if cbclient ~= nil then
            cbclient(mapping[tx])
        end
    end

    local function init()
        -- configuracao basica dos botoes
        for tx = 1, 4 do
            bt[tx] = {}
            bt[tx].enabled = true
            bt[tx].trigType = "down"
            bt[tx].pullup = gpio.PULLUP
        end
        bt[4].trigType = "up"
        bt[4].pullup = gpio.FLOAT

        bt[1].pin = 3 -- Internal PullUp: open = high
        bt[2].pin = 4 -- Internal PullUp: open = high
        bt[3].pin = 5 -- Internal PullUp: open = high
        bt[4].pin = 8 -- Board PullDown: open = low

        -- callback dos botoes
        for tx = 1, 4 do
            local bttx = bt[tx]
            gpio.mode(bttx.pin, gpio.INT, bttx.pullup)
            gpio.trig(bttx.pin, bttx.trigType, function (level, when, count)
                if bttx.enabled then
                    bttx.enabled = false
                    tmr.create():alarm(debaucingTime, tmr.ALARM_SINGLE, function(t) bttx.enabled = true end)
                    cbbotao(tx)
                end
            end)
        end
    end

    local function beep(freq, duration)
        pwm.stop(buzzer)
        pwm.setup(buzzer, freq, 512)
        pwm.start(buzzer)
        tmr.create():alarm(duration, tmr.ALARM_SINGLE, function() pwm.stop(buzzer) end)
    end

    return {
        init = init,
        beep = beep,
        addcb = function(cb) cbclient = cb end,
    }
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- daniel guimaraes - 1910462
-- controle do guitar hero
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- criando as variaveis

game = getgame()
client = getclient()
botoes = getbotoes()

-- ligando os callbacks
game.addcbs(
    function(slot) client.hit(slot) end,        -- hitcb
    function(slot) client.miss(slot) end,       -- misscb
    function() botoes.beep(440, 0.1) end        -- beatcb
)

botoes.addcb(
    function(slot) game:setpressed(slot) end    -- cbbotao
)

client.init(
    function(period, notes, timestamp) game.reset(notes, period, timestamp) end, -- configcb
    function() game:stop() end                                                  -- stopcb
)
