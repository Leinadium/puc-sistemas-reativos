require "love"
local mqtt = require("mqtt_library")

-- variaveis globais
local dispatcher
local players
local shots
local asteroids
local gamestate
local texts
local controles

-- (so para evitar ficar pegando love.graphics.getWidth() e getHeight() toda hora)
local swidth, sheight

local function radiustopoints(r)
    if r > 50 then
        return 5
    elseif r > 30 then
        return 2
    else
        return 1
    end
end

-- helper function: diz se existe uma colisao dada
-- duas coordenadas e dois raios
local function genericcolision(x1, y1, r1, x2, y2, r2)
    local x = x1 - x2
    local y = y1 - y2
    return (math.sqrt(x * x + y * y) < (r1 + r2))
end

-- roda fn usando x y, e se x e y estiverem fora dos limites (mesmo que parcialmente)
-- roda de novo, com os x e y apropriados
-- fn deve ser uma funcao que nao retorna nada e que recebe somente x e y
local function doagainifoutofbounds(fn, x, y, radius, bx, by)
    local origx, origy = x, y
    fn(x, y)

    -- atualiza x
    if x < radius then
        x = x + bx
    elseif x > bx - radius then
        x = x - bx
    end

    -- atualiza y
    if y < radius then
        y = y + by
    elseif y > by - radius then
        y = y - by
    end

    -- verifica se precisa
    if x ~= origx or y ~= origy then
        fn(x, y)
    end
end

local function wrapifoutofbound(x, y, bx, by)
    -- atualiza x
    if x < 0 then
        x = bx - x
    elseif x > bx then
        x = x - bx
    end

    -- atualiza y
    if y < 0 then
        y = by - y
    elseif y > by then
        y = y - by
    end

    return x, y
end

local function getasteroid(x, y, bearing, vel, radius)
    local mx, my, mb, mv, mr = x, y, bearing, vel, radius

    local sx = mv * math.cos(mb - math.pi / 2)
    local sy = mv * math.sin(mb - math.pi / 2)
    local mout = false

    -- asteroide bonitinho
    local qsides = love.math.random(5, 10)
    local vsides = {}
    local function createsides()
        for i = 1, qsides do
            table.insert(
                vsides,
                mr * (0.7 + love.math.random() * 0.3)
            )
        end
    end
    createsides()

    local function drawasteroid(xx, yy)
        for i = 1, qsides do
            local x1, y1, x2, y2
            x1 = xx + vsides[i] * math.cos((i - 1) * 2 * math.pi / qsides)
            y1 = yy + vsides[i] * math.sin((i - 1) * 2 * math.pi / qsides)
            x2 = xx + vsides[i % qsides + 1] * math.cos((i % qsides) * 2 * math.pi / qsides)
            y2 = yy + vsides[i % qsides + 1] * math.sin((i % qsides) * 2 * math.pi / qsides)
            love.graphics.line(x1, y1, x2, y2)
        end
    end

    local function checkshots()
        mout = shots.checkasteroid(mx, my, mr * 0.8)
    end

    return {
        update = function (dt)
            mx = mx + sx * dt
            my = my + sy * dt
            mx, my = wrapifoutofbound(mx, my, swidth, sheight)
            checkshots()
        end,

        getout = function () return mout end,

        getx = function () return mx end,
        gety = function () return my end,
        getb = function () return mb end,
        getr = function () return mr end,

        draw = function ()
            doagainifoutofbounds(
                function (xx, yy)
                    love.graphics.setColor(0.8, 0.8, 0.8)
                    drawasteroid(xx, yy)
                end,
                mx, my, mr, swidth, sheight
            )
        end
    }
end

local function getasteroids()
    local myasteroids = {}
    local timer = 0
    local spawntimer = 5
    local maxtimer = 5

    local minradius = 20
    local maxradius = 70
    local exclusionradius = 150

    local function tickmaxtimer()
        spawntimer = spawntimer - 0.1
        if spawntimer < maxtimer then
            spawntimer = maxtimer
        end
    end

    local function spawn()
        local x, y, b
        local pxs = players.getxs()
        local pys = players.getys()

        while true do
            x = love.math.random(minradius, swidth - minradius)
            y = love.math.random(minradius, sheight - minradius)
            -- checa se esta perto do player
            local allowed = true
            for i = 1, #pxs do
                if genericcolision(x, y, exclusionradius, pxs[i], pys[i], exclusionradius) then
                    allowed = false
                    break
                end
            end
            if allowed then break end
        end

        tickmaxtimer()

        table.insert(myasteroids,
            getasteroid(
                x,
                y,
                love.math.random(0, math.pi * 2),   -- bearing
                love.math.random(50, 100),          -- vel
                love.math.random(minradius, maxradius)  -- radius
            )
        )

    end

    local function spawnchildren(asteroid)
        local x, y, b, r
        x, y, b, r = asteroid.getx(), asteroid.gety(), asteroid.getb(), asteroid.getr()
        table.insert(myasteroids, 
            getasteroid(x, y, b + math.pi / 4, 100, r / 2)
        )
        table.insert(myasteroids, 
            getasteroid(x, y, b - math.pi / 4, 100, r / 2)
        )
    end

    local function removeouts()
        local toremove = {}
        for i = 1, #myasteroids do
            if myasteroids[i].getout() then
                -- aumenta a pontuacao do player
                local p = radiustopoints(myasteroids[i].getr())
                players.addpoints(p)
                -- cria o texto
                texts.spawn(myasteroids[i].getx(), myasteroids[i].gety(), tostring("+" .. tostring(p)))
                -- pode nascer outros dois asteroides dependendo do tamanho do atual
                if myasteroids[i].getr() > minradius then
                    spawnchildren(myasteroids[i])
                end
                table.insert(toremove, i)
            end
        end
        for i = 1, #toremove do
            table.remove(myasteroids, toremove[i] - i + 1)
        end
    end

    local function checkplayer(px, py, pr)
        for i = 1, #myasteroids do
            local ax, ay, ar = myasteroids[i].getx(), myasteroids[i].gety(), myasteroids[i].getr()
            if genericcolision(px, py, pr, ax, ay, ar) then
                return true
            end
        end
        return false
    end

    local function update(dt)
        timer = timer + dt
        -- checa se deve spawnar um novo asteroid
        if timer > spawntimer then
            spawn()
            timer = 0
        end

        -- atualiza cada asteroid
        for i = 1, #myasteroids do
            myasteroids[i].update(dt)
        end

        -- remove os asteroids que exploriram
        removeouts()
    end

    return {
        update = function (dt) return update(dt) end,

        updateco = function ()
            while true do
                local dt = coroutine.yield()
                update(dt)
            end
        end,

        checkplayer = function (x, y, r) return checkplayer(x, y, r) end,

        reset = function ()
            myasteroids = {}
            timer = 0
            spawntimer = maxtimer
        end,

        draw = function ()
            for i = 1, #myasteroids do myasteroids[i].draw() end
        end
    }
end

local function getshots()
    local myshots = {}

    local function removeouts()
        local toremove = {}
        for i = 1, #myshots do
            if myshots[i].isout() then
                table.insert(toremove, i)
            end
        end
        for i = 1, #toremove do
            table.remove(myshots, toremove[i] - i + 1)
        end
    end

    local function checkcolision(ax, ay, ar)
        for i = 1, #myshots do
            local x, y, r = myshots[i].getx(), myshots[i].gety(), myshots[i].getr()
            if genericcolision(x, y, r, ax, ay, ar) then
                -- aproveito e tbm removo o shot
                table.remove(myshots, i)
                return true
            end
        end
        return false
    end

    local function update(dt)
        -- atualiza cada shot
        for i = 1, #myshots do myshots[i].update(dt) end
        -- remove os asteroids que exploriram
        removeouts()    
    end

    return {
        spawn = function (x, y, bearing, radius)
            table.insert(myshots,
                getshot(x, y, bearing, radius)
            )
        end,

        checkasteroid = function (x, y, r)
            return checkcolision(x, y, r)
        end,

        update = function (dt) return update(dt) end,

        updateco = function ()
            while true do
                local dt = coroutine.yield()
                update(dt)
            end
        end,

        draw = function ()
            for i = 1, #myshots do myshots[i].draw() end
        end   
    }
end

function getshot(x, y, bearing, radius)
    local mx, my, mb, mr = x, y, bearing, radius
    local maxspeed = 500
    local ttl = math.min(swidth, sheight) * 0.8 / maxspeed

    local sx = maxspeed * math.cos(mb - math.pi / 2)
    local sy = maxspeed * math.sin(mb - math.pi / 2)
    local isout = false

    local function checkisout()
        if ttl <= 0 then
            isout = true
        end
    end

    return {
        update = function (dt)
            ttl = ttl - dt
            mx = mx + sx * dt
            my = my + sy * dt
            mx, my = wrapifoutofbound(mx, my, swidth, sheight)
            checkisout()
        end,

        isout = function () return isout end,

        getx = function () return mx end,
        gety = function () return my end,
        getr = function () return mr end,

        draw = function ()
            love.graphics.setColor(1, 1, 1)
            love.graphics.circle("fill", mx, my, mr)
        end
    }
end

local function getplayer(id)
    local meuid = id
    local x, y = swidth / 2, sheight / 2    -- posicao
    local sx, sy, sr = 0, 0, 0              -- velocidade
    local acel, acelr = 0, 0                -- aceleracao

    local bearing = 0                       -- direcao (graus)
    local cooldown = 0

    local maxacel = 250
    local maxspeed = 200
    local maxacelr = 10
    local maxspeedr = 4 

    local radius = 20
    local shotradius = 3
    local shotcooldown = 0.20

    local points = 0
    local isdead = false              
    local isenable = false

    local isshotting = false
    local isup = false
    local isleft = false
    local isright = false

    local function update(dt)
        -- se estiver morto, nao faz nada
        if isdead or not isenable then return end

        ------------- COLISAO  -------------
        if asteroids.checkplayer(x, y, radius * 0.7) then
            -- gamestate.setstate("gameover")
            isdead = true
        end

        -------------  SHOTS  -------------
        cooldown = cooldown + dt 
        if isshotting and cooldown >= shotcooldown then
            shots.spawn(x, y, bearing, shotradius)
            cooldown = 0
        end

        ------------- DIRECAO -------------

        -- atualiza a aceleracao da direcao
        acelr = 0
        if isleft or isright then
            if isleft then
                acelr = -maxacelr
            elseif isright then
                acelr = maxacelr
            end
            -- atualiza a velocidade da direcao
            sr = sr + acelr * dt
            if sr > maxspeedr then sr = maxspeedr elseif sr < -maxspeedr then sr = -maxspeedr end

        else
            -- se nao estiver apertando nada, dimunui a velocidade
            -- de forma exponencial... eh mais facil
            if sr < 0.1 and sr > -0.1 
                then sr = 0 
            else
                sr = sr * 0.9
            end
        end
        -- atualiza a direcao
        bearing = (bearing + sr * dt) % (math.pi * 2)

        -------------- POSICAO -------------
        -- atualiza aceleracao
        local acelx, acely = 0, 0
        local acelnow = 0
        if isup then
            acelnow = maxacel
        end
        acelx = acelnow * math.cos(bearing - math.pi / 2)
        acely = acelnow * math.sin(bearing - math.pi / 2)
        -- atualiza velocidade
        sx = sx + acelx * dt
        if sx > maxspeed then sx = maxspeed elseif sx < -maxspeed then sx = -maxspeed end
        sy = sy + acely * dt
        if sy > maxspeed then sy = maxspeed elseif sy < -maxspeed then sy = -maxspeed end
        -- atualiza posicao
        x = x + sx * dt
        y = y + sy * dt
        x, y = wrapifoutofbound(x, y, swidth, sheight)
    end

    return {
        setenable = function (v) isenable = v end,
        setdead = function (v) isdead = v end,
        getisdead = function () return isdead end,
        getisenable = function () return isenable end,

        reset = function ()
            x, y = swidth / 2, sheight / 2
            sx, sy, sr = 0, 0, 0
            acel, acelr = 0, 0
            bearing = 0
            cooldown = 0
            points = 0
            isdead = false
        end,

        update = function (dt) return update(dt) end,

        updateco = function ()
            while true do
                local dt = coroutine.yield()
                update(dt)
            end
        end,

        getx = function () return x end,
        gety = function () return y end,
        getr = function () return radius end,
        getpoints = function () return points end,

        addpoints = function (p) points = points + p end,

        setleft = function (v) isleft = v end,
        setright = function (v) isright = v end,
        setup = function (v) isup = v end,
        setshotting = function (v) isshotting = v end,

        draw = function ()
            if not isenable then return end
            
            local function drawplayer(xx, yy)
                love.graphics.push()
                -- roda em volta de (x, y)
                love.graphics.translate(xx, yy)
                love.graphics.rotate(bearing)
                love.graphics.translate(-xx, -yy)

                -- desenha o triangulo
                if not isdead then
                    love.graphics.setColor(1, 1, 1)
                else
                    love.graphics.setColor(1, 0.1, 0.1)
                end
                
                love.graphics.polygon("line", {
                    xx, yy - radius, 
                    xx + math.cos(math.pi / 6) * radius * 0.8, yy + math.sin(math.pi / 6) * radius, 
                    xx, yy,
                    xx - math.cos(math.pi / 6) * radius * 0.8, yy + math.sin(math.pi / 6) * radius,
                })
                love.graphics.pop()
                -- desenha o numero dele em cima
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(tostring(meuid), xx - 4, yy + radius)

            end

            doagainifoutofbounds(drawplayer, x, y, radius, swidth, sheight)

            -- love.graphics.print(tostring(points), 50, 50)
        end
    }
end

local function getplayers()
    local mplayers = {}
    local points = 0

    local function checkreviveplayers()
        -- todos com todos
        for i = 1, #mplayers do
            -- se o player esta morto, verifica se ele pode ser revivido
            if mplayers[i].getisdead() then
                for j = 1, #mplayers do
                    -- pega um outro player 
                    if i ~= j then
                        -- se os players estao se tocando, revive
                        if genericcolision(
                            mplayers[i].getx(), mplayers[i].gety(), mplayers[i].getr(),
                            mplayers[j].getx(), mplayers[j].gety(), mplayers[j].getr()
                        ) then
                            mplayers[i].setdead(false)
                            mplayers[i].setenable(true)
                            break
                        end
                    end
                end
            end
        end
    end

    local function update(dt)
        -- atualiza cada player
        local alldead = true
        for i = 1, #mplayers do 
            mplayers[i].update(dt)
            local isdead = mplayers[i].getisdead()
            local isenable = mplayers[i].getisenable()
            if not isdead and isenable then
                alldead = false
            end
        end
        -- se todos os players morreram, acaba o jogo mais cedo
        if alldead then
            gamestate.setstate("gameover")
            return
        end

        -- roda a verificacao de reviver
        checkreviveplayers()
    end

    local function updateco()
        while true do
            local dt = coroutine.yield()
            update(dt)
        end
    end

    local function getpoints()
        return points
    end

    local function addpoints(p)
        points = points + p
    end

    local function getxs()
        local xs = {}
        for i = 1, #mplayers do
            table.insert(xs, mplayers[i].getx())
        end
        return xs
    end

    local function getys()
        local ys = {}
        for i = 1, #mplayers do
            table.insert(ys, mplayers[i].gety())
        end
        return ys
    end

    local function reset()
        for i = 1, #mplayers do mplayers[i].reset() end
        points = 0
    end

    return {
        add = function (p) table.insert(mplayers, p) end,

        addpoints = function (p) addpoints(p) end,
        getpoints = function () return getpoints() end,
        getxs = function () return getxs() end,
        getys = function () return getys() end,

        setdead = function(v) for i = 1, #mplayers do mplayers[i].setdead(v) end end,
        setenable = function(v) for i = 1, #mplayers do mplayers[i].setenable(v) end end,
        reset = function() return reset() end,

        setup = function(i, v) mplayers[i].setup(v) end,
        setleft = function(i, v) mplayers[i].setleft(v) end,
        setright = function(i, v) mplayers[i].setright(v) end,
        setshotting = function(i, v) mplayers[i].setshotting(v) end,

        update = function(dt) return update(dt) end,
        updateco = function() return updateco() end,
        draw = function() for i = 1, #mplayers do mplayers[i].draw() end end,
    }
end

local function gettext(x, y, s)
    local mx, my, ms = x, y, s
    local ttl = 1
    local ydrift = 50

    return {
        update = function (dt)
            ttl = ttl - dt
            my = my - ydrift * dt
        end,

        getttl = function () return ttl end,

        draw = function ()
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(ms, mx, my)
        end
    }
end

local function gettexts()
    local mtexts = {}

    local function removeouts()
        local toremove = {}
        for i = 1, #mtexts do
            if mtexts[i].getttl() <= 0 then
                table.insert(toremove, i)
            end
        end
        for i = 1, #toremove do
            table.remove(mtexts, toremove[i] - i + 1)
        end
    end

    local function update(dt)
        for i = 1, #mtexts do mtexts[i].update(dt) end
        removeouts()
    end

    return {
        spawn = function (x, y, s)
            table.insert(mtexts,
                gettext(x, y, s)
            )
        end,

        update = function (dt) return update(dt) end,

        updateco = function ()
            while true do
                local dt = coroutine.yield()
                update(dt)
            end
        end,

        draw = function ()
            for i = 1, #mtexts do mtexts[i].draw() end
        end
    }
end

local function getgamestate()
    local state = "menu"    -- menu | game | gameover
    local podejogar = false
    local isenterpressed = false

    local function setpodejogar() podejogar = true end

    local function setstate(newstate)
        if newstate == "game" then
            -- reinicia tudo
            love.math.setRandomSeed(love.timer.getTime())
            players.setenable(true)
            players.reset()
            asteroids.reset()
        elseif newstate == "gameover" then
            if state ~= "game" then return end  -- so pode ir para gameover se estiver em game
            players.setdead(true)
        elseif newstate == "menu" then
            players.setenable(false)
        end
        state = newstate
    end

    local function update(dt)
        if state == "menu" and podejogar then
            if isenterpressed then
                setstate("game")
            end
        elseif state == "game" then
            -- os outros updates estão rodando já
        elseif state == "gameover" then
            if isenterpressed then
                setstate("menu")
            end
        end
        isenterpressed = false
    end

    return {
        setstate = function (s) return setstate(s) end,
        setpodejogar = function () return setpodejogar() end,
        setenterpressed = function () isenterpressed = true end,

        update = function (dt) return update(dt) end,

        updateco = function()
            while true do
                local dt = coroutine.yield()
                update(dt)
            end
        end,

        draw = function ()
            if state == "game" then
                -- os outros draw estão rodando já
            end
            if state == "menu" then
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(
                    "Asteroids",
                    swidth / 2 - 150, sheight / 2 - 100
                )
                if podejogar then
                    love.graphics.print(
                        "Pressione [ENTER] para comecar",
                        swidth / 2 - 150, sheight / 2 - 50
                    )
                else
                    love.graphics.print(
                        "Aguardando outros jogadores",
                        swidth / 2 - 150, sheight / 2 - 50
                    )
                end
            end
            if state == "gameover" then
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(
                    "Game Over",
                    swidth / 2 - 150, sheight / 2 - 100
                )
                love.graphics.print(
                    "Pontuacao: " .. tostring(players.getpoints()),
                    swidth / 2 - 150, sheight / 2 - 75
                )
                love.graphics.print(
                    "Pressione ENTER para voltar ao menu",
                    swidth / 2 - 150, sheight / 2 - 50
                )
            end
        end
    }
end

local function getcontroles()
    local meuid = "asteroid-love"
    local topico = "asteroid"
    local host = "10.1.1.99"
    local port = 1883
    local mclient = {}
    local playerids = {}

    local function callback(topic, msg)
        -- cada msg é no formato "id,payload,state",
        -- em que payload pode ser "left", "right", "up", "shot"
        -- e state pode ser "down" ou "up"

        -- separando as variaveis
        local ident, payload, state = string.match(msg, "([^,]+),([^,]+),([^,]+)")
        local index = playerids[ident] or nil

        -- print(ident)
        -- print(#playerids)
        -- print(index)

        -- imprimindo a tabela playerids
        for k, v in pairs(playerids) do
            print(k, v)
        end

        -- se nao tiver um id no playerids, adiciona
        if index == nil then
            -- contando o numero de players
            index = 1
            for _ in pairs(playerids) do index = index + 1 end
            playerids[ident] = index

            players.add(getplayer(index))

            -- mostra um texto avisando que entrou um player no jogo
            texts.spawn(
                swidth / 2,
                sheight / 2,
                "Player " .. tostring(index) .. " entrou no jogo"
            )
            -- se for o primeiro player, pode jogar
            if index == 1 then
                gamestate.setpodejogar()
            end
        end

        local statebool = state == "true"

        if payload == "left" then
            players.setleft(index, statebool)
        elseif payload == "right" then
            players.setright(index, statebool)
        elseif payload == "up" then
            players.setup(index, statebool)
        elseif payload == "shot" then
            players.setshotting(index, statebool)
        end
    end

    local function init()
        mqtt.Utility.set_debug(true)
        mclient = mqtt.client.create(
            host,
            port,
            callback
        )
        mclient:connect(meuid)
        mclient:subscribe({topico})
    end

    local function reset()
        playerids = {}
    end

    local function update()
        mclient:handler()
    end

    local function updateco()
        while true do
            coroutine.yield()
            update()
        end
    end

    return {
        reset = function () reset() end,
        init = function () init() end,
        updateco = updateco,
    }
end

-- Dispatcher
-- implementação de loop de "eventos"
local function getdispatcher()
    local tasks = {}

    return {
        -- adiciona uma task
        add = function (task)
            table.insert(tasks, coroutine.create(task))
        end,

        -- loop do dispatcher
        process = function (dt)
            local i = 1
            while i <= #tasks do
                if tasks[i] == nil then
                    return
                end
                local status = coroutine.resume(tasks[i], dt)
                -- if status == false then
                --     table.remove(tasks, i)
                -- else
                --     i = i + 1
                -- end
                i = i + 1
            end
        end,

        quantidade = function () return #tasks end
    }
end

function love.keypressed(key)
    -- se for f11, tela cheia
    print(key)
    if key == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
        swidth, sheight = love.graphics.getDimensions()

    -- se for enter, seta a flag de enter
    elseif key == "return" then
        gamestate.setenterpressed()
    end
end

function love.resize(w, h)
    swidth, sheight = w, h
end

function love.load(arg)
    love.window.setMode(800, 600, {resizable = true})
    swidth, sheight = love.graphics.getDimensions()

    dispatcher = getdispatcher()
    gamestate = getgamestate()
    players = getplayers()
    asteroids = getasteroids()
    shots = getshots()
    texts = gettexts()
    controles = getcontroles()

    controles.init()

    dispatcher.add(gamestate.updateco)
    dispatcher.add(players.updateco)
    dispatcher.add(asteroids.updateco)
    dispatcher.add(shots.updateco)
    dispatcher.add(texts.updateco)
    dispatcher.add(controles.updateco)

    gamestate.setstate("menu")  -- para comecar tudo
end

function love.draw()
    gamestate.draw()
    players.draw()
    asteroids.draw()
    shots.draw()
    texts.draw()
end

function love.update(dt)
    dispatcher.process(dt)
end

function love.quit()
    love.window.close()
    os.exit()
end

