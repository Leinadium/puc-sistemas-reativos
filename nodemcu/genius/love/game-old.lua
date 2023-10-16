require "love"
require "coroutine"
local M = {}

local swidth, sheight

function M.getboard()
    local level = 0         -- nivel atual
    local sequence = {}     -- sequencia das cores
    local step = 0          -- selecao atual da sequencia
    local current = {false, false, false,false} -- cores acesas
    local timebuffer = 0    -- buffer de tempo para a corotina
    local currentco = nil   -- corotina
    local gamecb = nil      -- callback apos acabar a corotina

    -- cores do tabuleiro
    local colors = {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {1, 1, 0}}

    -- reinicia o tabuleiro
    local function reset()
        sequence = {false, false, false, false}
        level = 0
        step = 0
    end

    -- avanca de nivel
    local function nextlevel()
        level = level + 1
        table.insert(sequence, math.random(1, 4))
        step = 0
    end
    
    -- cria a corotina da sequencia
    -- e salva o callback do jogo para quando ela acabar
    local function dosequence(finishcb)    
        currentco = coroutine.create(function ()
            for i = 1, #sequence do
                current[i] = true
                coroutine.yield()
                current[i] = false
                coroutine.yield()
            end
        end)
        gamecb = finishcb
    end

    -- cria a corotina de erro
    local function doerror(wrong, right)
        currentco = coroutine.create(function ()
            current[wrong] = true
            while true do
                current[right] = true
                coroutine.yield()
                current[right] = false
                coroutine.yield()
            end
        end)
    end

    -- cria a corotina de selecao
    local function doselection(selection)
        currentco = coroutine.create(function ()
            current[selection] = true
            coroutine.yield()
            current[selection] = false
            -- coroutine.yield()
        end)
    end

    -- seleciona o botao x
    -- retorna true se acabou a sequencia
    -- retorna false se errou a sequencia
    -- retorna nulo se ainda nao acabou a sequencia
    local function select(x)
        -- se tiver uma corotina rodando, ignora
        if currentco ~= nil then return end

        -- se for certo, mostra usando a corotina de selecao
        if sequence[step] == x then
            doselection(x)
            step = step + 1
            -- verifica se acabou
            if step > #sequence then
                nextlevel()
                return true
            end
        -- se for errado, mostra usando a corotina de erro
        else
            doerror(x, sequence[step])
            return false
        end
    end

    local function update(dt)
        -- corotina da sequencia
        if currentco ~= nil then
            -- adiciona o tempo ao buffer
            timebuffer = timebuffer + dt
            if timebuffer > 0.5 then
                -- se passou mais de meio segundo, então executa a corotina
                timebuffer = 0
                if not coroutine.resume(currentco) then
                    -- se acabou a corotina, limpa as variaveis
                    -- e chama o callback do game
                    currentco = nil
                    if gamecb ~= nil then gamecb() end
                    gamecb = nil
                end
            end
        end
    end

    local function draw()
        local x, y = swidth / 2, sheight / 2
        local radius = 200
        local angle = 0
        local step = 2 * math.pi / 4

        for i = 1, 4 do
            -- fundo
            love.graphics.setColor(0.1, 0.1, 0.1)
            love.graphics.arc("fill", x, y, radius + 10, angle, angle + step)
            
            -- botao
            if current[i] then
                love.graphics.setColor(colors[i][1], colors[i][2], colors[i][3])
            else
                love.graphics.setColor(colors[i][1] * 0.5, colors[i][2] * 0.5, colors[i][3] * 0.5)
            end
            love.graphics.arc("fill", x, y, radius, angle, angle + step)
            angle = angle + step
        end

        love.graphics.print("level " .. tostring(level), 10, 30)
        -- love.graphics.print("sequence " .. tostring(sequence), 10, 50)
        for i = 1, #sequence do
            love.graphics.print(tostring(sequence[i]), 10*i, 150)
        end
        love.graphics.print("currentco " .. tostring(currentco), 10, 70)
        love.graphics.print("timebuffer " .. tostring(timebuffer), 10, 90)
    end

    return {
        reset = reset,
        nextlevel = nextlevel,
        dosequence = dosequence,
        select = select,
        draw = draw,
        update = update,
    }
end

function M.getgame()
    local state = "menu"    -- "menu", "computer", "player", "gameover"
    local board = M.getboard()
    local temp = 0

    local function setstate(newstate)
        if newstate == state then return end

        if newstate == "menu" then
            board.reset()
        elseif newstate == "computer" then
            board.dosequence(function () setstate("player") end)
        end
        
        state = newstate
    end

    -- cuida do retorno do .select do board
    local function handleselection(status)
        -- se retornou nulo, só continua o jogo normalmente
        if status == nil then 
            return
        -- se retorn true, vai para o computador
        elseif status then 
            setstate("computer")
        else 
            setstate("gameover")
        end
    end

    local function buttonhandler(button)
        -- button = 1, 2, 3 ou 4
        temp = temp + 1
        if state == "menu" then
            board.nextlevel()       -- gera o primeiro nivel
            setstate("computer")    -- mostra a sequencia

        elseif state == "player" then
            handleselection(board.select(button))
        end
    end

    local function update(dt)
        board.update(dt)
    end

    local function draw()
        love.graphics.print("state " .. state, 10, 10)
        love.graphics.print("temp " .. tostring(temp), 10, 110)
        board.draw()
    end

    -- temporario
    local function setup()
        function love.keypressed(key, scancode, isrepeat)
            if key == "1" or key == "2" or key == "3" or key == "4" then
                buttonhandler(tonumber(key))
            end
        end
    end

    return {
        setup = setup,
        update = update,
        draw = draw,
    }
end

function M.init()
    swidth, sheight = love.graphics.getDimensions()
end

return M