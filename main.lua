local Game = require 'src/game'
local game

function love.load()
    -- Configure window
    love.window.setMode(800, 600, {
        resizable = true,
        minwidth = 400,
        minheight = 300
    })
    
    -- Initialize game
    game = Game:new()
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    -- Calculate scaling to maintain aspect ratio
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    -- Calculate game area dimensions
    local gameWidth = game.GRID_WIDTH * game.GRID_SIZE
    local gameHeight = game.GRID_HEIGHT * game.GRID_SIZE
    
    -- Calculate scaling factor to fit screen while maintaining aspect ratio
    local scale = math.min(
        windowWidth / gameWidth,
        windowHeight / gameHeight
    ) * 0.9 -- 90% of screen size for margins
    
    -- Calculate centered position
    local x = (windowWidth - gameWidth * scale) / 2
    local y = (windowHeight - gameHeight * scale) / 2
    
    -- Apply transformation
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale, scale)
    
    -- Draw game
    game:draw()
    
    love.graphics.pop()
end
