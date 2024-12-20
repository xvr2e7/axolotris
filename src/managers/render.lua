local RenderManager = {
    -- Previous color definitions remain unchanged...
    COLORS = {
        background = {0.1, 0.1, 0.15},
        grid = {0.2, 0.2, 0.25},
        gridLine = {0.3, 0.3, 0.35, 0.5},
        trapBlock = {0.6, 0.4, 0.4},
        highlighted = {0.8, 0.6, 0.6},
        selected = {0.5, 0.5, 0.5},
        axolotl = {0.9, 0.5, 0.7},
        barrier = {0.3, 0.3, 0.3},
        weakBarrier = {0.4, 0.4, 0.4},
        disabled = {0.9, 0.9, 0.9, 0.7},
        safeBlock = {0.5, 0.8, 0.5},
        safeBlockSelected = {0.4, 0.7, 0.4},
        heart = {0.9, 0.2, 0.2},
        symbol = {1, 1, 1},
        exit = {0.8, 0.8, 0.4},
        default = {0.7, 0.7, 0.7},
        tetrisGhost = {1, 1, 1, 0.2},  -- New color for ghost piece
        ui = {
            background = {0.15, 0.15, 0.2},
            border = {0.3, 0.3, 0.35},
            text = {0.9, 0.9, 0.9},
            shadow = {0.1, 0.1, 0.15, 0.5},
            modeActive = {0.2, 0.8, 0.2},
            modeInactive = {0.4, 0.4, 0.4},
            counter = {0.9, 0.9, 0.9}
        }
    }
}

function RenderManager:new(gridWidth, gridHeight, gridSize)
    local manager = {
        gridWidth = gridWidth,
        gridHeight = gridHeight,
        gridSize = gridSize
    }
    setmetatable(manager, {__index = self})
    return manager
end

-- Primitive drawing operations that other components can use
function RenderManager:drawRect(x, y, width, height, color, mode)
    love.graphics.setColor(color)
    love.graphics.rectangle(mode or "fill", x, y, width, height)
end

function RenderManager:drawText(text, x, y, color, scale)
    love.graphics.setColor(color)
    love.graphics.print(text, x, y, 0, scale or 1, scale or 1)
end

function RenderManager:drawBlock(x, y, block, size)
    -- Draw base block
    self:setColor(block.color)
    love.graphics.rectangle(
        "fill",
        x + 1,
        y + 1,
        size - 2,
        size - 2
    )
    
    -- Draw border for primary barriers
    if block.barrier and block.barrier.strength == "primary" then
        -- Draw thick dark border
        love.graphics.setLineWidth(3)
        self:setColor({0.15, 0.15, 0.15})
        love.graphics.rectangle(
            "line",
            x + 2,
            y + 2,
            size - 4,
            size - 4
        )
        love.graphics.setLineWidth(1)
    end
    
    -- Draw symbols
    if block.barrier then
        self:drawBarrierSymbol(x, y, block.barrier.type)
    elseif block.safe and block.showHeart then
        self:drawPixelHeart(x, y)
    end
end

function RenderManager:drawGrid(gridManager, tetrisManager)
    if not gridManager then return end
    
    -- Safely check tetris mode
    local inTetrisMode = false
    if tetrisManager and tetrisManager.isInTetrisMode then
        inTetrisMode = tetrisManager:isInTetrisMode()
    end
    
    -- Draw background
    self:setColor(self.COLORS.background)
    love.graphics.rectangle("fill", 0, 0,
        self.gridWidth * self.gridSize,
        self.gridHeight * self.gridSize)
    
    -- First pass: Draw ghost piece in Tetris mode
    if inTetrisMode and tetrisManager and tetrisManager.ghostPiece then
        for _, block in ipairs(tetrisManager.ghostPiece.pattern) do
            local x = (tetrisManager.ghostPiece.x + block[1] - 1) * self.gridSize
            local y = (tetrisManager.ghostPiece.y + block[2] - 1) * self.gridSize
            
            -- Draw semi-transparent ghost block
            self:setColor({
                tetrisManager.ghostPiece.color[1],
                tetrisManager.ghostPiece.color[2],
                tetrisManager.ghostPiece.color[3],
                0.3
            })
            love.graphics.rectangle(
                'fill',
                x + 1,
                y + 1,
                self.gridSize - 2,
                self.gridSize - 2
            )
        end
    end
    
    -- Second pass: Draw all non-portal blocks
    for y = 1, self.gridHeight do
        for x = 1, self.gridWidth do
            local block = gridManager.grid[y][x]
            if block and not block.isExit then
                local blockX = (x-1) * self.gridSize
                local blockY = (y-1) * self.gridSize
                
                -- In Tetris mode, don't draw highlighted/selected states in buffer zone
                if inTetrisMode and tetrisManager.game and 
                   y <= tetrisManager.game.BUFFER_ZONE_HEIGHT then
                    if not block.locked then
                        -- Draw empty block in buffer zone
                        self:setColor(self.COLORS.background)
                        love.graphics.rectangle("fill",
                            blockX + 1,
                            blockY + 1,
                            self.gridSize - 2,
                            self.gridSize - 2
                        )
                    else
                        -- Draw locked tetris blocks
                        self:setColor(block.color)
                        love.graphics.rectangle("fill",
                            blockX + 1,
                            blockY + 1,
                            self.gridSize - 2,
                            self.gridSize - 2
                        )
                    end
                else
                    -- Draw normal block
                    self:setColor(block.color)
                    love.graphics.rectangle("fill",
                        blockX + 1,
                        blockY + 1,
                        self.gridSize - 2,
                        self.gridSize - 2
                    )
                    
                    -- Draw primary barrier border
                    if block.barrier and block.barrier.strength == "primary" then
                        love.graphics.setLineWidth(3)
                        self:setColor({0.15, 0.15, 0.15})
                        love.graphics.rectangle(
                            "line",
                            blockX + 2,
                            blockY + 2,
                            self.gridSize - 4,
                            self.gridSize - 4
                        )
                        love.graphics.setLineWidth(1)
                    end
                    
                    -- Draw block symbols
                    if block.barrier then
                        self:drawBarrierSymbol(blockX, blockY, block.barrier.type)
                    elseif block.safe and block.showHeart then
                        self:drawPixelHeart(blockX, blockY)
                    end
                end
            end
        end
    end
    
    -- Third pass: Draw grid lines
    self:setColor(self.COLORS.gridLine)
    for x = 0, self.gridWidth do
        love.graphics.line(
            x * self.gridSize, 0,
            x * self.gridSize, self.gridHeight * self.gridSize
        )
    end
    
    for y = 0, self.gridHeight do
        love.graphics.line(
            0, y * self.gridSize,
            self.gridWidth * self.gridSize, y * self.gridSize
        )
    end
    
    -- Fourth pass: Draw exit portal
    for y = 1, self.gridHeight do
        for x = 1, self.gridWidth do
            local block = gridManager.grid[y][x]
            if block and block.isExit then
                if not gridManager.grid[y][x-1] or not gridManager.grid[y][x-1].isExit then
                    self:drawExitPortal((x-1) * self.gridSize, (y-1) * self.gridSize)
                    break
                end
            end
        end
    end
    
    -- Final pass: Draw active Tetris piece
    if inTetrisMode and tetrisManager and tetrisManager.activePiece then
        for _, block in ipairs(tetrisManager.activePiece.pattern) do
            local x = (tetrisManager.activePiece.x + block[1] - 1) * self.gridSize
            local y = (tetrisManager.activePiece.y + block[2] - 1) * self.gridSize
            
            self:setColor(tetrisManager.activePiece.color)
            love.graphics.rectangle(
                'fill',
                x + 1,
                y + 1,
                self.gridSize - 2,
                self.gridSize - 2
            )
        end
    end
end

function RenderManager:drawAxolotl(axolotl, game)
   if not game or not game.sprites or not game.sprites.axolotl then return end

   local direction = "down"
   if axolotl.rotation == 0 then direction = "up"
   elseif axolotl.rotation == 90 then direction = "right"
   elseif axolotl.rotation == 270 then direction = "left"
   end
   
   love.graphics.setColor(1, 1, 1)
   local sprite = game.sprites.axolotl[direction]
   
   -- Scale sprite to fit grid cell while maintaining aspect ratio
   local scale = (self.gridSize * 0.8) / sprite:getWidth() -- Using 80% of grid size
   
   -- Center the sprite in the grid cell
   local spriteWidth = sprite:getWidth() * scale
   local spriteHeight = sprite:getHeight() * scale
   local x = (axolotl.x - 1) * self.gridSize + (self.gridSize - spriteWidth) / 2
   local y = (axolotl.y - 1) * self.gridSize + (self.gridSize - spriteHeight) / 2
   
   love.graphics.draw(sprite, x, y, 0, scale, scale)
end

function RenderManager:drawPixelHeart(x, y)
    local blockSize = self.gridSize
    local size = blockSize * 0.5
    local centerX = x + blockSize / 2
    local centerY = y + blockSize / 2 - size * 0.1
    
    -- Draw the heart shape with pixel art styling
    love.graphics.setColor(self.COLORS.heart)
    
    local pixelSize = size / 4
    
    -- Top row (two separate pixels, wider apart)
    love.graphics.rectangle('fill',
        centerX - pixelSize * 2, centerY - pixelSize,
        pixelSize, pixelSize)
    love.graphics.rectangle('fill',
        centerX + pixelSize, centerY - pixelSize,
        pixelSize, pixelSize)
    
    -- Second row (full width, wider)
    love.graphics.rectangle('fill',
        centerX - pixelSize * 2, centerY,
        pixelSize * 4, pixelSize)
    
    -- Third row (wider)
    love.graphics.rectangle('fill',
        centerX - pixelSize * 1.5, centerY + pixelSize,
        pixelSize * 3, pixelSize)
    
    -- Bottom pixel (wider)
    love.graphics.rectangle('fill',
        centerX - pixelSize, centerY + pixelSize * 2,
        pixelSize * 2, pixelSize)
    
    -- Add subtle shading for depth
    love.graphics.setColor(0.9, 0.2, 0.2, 0.3)
    love.graphics.rectangle('fill',
        centerX - pixelSize, centerY + pixelSize * 2,
        pixelSize * 2, pixelSize)
end

function RenderManager:drawExitPortal(x, y)
    -- Calculate center point between the two merged exit blocks
    local centerX = x + self.gridSize  -- Center of two blocks
    local centerY = y + self.gridSize * 0.5  -- Center of one block height
    
    -- Portal base size
    local portalWidth = self.gridSize * 2    -- Width of two blocks
    local portalHeight = self.gridSize       -- Height of one block
    
    -- Create a stencil to clip the halo effect at the grid boundary
    love.graphics.stencil(function()
        love.graphics.rectangle('fill', 0, 0, 
            self.gridWidth * self.gridSize,
            self.gridHeight * self.gridSize)
    end, 'replace', 1)
    love.graphics.setStencilTest('equal', 1)
    
    -- Draw radial gradient halo
    local maxRadius = self.gridSize * 1.5  -- Reduced from 3 to 1.5
    local segments = 64  -- Keep smooth circle
    
    -- Draw gradient circles from outside in for better blending
    for i = 15, 1, -1 do  -- Reduced layers from 20 to 15
        local alpha = 0.15 * (i / 15)  -- Adjusted for new layer count
        local scale = 1 + (i - 1) * 0.08  -- Reduced scale increment from 0.15 to 0.08
        
        love.graphics.setColor(
            self.COLORS.exit[1],
            self.COLORS.exit[2],
            self.COLORS.exit[3],
            alpha
        )
        
        love.graphics.circle(
            'fill',
            centerX,
            centerY,
            maxRadius * scale / 2,
            segments
        )
    end
    
    -- Draw the base portal (merged blocks) on top of the halo
    love.graphics.setColor(self.COLORS.exit[1], self.COLORS.exit[2], self.COLORS.exit[3], 1)
    love.graphics.rectangle('fill',
        x,
        y,
        portalWidth,
        portalHeight
    )
    
    -- Reset stencil test
    love.graphics.setStencilTest()
end

function RenderManager:drawBarrierSymbol(x, y, barrierType)
    local blockSize = self.gridSize
    local size = blockSize * 0.3
    local centerX = x + blockSize / 2
    local centerY = y + blockSize / 2
    
    love.graphics.setColor(self.COLORS.symbol)
    
    if barrierType == "horizontal" then
        -- Right arrow
        love.graphics.polygon('fill',
            centerX - size, centerY - size/3,
            centerX + size, centerY,
            centerX - size, centerY + size/3
        )
    elseif barrierType == "vertical" then
        -- Up arrow
        love.graphics.polygon('fill',
            centerX - size/3, centerY + size,
            centerX, centerY - size,
            centerX + size/3, centerY + size
        )
    elseif barrierType == "cross" then
        -- Plus sign
        local thickness = size * 0.3
        love.graphics.rectangle('fill',
            centerX - thickness/2, centerY - size,
            thickness, size * 2
        )
        love.graphics.rectangle('fill',
            centerX - size, centerY - thickness/2,
            size * 2, thickness
        )
    end
end

function RenderManager:setColor(color)
    -- If color is nil or invalid, use default color
    if not color or type(color) ~= "table" or #color < 3 then
        color = self.COLORS.default
    end
    
    -- Ensure we have valid numeric values
    local r = tonumber(color[1]) or self.COLORS.default[1]
    local g = tonumber(color[2]) or self.COLORS.default[2]
    local b = tonumber(color[3]) or self.COLORS.default[3]
    local a = tonumber(color[4]) or 1 -- Default alpha to 1 if not specified
    
    love.graphics.setColor(r, g, b, a)
end


return RenderManager