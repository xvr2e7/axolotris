local Game = {
    GRID_SIZE = 32,
    GRID_WIDTH = 12,
    GRID_HEIGHT = 21,
    SELECTION_RANGE = 3,
    COLORS = {
        background = {0.1, 0.1, 0.15}, -- Slightly blue tint
        grid = {0.2, 0.2, 0.25},
        gridLine = {0.3, 0.3, 0.35, 0.5}, -- Softer grid lines
        trapBlock = {0.6, 0.4, 0.4}, -- Softer red
        selected = {0.4, 0.8, 0.4}, -- Softer green
        axolotl = {0.9, 0.5, 0.7}, -- Softer pink
        movementArea = {0.4, 0.4, 0.6, 0.3}, -- More transparent
        tetrimino = {0.4, 0.6, 0.8} -- Softer blue
    }
}

local Entities = require 'src/entities'

function Game:new()
    local game = {
        grid = {},
        selectedBlocks = {},
        gravity = 0
    }
    
    -- Create axolotl at center
    game.axolotl = Entities.newAxolotl(
        math.floor(self.GRID_WIDTH / 2),
        math.floor(self.GRID_HEIGHT / 2)
    )
    
    -- Initialize grid
    for y = 1, self.GRID_HEIGHT do
        game.grid[y] = {}
        for x = 1, self.GRID_WIDTH do
            game.grid[y][x] = Entities.newBlock("trap")
        end
    end
    
    setmetatable(game, {__index = self})
    return game
end

function Game:update(dt)
    -- Update game state
    self.gravity = self.gravity + dt
end

function Game:draw()
    -- Draw background
    love.graphics.setColor(self.COLORS.background)
    love.graphics.rectangle("fill", 0, 0, 
        self.GRID_WIDTH * self.GRID_SIZE, 
        self.GRID_HEIGHT * self.GRID_SIZE)
    
    -- Draw grid
    love.graphics.setColor(self.COLORS.gridLine)
    for y = 0, self.GRID_HEIGHT do
        love.graphics.line(
            0, y * self.GRID_SIZE,
            self.GRID_WIDTH * self.GRID_SIZE, y * self.GRID_SIZE
        )
    end
    for x = 0, self.GRID_WIDTH do
        love.graphics.line(
            x * self.GRID_SIZE, 0,
            x * self.GRID_SIZE, self.GRID_HEIGHT * self.GRID_SIZE
        )
    end
    
    -- Draw blocks
    for y = 1, self.GRID_HEIGHT do
        for x = 1, self.GRID_WIDTH do
            local block = self.grid[y][x]
            if block then
                love.graphics.setColor(self.COLORS.trapBlock)
                love.graphics.rectangle("fill",
                    (x-1) * self.GRID_SIZE + 1,
                    (y-1) * self.GRID_SIZE + 1,
                    self.GRID_SIZE - 2,
                    self.GRID_SIZE - 2
                )
            end
        end
    end
    
    -- Draw axolotl
    love.graphics.setColor(self.COLORS.axolotl)
    love.graphics.rectangle("fill",
        (self.axolotl.x-1) * self.GRID_SIZE + 4,
        (self.axolotl.y-1) * self.GRID_SIZE + 4,
        self.GRID_SIZE - 8,
        self.GRID_SIZE - 8
    )
end

return Game