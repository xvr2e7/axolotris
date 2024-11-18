local Tetrimino = require('src.managers.tetrimino')
local Grid = require('src.managers.grid')
local Render = require('src.managers.render')
local Input = require('src.managers.input')
local UI = require('src.managers.ui')

local Game = {
    GRID_SIZE = 32,
    GRID_WIDTH = 12,
    GRID_HEIGHT = 21,
    MOVE_DELAY = 0.15
}

function Game:new()
    local game = {
        tetrimino = Tetrimino:new(),
        grid = Grid:new(self.GRID_WIDTH, self.GRID_HEIGHT),
        render = Render:new(self.GRID_WIDTH, self.GRID_HEIGHT, self.GRID_SIZE),
        input = Input:new(self.MOVE_DELAY, self.GRID_SIZE),
        ui = UI:new(self.GRID_WIDTH, self.GRID_HEIGHT, self.GRID_SIZE),
        -- Create axolotl at the bottom of the grid
        axolotl = {
            x = math.floor(self.GRID_WIDTH / 2),
            y = self.GRID_HEIGHT,
            rotation = 0
        }
    }
    setmetatable(game, {__index = self})
    
    -- Initial highlight update
    game:updateHighlightedBlocks()
    return game
end

function Game:isValidPosition(x, y)
    -- Check grid boundaries
    if x < 1 or x > self.GRID_WIDTH or y < 1 or y > self.GRID_HEIGHT then
        return false
    end
    
    -- Check if position is disabled by barrier field
    local block = self.grid.grid[y][x]
    if block.disabled and not block.safe then
        return false
    end
    
    return true
end

function Game:canRotateAtCurrentPosition()
    local x, y = self.axolotl.x, self.axolotl.y
    local nextRotation = (self.axolotl.rotation + 90) % 360
    
    -- Get positions that would be reached after rotation
    local futurePositions = self:getReachablePositionsForRotation(nextRotation)
    
    -- Check if all future positions are valid
    for _, pos in ipairs(futurePositions) do
        if not self:isValidPosition(pos.x, pos.y) then
            return false
        end
    end
    
    return true
end

function Game:moveAxolotl(dx, dy)
    local newX = self.axolotl.x + dx
    local newY = self.axolotl.y + dy
    
    if self:isValidPosition(newX, newY) then
        -- Clear highlights before moving
        self:clearAllHighlights()
        
        self.axolotl.x = newX
        self.axolotl.y = newY
        
        -- Update highlights for new position
        self:updateHighlightedBlocks()
    end
end

function Game:rotateAxolotl()
    -- Only allow rotation if there's space
    if self:canRotateAtCurrentPosition() then
        -- Clear highlights before rotating
        self:clearAllHighlights()
        
        self.axolotl.rotation = (self.axolotl.rotation + 90) % 360
        
        -- Update highlights for new rotation
        self:updateHighlightedBlocks()
    end
end

function Game:clearAllHighlights()
    for y = 1, self.GRID_HEIGHT do
        for x = 1, self.GRID_WIDTH do
            if self.grid.grid[y] and self.grid.grid[y][x] then
                self.grid.grid[y][x].highlighted = false
            end
        end
    end
end

function Game:getReachablePositionsForRotation(rotation)
    local x, y = self.axolotl.x, self.axolotl.y
    local positions = {}
    
    if rotation == 0 then -- Up
        positions = {
            {x = x-1, y = y}, -- Left
            {x = x+1, y = y}, -- Right
            {x = x, y = y-1}  -- Up
        }
    elseif rotation == 90 then -- Right
        positions = {
            {x = x, y = y-1}, -- Up
            {x = x, y = y+1}, -- Down
            {x = x+1, y = y}  -- Right
        }
    elseif rotation == 180 then -- Down
        positions = {
            {x = x-1, y = y}, -- Left
            {x = x+1, y = y}, -- Right
            {x = x, y = y+1}  -- Down
        }
    else -- Left (270)
        positions = {
            {x = x, y = y-1}, -- Up
            {x = x, y = y+1}, -- Down
            {x = x-1, y = y}  -- Left
        }
    end
    
    return positions
end

function Game:updateHighlightedBlocks()
    -- Clear all highlights first
    self:clearAllHighlights()
    
    -- Get reachable positions based on current rotation
    local positions = self:getReachablePositionsForRotation(self.axolotl.rotation)
    
    -- Only highlight valid positions that aren't disabled by barriers
    for _, pos in ipairs(positions) do
        if self:isValidPosition(pos.x, pos.y) then
            self.grid.grid[pos.y][pos.x].highlighted = true
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

function Game:handleMouseClick(screenX, screenY)
    local gridX, gridY = self:screenToGridCoords(screenX, screenY)
    
    if self:isValidPosition(gridX, gridY) then
        local block = self.grid.grid[gridY][gridX]
        -- Only allow selection/deselection within highlighted area
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