local Game = {
    GRID_SIZE = 32,
    GRID_WIDTH = 12,
    GRID_HEIGHT = 21,
    COLORS = {
        background = {0.1, 0.1, 0.15},
        grid = {0.2, 0.2, 0.25},
        gridLine = {0.3, 0.3, 0.35, 0.5},
        trapBlock = {0.6, 0.4, 0.4},
        highlighted = {0.8, 0.6, 0.6},
        selected = {0.5, 0.5, 0.5},
        axolotl = {0.9, 0.5, 0.7}
    }
}

local Entities = require 'src/entities'

function Game:isValidPosition(x, y)
    return x >= 1 and x <= self.GRID_WIDTH and
           y >= 1 and y <= self.GRID_HEIGHT
end

function Game:canRotate()
    local ax, ay = self.axolotl.x, self.axolotl.y
    -- Check if we have space to rotate (not at edges)
    return ax > 1 and ax < self.GRID_WIDTH and ay > 1 and ay < self.GRID_HEIGHT
end

function Game:updateHighlights()
    -- Reset all highlights
    for y = 1, self.GRID_HEIGHT do
        for x = 1, self.GRID_WIDTH do
            self.grid[y][x].highlighted = false
        end
    end
    
    -- Apply new highlights based on axolotl position and rotation
    local ramiBlocks = self.axolotl:getRamiBlocks()
    for _, block in ipairs(ramiBlocks) do
        local x = self.axolotl.x + block.dx
        local y = self.axolotl.y + block.dy
        if self:isValidPosition(x, y) then
            self.grid[y][x].highlighted = true
        end
    end
end

function Game:handleMouseClick(mouseX, mouseY)
    -- Convert mouse coordinates to grid position
    local gridX = math.floor(mouseX / self.GRID_SIZE) + 1
    local gridY = math.floor(mouseY / self.GRID_SIZE) + 1
    
    if self:isValidPosition(gridX, gridY) then
        local block = self.grid[gridY][gridX]
        if block.highlighted then
            block.selected = not block.selected
        end
    end
end

function Game:moveAxolotl(dx, dy)
    local newX = self.axolotl.x + dx
    local newY = self.axolotl.y + dy
    
    if self:isValidPosition(newX, newY) then
        self.axolotl.x = newX
        self.axolotl.y = newY
        self:updateHighlights()
    end
end

function Game:rotateAxolotl()
    if self:canRotate() then
        self.axolotl.rotation = (self.axolotl.rotation + 90) % 360
        self:updateHighlights()
    end
end

function Game:update(dt)
    self.lastMove = self.lastMove + dt
    
    -- Handle input with move delay
    if self.lastMove >= self.MOVE_DELAY then
        if love.keyboard.isDown('w') then
            self:moveAxolotl(0, -1)
            self.lastMove = 0
        elseif love.keyboard.isDown('s') then
            self:moveAxolotl(0, 1)
            self.lastMove = 0
        elseif love.keyboard.isDown('a') then
            self:moveAxolotl(-1, 0)
            self.lastMove = 0
        elseif love.keyboard.isDown('d') then
            self:moveAxolotl(1, 0)
            self.lastMove = 0
        elseif love.keyboard.isDown('r') then
            self:rotateAxolotl()
            self.lastMove = 0
        end
    end
end

function Game:draw()
    -- Draw background
    love.graphics.setColor(self.COLORS.background)
    love.graphics.rectangle("fill", 0, 0,
        self.GRID_WIDTH * self.GRID_SIZE,
        self.GRID_HEIGHT * self.GRID_SIZE)
    
    -- Draw grid lines
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
                if block.selected then
                    love.graphics.setColor(self.COLORS.selected)
                elseif block.highlighted then
                    love.graphics.setColor(self.COLORS.highlighted)
                else
                    love.graphics.setColor(self.COLORS.trapBlock)
                end
                love.graphics.rectangle("fill",
                    (x-1) * self.GRID_SIZE + 1,
                    (y-1) * self.GRID_SIZE + 1,
                    self.GRID_SIZE - 2,
                    self.GRID_SIZE - 2
                )
            end
        end
    end
    
    -- Draw axolotl with rotation indicator
    love.graphics.setColor(self.COLORS.axolotl)
    love.graphics.push()
    love.graphics.translate(
        (self.axolotl.x-0.5) * self.GRID_SIZE,
        (self.axolotl.y-0.5) * self.GRID_SIZE
    )
    love.graphics.rotate(math.rad(self.axolotl.rotation))
    
    -- Main body
    love.graphics.rectangle("fill",
        -self.GRID_SIZE/3,
        -self.GRID_SIZE/3,
        self.GRID_SIZE*2/3,
        self.GRID_SIZE*2/3
    )
    
    -- Direction indicator
    love.graphics.polygon("fill",
        0, -self.GRID_SIZE/3,
        self.GRID_SIZE/4, 0,
        -self.GRID_SIZE/4, 0
    )
    
    love.graphics.pop()
end

function Game:new()
    local game = {
        grid = {},
        selectedBlocks = {},
        lastMove = 0,
        MOVE_DELAY = 0.15 -- Delay between moves in seconds
    }
    
    -- Set up metatable first
    setmetatable(game, {__index = self})
    
    -- Initialize grid
    for y = 1, self.GRID_HEIGHT do
        game.grid[y] = {}
        for x = 1, self.GRID_WIDTH do
            game.grid[y][x] = Entities.newBlock("trap")
        end
    end
    
    -- Create axolotl at bottom center
    game.axolotl = Entities.newAxolotl(
        math.floor(self.GRID_WIDTH / 2),
        self.GRID_HEIGHT - 1
    )
    
    -- Now we can safely call methods
    game:updateHighlights()
    
    return game
end

return Game