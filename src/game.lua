local Game = {
    GRID_SIZE = 30,
    GRID_WIDTH = 20,
    GRID_HEIGHT = 15,
    SELECTION_RANGE = 3,
    COLORS = {
        background = {0.1, 0.1, 0.1},
        grid = {0.2, 0.2, 0.2},
        trapBlock = {0.5, 0.3, 0.3},
        selected = {0.3, 0.8, 0.3},
        axolotl = {0.8, 0.4, 0.6},
        movementArea = {0.4, 0.4, 0.6, 0.2},
        tetrimino = {0.3, 0.6, 0.8}
    }
}

local Entities = require './src/entities'

function Game:new()
    local game = {
        grid = {},
        selectedBlocks = {},
        gravity = 0
    }
    
    setmetatable(game, {__index = self})
    return game
end

return Game