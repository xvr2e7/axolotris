local Tetrimino = require('src.managers.tetrimino')
local Grid = require('src.managers.grid')
local Render = require('src.managers.render')
local Input = require('src.managers.input')
local UI = require('src.managers.ui')
local Tetris = require('src.managers.tetris')
local Audio = require('src.managers.audio')

local Game = {
    GRID_SIZE = 32,
    GRID_WIDTH = 12,
    GRID_HEIGHT = 21,
    MOVE_DELAY = 0.15,
    BUFFER_ZONE_HEIGHT = 7,
    GAME_STATES = {
        PLAYING = "playing",
        PAUSED = "paused", 
        VICTORY = "victory",
        LOSS = "loss"
    }
}

function Game:new()
    local game = {
        -- Initialize all managers
        tetrimino = Tetrimino:new(),
        grid = Grid:new(self.GRID_WIDTH, self.GRID_HEIGHT),
        render = Render:new(self.GRID_WIDTH, self.GRID_HEIGHT, self.GRID_SIZE),
        input = Input:new(self.MOVE_DELAY, self.GRID_SIZE),
        ui = UI:new(self.GRID_WIDTH, self.GRID_HEIGHT, self.GRID_SIZE),
        audio = Audio:new(),
        tetris = nil,  -- Will be initialized after game object creation
        
        -- Initial axolotl position and orientation
        axolotl = {
            x = math.floor(self.GRID_WIDTH / 2),
            y = self.GRID_HEIGHT,
            rotation = 0
        },
        
        -- Load axolotl sprites
        sprites = {
            axolotl = {
                up = love.graphics.newImage("asset/sprites/axolotl/up.png"),
                down = love.graphics.newImage("asset/sprites/axolotl/down.png"),
                left = love.graphics.newImage("asset/sprites/axolotl/left.png"),
                right = love.graphics.newImage("asset/sprites/axolotl/right.png")
            }
        },
        
        -- Game state tracking
        gameState = Game.GAME_STATES.PLAYING,
        messageBoxState = {
            isButtonHovered = false
        },
        
        -- Pause menu state
        isPaused = false,
        pauseMenu = {
            isResumeHovered = false,
            isRestartHovered = false
        }
    }
    
    -- Set metatable to inherit from Game class
    setmetatable(game, {__index = self})
    
    -- Configure sprite rendering
    for _, sprite in pairs(game.sprites.axolotl) do
        sprite:setFilter("nearest", "nearest")
    end
    
    -- Initialize audio
    game.audio:loadMusic("asset/sound/bottomtheme.ogg")
    game.audio:play()
    
    -- Create and initialize tetris manager
    game.tetris = Tetris:new()
    if game.tetris then
        game.tetris:init(game)
    end
    
    -- Initialize input manager with game reference
    if game.input and game.input.init then
        game.input:init(game)
    end
    
    -- Initialize initial block highlighting
    game:initializeHighlighting()
    
    return game
end

function Game:togglePause()
    if self.gameState == self.GAME_STATES.PLAYING then
        self.gameState = self.GAME_STATES.PAUSED
        self.isPaused = true
        -- Pause audio when entering pause state
        if self.audio then
            self.audio:pause()
        end
    elseif self.gameState == self.GAME_STATES.PAUSED then
        self.gameState = self.GAME_STATES.PLAYING
        self.isPaused = false
        -- Resume audio when leaving pause state
        if self.audio then
            self.audio:resume()
        end
    end
end

function Game:handleKeyPressed(key)
    -- Don't handle input if game is over
    if self.gameState == self.GAME_STATES.VICTORY or 
       self.gameState == self.GAME_STATES.LOSS then
        return
    end
    
    self.input:handleKeyPressed(key, self)
end

function Game:isValidPosition(x, y)
    -- Check grid boundaries
    if x < 1 or x > self.GRID_WIDTH or y < 1 or y > self.GRID_HEIGHT then
        return false
    end
    
    local block = self.grid.grid[y][x]
    
    -- Can't move onto barrier blocks
    if block.barrier then
        return false
    end
    
    -- Can move onto any non-disabled block
    -- Can always move onto safe blocks regardless of disabled state
    if not block.disabled or block.safe then
        return true
    end
    
    return false
end

function Game:isInBufferZone(y)
    return y <= self.BUFFER_ZONE_HEIGHT
end

function Game:moveAxolotl(dx, dy)
    -- Don't allow movement if game isn't in playing state
    if self.gameState ~= self.GAME_STATES.PLAYING then return end
    
    local newX = self.axolotl.x + dx
    local newY = self.axolotl.y + dy
    
    if self:isValidPosition(newX, newY) then
        -- Reset previously indicated blocks back to normal
        local oldPositions = self:getReachablePositionsForRotation(self.axolotl.rotation)
        for _, pos in ipairs(oldPositions) do
            if self:isValidPosition(pos.x, pos.y) then
                local block = self.grid.grid[pos.y][pos.x]
                if not block.selected then
                    if block.safe then
                        block.color = self.grid.colors.safeBlock
                    elseif block.tetrisColor then
                        block.color = block.tetrisColor
                    else
                        block.color = self.grid.colors.original
                    end
                end
                block.highlighted = false
            end
        end
        
        -- Update axolotl position
        self.axolotl.x = newX
        self.axolotl.y = newY
        
        -- Highlight new adjacent blocks
        local newPositions = self:getReachablePositionsForRotation(self.axolotl.rotation)
        for _, pos in ipairs(newPositions) do
            if self:isValidPosition(pos.x, pos.y) then
                local block = self.grid.grid[pos.y][pos.x]
                block.highlighted = true
                if not block.selected then
                    if block.safe then
                        block.color = self.grid.colors.safeBlockHighlighted
                    elseif block.tetrisColor and not block.disabled then
                        -- Create a highlighted version of tetris color
                        block.color = {
                            math.min(1, block.tetrisColor[1] + 0.2),
                            math.min(1, block.tetrisColor[2] + 0.2),
                            math.min(1, block.tetrisColor[3] + 0.2)
                        }
                    else
                        block.color = self.grid.colors.highlighted
                    end
                end
            end
        end
        
        -- Check for victory condition
        if self:isInBufferZone(newY) and self.grid.grid[newY][newX].isExit then
            self:handleVictory()
        end
    end
end

function Game:rotateAxolotl()
    -- Don't allow rotation if game isn't in playing state
    if self.gameState ~= self.GAME_STATES.PLAYING then return end
    
    -- Reset previously indicated blocks
    local oldPositions = self:getReachablePositionsForRotation(self.axolotl.rotation)
    for _, pos in ipairs(oldPositions) do
        if self:isValidPosition(pos.x, pos.y) then
            local block = self.grid.grid[pos.y][pos.x]
            if not block.selected then
                if block.safe then
                    block.color = self.grid.colors.safeBlock
                else
                    block.color = self.grid.colors.original
                end
            end
            block.highlighted = false
        end
    end
    
    -- Update rotation
    self.axolotl.rotation = (self.axolotl.rotation + 90) % 360
    
    -- Highlight new adjacent blocks
    local newPositions = self:getReachablePositionsForRotation(self.axolotl.rotation)
    for _, pos in ipairs(newPositions) do
        if self:isValidPosition(pos.x, pos.y) then
            local block = self.grid.grid[pos.y][pos.x]
            block.highlighted = true
            if not block.selected then
                if block.safe then
                    block.color = self.grid.colors.safeBlockHighlighted
                else
                    block.color = self.grid.colors.highlighted
                end
            end
        end
    end
end

function Game:initializeHighlighting()
    local positions = self:getReachablePositionsForRotation(self.axolotl.rotation)
    for _, pos in ipairs(positions) do
        if self:isValidPosition(pos.x, pos.y) then
            local block = self.grid.grid[pos.y][pos.x]
            block.highlighted = true
            if block.safe then
                block.color = block.selected and self.grid.colors.safeBlockSelected or self.grid.colors.safeBlockHighlighted
            else
                block.color = block.selected and self.grid.colors.selected or self.grid.colors.highlighted
            end
        end
    end
end

function Game:getReachablePositionsForRotation(rotation)
    local x, y = self.axolotl.x, self.axolotl.y
    local positions = {}
    
    -- The positions are returned in a specific order corresponding to the "rami"
    -- extending from the axolotl's sides based on its rotation
    if rotation == 0 then -- Facing up
        positions = {
            {x = x-1, y = y},   -- Left side
            {x = x+1, y = y},   -- Right side
            {x = x, y = y-1}    -- Front (top)
        }
    elseif rotation == 90 then -- Facing right
        positions = {
            {x = x, y = y-1},   -- Top side
            {x = x, y = y+1},   -- Bottom side
            {x = x+1, y = y}    -- Front (right)
        }
    elseif rotation == 180 then -- Facing down
        positions = {
            {x = x-1, y = y},   -- Left side
            {x = x+1, y = y},   -- Right side
            {x = x, y = y+1}    -- Front (bottom)
        }
    else -- rotation == 270, Facing left
        positions = {
            {x = x, y = y-1},   -- Top side
            {x = x, y = y+1},   -- Bottom side
            {x = x-1, y = y}    -- Front (left)
        }
    end
    
    return positions
end

function Game:refresh()
    -- Create new instances of all managers
    self.tetrimino = Tetrimino:new()
    self.grid = Grid:new(self.GRID_WIDTH, self.GRID_HEIGHT)
    self.tetris = Tetris:new()
    
    -- Reset axolotl position
    self.axolotl = {
        x = math.floor(self.GRID_WIDTH / 2),
        y = self.GRID_HEIGHT,
        rotation = 0
    }

    -- Reset game state
    self.gameState = self.GAME_STATES.PLAYING
    self.isPaused = false
    
    -- Initialize tetris manager with game reference
    if self.tetris then
        self.tetris:init(self)
    end
    
    -- Reinitialize highlighting
    self:initializeHighlighting()
end

function Game:handleVictory()
    if self.gameState == self.GAME_STATES.PLAYING then
        self.gameState = self.GAME_STATES.VICTORY
    end
end

function Game:handleLoss(reason)
    if self.gameState == self.GAME_STATES.PLAYING then
        self.gameState = self.GAME_STATES.LOSS
        self.lossReason = reason
    end
end


function Game:updateMessageBox(x, y)
    if self.gameState ~= self.GAME_STATES.PLAYING and 
       self.gameState ~= self.GAME_STATES.PAUSED then
        -- Calculate button position
        local boxX = (love.graphics.getWidth() - self.ui.MESSAGE_BOX_WIDTH) / 2
        local boxY = (love.graphics.getHeight() - self.ui.MESSAGE_BOX_HEIGHT) / 2
        local buttonX = boxX + (self.ui.MESSAGE_BOX_WIDTH - self.ui.MESSAGE_BUTTON_WIDTH) / 2
        local buttonY = boxY + self.ui.MESSAGE_BOX_HEIGHT - self.ui.MESSAGE_BUTTON_HEIGHT - self.ui.MESSAGE_PADDING
        
        -- Update hover state
        self.messageBoxState.isButtonHovered = 
            x >= buttonX and x <= buttonX + self.ui.MESSAGE_BUTTON_WIDTH and
            y >= buttonY and y <= buttonY + self.ui.MESSAGE_BUTTON_HEIGHT
    end
end

function Game:handleMessageBoxClick(x, y)
    if self.gameState ~= self.GAME_STATES.PLAYING and
        self.gameState ~= self.GAME_STATES.PAUSED then
        -- Calculate button position
        local boxX = (love.graphics.getWidth() - self.ui.MESSAGE_BOX_WIDTH) / 2
        local boxY = (love.graphics.getHeight() - self.ui.MESSAGE_BOX_HEIGHT) / 2
        local buttonX = boxX + (self.ui.MESSAGE_BOX_WIDTH - self.ui.MESSAGE_BUTTON_WIDTH) / 2
        local buttonY = boxY + self.ui.MESSAGE_BOX_HEIGHT - self.ui.MESSAGE_BUTTON_HEIGHT - self.ui.MESSAGE_PADDING

        -- Check if click is within button
        if x >= buttonX and x <= buttonX + self.ui.MESSAGE_BUTTON_WIDTH and
            y >= buttonY and y <= buttonY + self.ui.MESSAGE_BUTTON_HEIGHT then
            -- Reset game
            self:refresh()
        end
    end
end

function Game:handlePauseMenuClick(x, y)
    if not self.isPaused then return end
    
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    -- Calculate menu dimensions and position
    local menuWidth = 200
    local menuHeight = 150
    local menuX = (windowWidth - menuWidth) / 2
    local menuY = (windowHeight - menuHeight) / 2
    
    -- Button dimensions
    local buttonWidth = 160
    local buttonHeight = 40
    local buttonX = menuX + (menuWidth - buttonWidth) / 2
    
    -- Resume button
    local resumeY = menuY + 40
    if x >= buttonX and x <= buttonX + buttonWidth and
       y >= resumeY and y <= resumeY + buttonHeight then
        
        self:togglePause()
    end
    
    -- Restart button
    local restartY = resumeY + buttonHeight + 20
    if x >= buttonX and x <= buttonX + buttonWidth and
       y >= restartY and y <= restartY + buttonHeight then
        if self.audio then
            self.audio:restart()
        end
        self:refresh()
    end
end

function Game:updatePauseMenu(x, y)
    if not self.isPaused then return end
    
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    -- Calculate menu dimensions and position
    local menuWidth = 200
    local menuHeight = 150
    local menuX = (windowWidth - menuWidth) / 2
    local menuY = (windowHeight - menuHeight) / 2
    
    -- Button dimensions
    local buttonWidth = 160
    local buttonHeight = 40
    local buttonX = menuX + (menuWidth - buttonWidth) / 2
    
    -- Update hover states
    local resumeY = menuY + 40
    self.pauseMenu.isResumeHovered = 
        x >= buttonX and x <= buttonX + buttonWidth and
        y >= resumeY and y <= resumeY + buttonHeight
    
    local restartY = resumeY + buttonHeight + 20
    self.pauseMenu.isRestartHovered = 
        x >= buttonX and x <= buttonX + buttonWidth and
        y >= restartY and y <= restartY + buttonHeight
end

function Game:handleMouseClick(screenX, screenY)
    -- Handle message box clicks first
    if self.gameState == self.GAME_STATES.VICTORY or 
       self.gameState == self.GAME_STATES.LOSS then
        self:handleMessageBoxClick(screenX, screenY)
        return
    end
    
    -- Handle pause menu clicks
    if self.isPaused then
        self:handlePauseMenuClick(screenX, screenY)
        return
    end
    
    -- Only handle grid clicks if game is active
    if self.gameState == self.GAME_STATES.PLAYING then
        -- Convert screen coordinates to grid coordinates
        local gridX, gridY = self:screenToGridCoords(screenX, screenY)
        
        if self:isValidPosition(gridX, gridY) then
            local block = self.grid.grid[gridY][gridX]
            if block.highlighted then
                if self.grid:selectBlock(gridX, gridY) then
                    local selectedBlocks = self.grid:getLargestConnectedGroup()
                    
                    if #selectedBlocks == 4 then
                        local tetriminoType = self.tetrimino:detectTetrimino(selectedBlocks)
                        if tetriminoType then
                            self.tetrimino:handleMatchedTetrimino(tetriminoType, selectedBlocks, self.grid)
                        end
                    end
                end
            end
        end
    end
end

function Game:screenToGridCoords(screenX, screenY)
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    local gridPixelWidth = self.GRID_WIDTH * self.GRID_SIZE
    local gridPixelHeight = self.GRID_HEIGHT * self.GRID_SIZE
    
    local offsetX = (windowWidth - gridPixelWidth) / 2
    local offsetY = (windowHeight - gridPixelHeight) / 2
    
    local gridX = math.floor((screenX - offsetX) / self.GRID_SIZE) + 1
    local gridY = math.floor((screenY - offsetY) / self.GRID_SIZE) + 1
    
    return gridX, gridY
end

function Game:update(dt)
    -- Handle pause menu hover states
    local mouseX, mouseY = love.mouse.getPosition()
    self:updatePauseMenu(mouseX, mouseY)
    self:updateMessageBox(mouseX, mouseY)
    
    -- Don't update game state if not playing
    if self.gameState ~= self.GAME_STATES.PLAYING then return end
    
    self.input:update(dt, self)
end

function Game:draw()
    -- Update window dimensions in UI manager
    if self.ui then
        self.ui.windowWidth = love.graphics.getWidth()
        self.ui.windowHeight = love.graphics.getHeight()
    end
    
    -- Draw UI elements in screen space
    if self.ui and self.tetrimino and self.render then
        self.ui:draw(self.tetrimino, self.render)
    end
    
    -- Now handle the centered game grid
    love.graphics.push()
    
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    local gridPixelWidth = self.GRID_WIDTH * self.GRID_SIZE
    local gridPixelHeight = self.GRID_HEIGHT * self.GRID_SIZE
    
    self.windowOffsetX = (windowWidth - gridPixelWidth) / 2
    self.windowOffsetY = (windowHeight - gridPixelHeight) / 2
    
    -- Draw grid and game elements with offset
    love.graphics.translate(self.windowOffsetX, self.windowOffsetY)
    
    -- Draw grid with Tetris state
    if self.render and self.grid then
        self.render:drawGrid(self.grid, self.tetris)
    end
    
    -- Safely check tetris mode before deciding whether to draw axolotl
    local inTetrisMode = false
    if self.tetris and self.tetris.isInTetrisMode then
        inTetrisMode = self.tetris:isInTetrisMode()
    end
    
    -- Only draw axolotl in navigation mode
    if not inTetrisMode then
        if self.render and self.axolotl then
            self.render:drawAxolotl(self.axolotl, self)
        end
    end
    
    love.graphics.pop()
    
    -- Draw screen-space UI elements after pop
    if self.ui and self.render and self.tetris then
        self.ui:drawScreenUI(self.render, self.tetris)
    end
    
    -- Draw pause menu overlay if paused
    if self.ui and self.isPaused then
        self.ui:drawPauseMenu(self, self.render)
    end
    
    -- Draw victory/loss message boxes
    if self.gameState == self.GAME_STATES.VICTORY then
        self.ui:drawMessageBox(
            "Freedom At Last! Thanks for playing!",
            "Concept, Programming, Design: Ziyan Xie\nMusic: Sihui Lin",
            "Play Again",
            self.messageBoxState.isButtonHovered
        )
    elseif self.gameState == self.GAME_STATES.LOSS then
        if self.lossReason == "no_more_sessions" then
            self.ui:drawMessageBox(
                "Transformation Power Depleted!",
                "Our axolotl can no longer transform blocks...\nStill trapped in the cycle!",
                "Try Again",
                self.messageBoxState.isButtonHovered
            )
        else
            -- Classic tetris stack-too-high loss
            self.ui:drawMessageBox(
                "Blocks Overflowing!",
                "Our axolotl got trapped by their own tetrimino towers!\nTime to rethink the escape plan...",
                "Try Again",
                self.messageBoxState.isButtonHovered
            )
        end
    end
end

return Game