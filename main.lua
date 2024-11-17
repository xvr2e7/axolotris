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

-- New mouse input handler
function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then -- Left click only
        -- Calculate scaling to maintain aspect ratio
        local windowWidth = love.graphics.getWidth()
        local windowHeight = love.graphics.getHeight()
        
        -- Calculate game area dimensions
        local gameWidth = game.GRID_WIDTH * game.GRID_SIZE
        local gameHeight = game.GRID_HEIGHT * game.GRID_SIZE
        
        -- Calculate scaling factor
        local scale = math.min(
            windowWidth / gameWidth,
            windowHeight / gameHeight
        ) * 0.9 -- 90% of screen size for margins
        
        -- Calculate offset for centering
        local offsetX = (windowWidth - gameWidth * scale) / 2
        local offsetY = (windowHeight - gameHeight * scale) / 2
        
        -- Convert mouse coordinates to game coordinates
        local gameX = (x - offsetX) / scale
        local gameY = (y - offsetY) / scale
        
        game:handleMouseClick(gameX, gameY)
    end
end

function love.draw()
    -- Calculate scaling to maintain aspect ratio
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    -- Calculate game area dimensions
    local gameWidth = game.GRID_WIDTH * game.GRID_SIZE
    local gameHeight = game.GRID_HEIGHT * game.GRID_SIZE
    
    -- Calculate scaling factor
    local scale = math.min(
        windowWidth / gameWidth,
        windowHeight / gameHeight
    ) * 0.9
    
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
