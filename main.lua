local game

function love.load()
    -- Calculate window size based on grid size plus UI space
    local Game = require('src.game')
    local gridPixelWidth = Game.GRID_WIDTH * Game.GRID_SIZE
    local gridPixelHeight = Game.GRID_HEIGHT * Game.GRID_SIZE
    local uiWidth = Game.GRID_SIZE * 8  -- Space for UI
    
    -- Configure window with proper size
    love.window.setMode(
        gridPixelWidth + uiWidth,  -- Width with UI space
        gridPixelHeight,           -- Height
        {
            resizable = true,
            minwidth = gridPixelWidth + uiWidth,
            minheight = gridPixelHeight
        }
    )
    
    -- Initialize game
    game = Game:new()
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left click
        if not game then return end  -- Safety check for game object
        
        if game.isPaused then
            if game.handlePauseMenuClick then  -- Safety check for method
                game:handlePauseMenuClick(x, y)
            end
        else
            if game.handleMouseClick then  -- Safety check for method
                game:handleMouseClick(x, y)
            end
        end
    end
end

function love.keypressed(key)
    game:handleKeyPressed(key)
end