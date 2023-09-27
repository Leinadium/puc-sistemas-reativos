-- variaveis globais
local dispatcher
local player
local shots
local asteroids
local gamestate

-- (so para evitar ficar pegando love.graphics.getWidth() e getHeight() toda hora)
local swidth, sheight

function radiustopoints(r)
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
function genericcolision(x1, y1, r1, x2, y2, r2)
    local x = x1 - x2
    local y = y1 - y2
    return (math.sqrt(x * x + y * y) < (r1 + r2))
end

-- roda fn usando x y, e se x e y estiverem fora dos limites (mesmo que parcialmente)
-- roda de novo, com os x e y apropriados
-- fn deve ser uma funcao que nao retorna nada e que recebe somente x e y
function doagainifoutofbounds(fn, x, y, radius, bx, by)
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

function wrapifoutofbound(x, y, bx, by)
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

function getasteroid(x, y, bearing, vel, radius)
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

function getasteroids()
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
        local px, py = player.getx(), player.gety()

        while true do
            x = love.math.random(minradius, swidth - minradius)
            y = love.math.random(minradius, sheight - minradius)
            -- checa se esta perto do player
            if not genericcolision(x, y, exclusionradius, px, py, exclusionradius) then
                break
            end
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
                player.addpoints(p)
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
                dt = coroutine.yield()
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

function getshots()
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
                dt = coroutine.yield()
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

function getplayer()
    local x, y = swidth / 2, sheight / 2    -- posicao
    local sx, sy, sr = 0, 0, 0              -- velocidade
    local acel, acelr = 0                   -- aceleracao

    local bearing = 0                       -- direcao (graus)
    local cooldown = 0

    local maxacel = 250
    local maxspeed = 200
    local maxacelr = 8
    local maxspeedr = 4 

    local radius = 20
    local shotradius = 3
    local shotcooldown = 0.20

    local points = 0
    local isdead = false              
    local isenable = false

    local function update(dt)
        -- se estiver morto, nao faz nada
        if isdead or not isenable then return end

        ------------- COLISAO  -------------
        if asteroids.checkplayer(x, y, radius * 0.7) then
            gamestate.setstate("gameover")
        end

        -------------  SHOTS  -------------
        cooldown = cooldown + dt 
        if love.keyboard.isDown("space") and cooldown >= shotcooldown then
            shots.spawn(x, y, bearing, shotradius)
            cooldown = 0
        end

        ------------- DIRECAO -------------
        -- atualiza a aceleracao da direcao
        acelr = 0
        if love.keyboard.isDown("left") then
            acelr = -maxacelr
        elseif love.keyboard.isDown("right") then
            acelr = maxacelr
        end
        -- atualiza a velocidade da direcao
        sr = sr + acelr * dt, maxspeedr
        if sr > maxspeedr then sr = maxspeedr elseif sr < -maxspeedr then sr = -maxspeedr end
        -- atualiza a direcao
        bearing = (bearing + sr * dt) % (math.pi * 2)

        -------------- POSICAO -------------
        -- atualiza aceleracao
        local acelx, acely = 0, 0
        local acelnow = 0
        if love.keyboard.isDown("up") then
            acelnow = maxacel
        elseif love.keyboard.isDown("down") then
            acelnow = -maxacel
        end
        acelx = acelnow * math.cos(bearing - math.pi / 2)
        acely = acelnow * math.sin(bearing - math.pi / 2)
        -- atualiza velocidade
        sx = sx + acelx * dt, maxspeed
        if sx > maxspeed then sx = maxspeed elseif sx < -maxspeed then sx = -maxspeed end
        sy = sy + acely * dt, maxspeed
        if sy > maxspeed then sy = maxspeed elseif sy < -maxspeed then sy = -maxspeed end     
        -- atualiza posicao
        x = x + sx * dt
        y = y + sy * dt
        x, y = wrapifoutofbound(x, y, swidth, sheight)
    end

    return {
        setenable = function (v) isenable = v end,
        setdead = function (v) isdead = v end,

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
                dt = coroutine.yield()
                update(dt)
            end
        end,

        getx = function () return x end,
        gety = function () return y end,
        getpoints = function () return points end,

        addpoints = function (p) points = points + p end,

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
                -- love.graphics.setColor(1, 1, 1)

                love.graphics.polygon("line", {
                    xx, yy - radius, 
                    xx + math.cos(math.pi / 6) * radius * 0.8, yy + math.sin(math.pi / 6) * radius, 
                    xx, yy,
                    xx - math.cos(math.pi / 6) * radius * 0.8, yy + math.sin(math.pi / 6) * radius,
                })
                love.graphics.pop()
            end

            doagainifoutofbounds(drawplayer, x, y, radius, swidth, sheight)

            -- love.graphics.print(tostring(points), 50, 50)
        end
    }
end

function gettext(x, y, s)
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

function gettexts()
    local texts = {}

    local function removeouts()
        local toremove = {}
        for i = 1, #texts do
            if texts[i].getttl() <= 0 then
                table.insert(toremove, i)
            end
        end
        for i = 1, #toremove do
            table.remove(texts, toremove[i] - i + 1)
        end
    end

    local function update(dt)
        for i = 1, #texts do texts[i].update(dt) end
        removeouts()
    end

    return {
        spawn = function (x, y, s)
            table.insert(texts,
                gettext(x, y, s)
            )
        end,

        update = function (dt) return update(dt) end,

        updateco = function ()
            while true do
                dt = coroutine.yield()
                update(dt)
            end
        end,

        draw = function ()
            for i = 1, #texts do texts[i].draw() end
        end
    }
end

function getgamestate()
    local state = "menu"    -- menu | game | gameover

    local function setstate(newstate)
        if newstate == "game" then
            -- reinicia tudo
            love.math.setRandomSeed(love.timer.getTime())
            player.setenable(true)
            player.reset()
            asteroids.reset()
        elseif newstate == "gameover" then
            player.setdead(true)
        elseif newstate == "menu" then
            player.setenable(false)
        end
        state = newstate
    end

    local function update(dt)
        if state == "menu" then
            if love.keyboard.isDown("return") then
                setstate("game")
            end
        elseif state == "game" then
            -- os outros updates estão rodando já
        elseif state == "gameover" then
            if love.keyboard.isDown("return") then
                setstate("menu")
            end
        end
    end

    return {
        setstate = function (s) return setstate(s) end,

        update = function (dt) return update(dt) end,

        updateco = function()
            while true do
                dt = coroutine.yield()
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
                love.graphics.print(
                    "Pressione [ENTER] para comecar",
                    swidth / 2 - 150, sheight / 2 - 50
                )
            end
            if state == "gameover" then
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(
                    "Game Over",
                    swidth / 2 - 150, sheight / 2 - 100
                )
                love.graphics.print(
                    "Pontuacao: " .. tostring(player.getpoints()),
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


-- Dispatcher
-- implementação de loop de "eventos"
function getdispatcher()
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

function love.load(arg)
    swidth, sheight = love.graphics.getDimensions()

    dispatcher = getdispatcher()
    gamestate = getgamestate()
    player = getplayer()
    asteroids = getasteroids()
    shots = getshots()
    texts = gettexts()

    dispatcher.add(gamestate.updateco)
    dispatcher.add(player.updateco)
    dispatcher.add(asteroids.updateco)
    dispatcher.add(shots.updateco)
    dispatcher.add(texts.updateco)

    gamestate.setstate("menu")  -- para comecar tudo
end

function love.draw()
    gamestate.draw()
    player.draw()
    asteroids.draw()
    shots.draw()
    texts.draw()
end

function love.update(dt)
    -- player.update(dt)
    -- asteroids.update(dt)
    -- shots.update(dt)
    -- texts.update(dt)
    
    dispatcher.process(dt)
end

function love.quit()
    love.window.close()
    os.exit()
end

