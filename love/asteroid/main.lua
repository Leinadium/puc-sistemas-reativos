local dispatcher, player, shots, asteroids
local swidth, sheight

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

    local function checkshots()
        mout = shots.checkasteroid(mx, my, mr)
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
                    love.graphics.circle("line", mx, my, mr)
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
                -- TODO: acertou! aumenta a pontuacao
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

        draw = function ()
            for i = 1, #myasteroids do myasteroids[i].draw() end
            love.graphics.print(tostring(timer), 50, 120)
            love.graphics.print(tostring(#myasteroids), 50, 130)
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
            love.graphics.print(tostring(#myshots), 50, 70)
        end   
    }
end

function getshot(x, y, bearing, radius)
    local mx, my, mb, mr = x, y, bearing, radius
    local maxspeed = 500

    local sx = maxspeed * math.cos(mb - math.pi / 2)
    local sy = maxspeed * math.sin(mb - math.pi / 2)
    local isout = false

    local function checkisout()
        if mx < 0 or mx > love.graphics.getWidth() or my < 0 or my > love.graphics.getHeight() then
            isout = true
            return
        end
    end

    return {
        update = function (dt)
            mx = mx + sx * dt
            my = my + sy * dt
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
    local sx, sy, sr = 0, 0, 0                 -- velocidade
    local acel, acelr = 0                   -- aceleracao

    local bearing = 0                       -- direcao (graus)
    local cooldown = 0

    local maxacel = 250
    local maxspeed = 200
    local maxacelr = 8
    local maxspeedr = 4 

    local radius = 20
    local shotradius = 3
    local shotcooldown = 0.25

    local function update(dt)
        -- atualiza shot
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
        update = function (dt) return update(dt) end,

        updateco = function ()
            while true do
                dt = coroutine.yield()
                update(dt)
            end
        end,

        getx = function () return x end,
        gety = function () return y end,

        

        draw = function ()
            local function drawplayer(xx, yy)
                love.graphics.push()
                -- roda em volta de (x, y)
                love.graphics.translate(xx, yy)
                love.graphics.rotate(bearing)
                love.graphics.translate(-xx, -yy)

                -- desenha o triangulo
                love.graphics.setColor(1, 1, 1)
                love.graphics.polygon("fill", {
                    xx, yy - radius, 
                    xx + math.cos(math.pi / 6) * radius, yy + math.sin(math.pi / 6) * radius, 
                    xx, yy,
                    xx - math.cos(math.pi / 6) * radius, yy + math.sin(math.pi / 6) * radius,
                })
                love.graphics.pop()
            end

            doagainifoutofbounds(drawplayer, x, y, radius, swidth, sheight)

            love.graphics.print(tostring(bearing), 50, 50)
            
            love.graphics.print(tostring(dispatcher.quantidade()), 50, 150)

            love.graphics.print(tostring(sx), 350, 160)
            love.graphics.print(tostring(sy), 350, 170)
            love.graphics.print(tostring(sr), 350, 180)
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
    player = getplayer()
    asteroids = getasteroids()
    shots = getshots()

    dispatcher.add(player.updateco)
    dispatcher.add(asteroids.updateco)
    dispatcher.add(shots.updateco)

    love.math.setRandomSeed(love.timer.getTime())
end

function love.draw()
    player.draw()
    asteroids.draw()
    shots.draw()
end

function love.update(dt)
    -- player.update(dt)
    -- asteroids.update(dt)
    -- shots.update(dt)
    
    dispatcher.process(dt)
end

function love.quit()
    love.window.close()
    os.exit()
end

