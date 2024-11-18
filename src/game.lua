local Tetrimino = require('src.managers.tetrimino')
local Grid = require('src.managers.grid')
local Render = require('src.managers.render')
local Input = require('src.managers.input')
local UI = require('src.managers.ui')

local Game = {
    GRID_SIZE = 32,
    GRID_WIDTH = 12,
    GRID_HEIGHT = 21,
    MOVE_DELAY = 0.15,
    BUFFER_ZONE_HEIGHT = 7
}

function Game:new()
    local game = {
        tetrimino = Tetrimino:new(),
        grid = Grid:new(self.GRID_WIDTH, self.GRID_HEIGHT),
        render = Render:new(self.GRID_WIDTH, self.GRID_HEIGHT, self.GRID_SIZE),
        input = Input:new(self.MOVE_DELAY, self.GRID_SIZE),
        ui = UI:new(self.GRID_WIDTH, self.GRID_HEIGHT, self.GRID_SIZE),
        -- Create axolotl at the bottom middle of the grid
        axolotl = {
            x = math.floor(self.GRID_WIDTH / 2),
            y = self.GRID_HEIGHT,
            rotation = 0
        }
    }
    setmetatable(game, {__index = self})
    
    -- Initialize initial block highlighting
    game:initializeHighlighting()
    return game
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
    
    -- Can't move onto disabled blocks unless they're safe
    if block.disabled and not block.safe then
        return false
    end
    
    return true
end

function Game:isInBufferZone(y)
    return y <= self.BUFFER_ZONE_HEIGHT
end

function Game:moveAxolotl(dx, dy)
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
                    else
                        block.color = self.grid.colors.original
                    end
                end
                block.highlighted = false
            end
        end
        
        -- Restore heart on previous position if it was a safe block
        local currentBlock = self.grid.grid[self.axolotl.y][self.axolotl.x]
        if currentBlock.safe then
            currentBlock.showHeart = true
        end
        
        -- Update axolotl position
        self.axolotl.x = newX
        self.axolotl.y = newY
        
        -- Hide heart on new position if it's a safe block
        local targetBlock = self.grid.grid[newY][newX]
        if targetBlock.safe then
            targetBlock.showHeart = false
        end
        
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
        
        -- Check for victory condition
        if self:isInBufferZone(newY) and self.grid.grid[newY][newX].isExit then
            self:handleVictory()
        end
    end
end

function Game:rotateAxolotl()
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

function Game:handleMouseClick(screenX, screenY)
    local gridX, gridY = self:screenToGridCoords(screenX, screenY)
    
    if self:isValidPosition(gridX, gridY) then
        local block = self.grid.grid[gridY][gridX]
        -- Only allow selection/deselection within highlighted blocks
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

function Game:handleVictory()
    print("Victory! The axolotl has escaped!")
end

function Game:update(dt)
    self.input:update(dt, self)
end

function Game:draw()
    love.graphics.push()
    
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    local gridPixelWidth = self.GRID_WIDTH * self.GRID_SIZE
    local gridPixelHeight = self.GRID_HEIGHT * self.GRID_SIZE
    
    self.windowOffsetX = (windowWidth - gridPixelWidth) / 2
    self.windowOffsetY = (windowHeight - gridPixelHeight) / 2
    
    love.graphics.translate(self.windowOffsetX, self.windowOffsetY)
    
    self.render:drawGrid(self.grid)
    self.render:drawAxolotl(self.axolotl)
    self.ui:drawSidebar(self.tetrimino, self.render)
    
    love.graphics.pop()
end

return Game