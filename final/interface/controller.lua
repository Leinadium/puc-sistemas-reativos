local game = require("game")
local console = require("console")

local M = {}

Controller = {
    game = game.Game:new(),
    console = console.Console:new(),
}

M.Controller = Controller
return M