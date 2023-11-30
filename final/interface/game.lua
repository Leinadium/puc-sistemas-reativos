local track = require("track")

local M = {}

Game = {
    track = track.Track:new(),
    points = 0,
}

function Game:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

M.Game = Game
return M