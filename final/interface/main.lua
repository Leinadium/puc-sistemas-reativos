-- daniel guimaraes - 1910462
-- interface do guitar hero

require "love"
require "os"

local controller = require("controller")

local track = require("track")
local note = require("note")

local t

function love.load(arg)
    t = track.Track:new()
    t:reset(
        {
            note.Note:new(1, 1),
            note.Note:new(2, 2),
            note.Note:new(3, 3),
            note.Note:new(4, 4),
            note.Note:new(5, 2),
            note.Note:new(6, 3),
            note.Note:new(7, 1),
            note.Note:new(8, 1),
            note.Note:new(9, 2),
            note.Note:new(10, 3),
            note.Note:new(11, 4),
            note.Note:new(12, 2),
            note.Note:new(13, 3),
            note.Note:new(14, 1),
        },
        0.4411
    )
end

function love.draw()
    t:draw()
end

function love.update(dt)
    t:update(dt)
end

function love.quit()
    love.window.close()
    os.exit(1)
end