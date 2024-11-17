local Game = require './src/game'
local game

function love.load()
    game = Game:new()
end