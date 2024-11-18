local RenderManager = {
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
        heart = {0.9, 0.2, 0.2},  -- Red heart
        symbol = {1, 1, 1},  -- White for other symbols
        exit = {0.8, 0.8, 0.4},  -- Yellow-ish for exit
        ui = {
            background = {0.15, 0.15, 0.2},
            border = {0.3, 0.3, 0.35},
            text = {0.9, 0.9, 0.9},
            shadow = {0.1, 0.1, 0.15, 0.5}
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

function RenderManager:drawGrid(gridManager)
    -- Draw background
    love.graphics.setColor(self.COLORS.background)
    love.graphics.rectangle("fill", 0, 0,
        self.gridWidth * self.gridSize,
        self.gridHeight * self.gridSize)
    
    -- First pass: Draw all non-portal blocks and regular grid lines
    for y = 1, self.gridHeight do
        for x = 1, self.gridWidth do
            local block = gridManager.grid[y][x]
            if block and not block.isExit then
                local blockX = (x-1) * self.gridSize
                local blockY = (y-1) * self.gridSize
                
                -- Draw regular block background
                love.graphics.setColor(block.color)
                love.graphics.rectangle("fill",
                    blockX + 1,
                    blockY + 1,
                    self.gridSize - 2,
                    self.gridSize - 2
                )
                
                -- Draw symbols
                if block.barrier then
                    self:drawBarrierSymbol(blockX, blockY, block.barrier.type)
                elseif block.safe and block.showHeart then
                    self:drawPixelHeart(blockX, blockY)
                end
            end
        end
    end
    
    -- Draw grid lines, skipping the portal area
    love.graphics.setColor(self.COLORS.gridLine)
    
    -- Draw vertical lines
    for x = 0, self.gridWidth do
        local skipLine = false
        -- Check if this line would be between exit blocks
        local exitX = math.floor(self.gridWidth / 2)
        if x > exitX - 1 and x < exitX + 2 then
            skipLine = true
        end
        
        if not skipLine then
            love.graphics.line(
                x * self.gridSize, 0,
                x * self.gridSize, self.gridHeight * self.gridSize
            )
        end
    end
    
    -- Draw horizontal lines
    for y = 0, self.gridHeight do
        love.graphics.line(
            0, y * self.gridSize,
            self.gridWidth * self.gridSize, y * self.gridSize
        )
    end
    
    -- Second pass: Draw the portal last
    for y = 1, self.gridHeight do
        for x = 1, self.gridWidth do
            local block = gridManager.grid[y][x]
            if block and block.isExit then
                -- Only draw exit portal once for the leftmost exit block
                if not gridManager.grid[y][x-1] or not gridManager.grid[y][x-1].isExit then
                    self:drawExitPortal((x-1) * self.gridSize, (y-1) * self.gridSize)
                    break  -- Exit after drawing the portal once
                end
            end
        end
    end
end

function RenderManager:drawAxolotl(axolotl)
    love.graphics.setColor(self.COLORS.axolotl)
    love.graphics.push()
    love.graphics.translate(
        (axolotl.x - 0.5) * self.gridSize,
        (axolotl.y - 0.5) * self.gridSize
    )
    love.graphics.rotate(math.rad(axolotl.rotation))

    -- Main body
    love.graphics.rectangle("fill",
        -self.gridSize / 3,
        -self.gridSize / 3,
        self.gridSize * 2 / 3,
        self.gridSize * 2 / 3
    )

    -- Direction indicator
    love.graphics.polygon("fill",
        0, -self.gridSize / 3,
        self.gridSize / 4, 0,
        -self.gridSize / 4, 0
    )

    love.graphics.pop()
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

return RenderManager