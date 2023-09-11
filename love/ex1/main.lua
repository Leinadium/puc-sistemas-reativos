local xinit = 50
local yinit = 50

function retangulo(x, y, w, h)
    local originalx, originaly, rx, ry, rw, rh = x, y, x, y, w, h
    return {
        draw =
            function ()
                love.graphics.rectangle("line", rx, ry, rw, rh)
            end,
        keypressed =
            function (key)
                local mx, my = love.mouse.getPosition() 
                if naimagem(mx, my, x, y) then
                    if key == 'b' then
                        ry = originaly
                    elseif key == 'down' then
                        ry = ry + 10
                    elseif key == 'right' then
                        rx = rx + 10
                    end
                end
            end
    }
end

function love.load()
    x = xinit 
    y = yinit
    w = 200 h = 300
end

function naimagem (mx, my, x, y) 
    return (mx>x) and (mx<x+w) and (my>y) and (my<y+h)
end

function love.keypressed(key)
    local mx, my = love.mouse.getPosition() 
    
    if naimagem(mx, my, x, y) then
        if key == 'b' then
            y = yinit
        elseif key == 'down' then
            y = y + 10
        elseif key == 'right' then
            x = x + 10
        end
    end
end

-- function love.update (dt)
--     local mx, my = love.mouse.getPosition() 
--     if love.keyboard.isDown("down")  and naimagem(mx, my, x, y)  then
--         y = y + 10
--     end
-- end

function love.draw ()
    love.graphics.rectangle("line", x, y, w, h)
end

