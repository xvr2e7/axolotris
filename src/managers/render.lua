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
        disabled = {0.9, 0.9, 0.9},
        safeBlock = {0.5, 0.8, 0.5},
        symbol = {1, 1, 1},  -- White color for symbols
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
    
    -- Draw grid lines
    love.graphics.setColor(self.COLORS.gridLine)
    for y = 0, self.gridHeight do
        love.graphics.line(
            0, y * self.gridSize,
            self.gridWidth * self.gridSize, y * self.gridSize
        )
    end
    for x = 0, self.gridWidth do
        love.graphics.line(
            x * self.gridSize, 0,
            x * self.gridSize, self.gridHeight * self.gridSize
        )
    end

    -- Draw blocks
    for y = 1, self.gridHeight do
        for x = 1, self.gridWidth do
            local block = gridManager.grid[y][x]
            if block then
                -- Calculate block position
                local blockX = (x-1) * self.gridSize
                local blockY = (y-1) * self.gridSize
                
                -- Draw block background
                if block.barrier then
                    love.graphics.setColor(block.barrier.strength == "primary" 
                        and self.COLORS.barrier 
                        or self.COLORS.weakBarrier)
                elseif block.safe then
                    love.graphics.setColor(self.COLORS.safeBlock)
                elseif block.disabled then
                    love.graphics.setColor(self.COLORS.disabled)
                elseif block.selected then
                    love.graphics.setColor(self.COLORS.selected)
                elseif block.highlighted then
                    love.graphics.setColor(self.COLORS.highlighted)
                else
                    love.graphics.setColor(self.COLORS.trapBlock)
                end
                
                love.graphics.rectangle("fill",
                    blockX + 1,
                    blockY + 1,
                    self.gridSize - 2,
                    self.gridSize - 2
                )
                
                -- Draw barrier symbols or safe block hearts
                if block.barrier then
                    self:drawBarrierSymbol(blockX, blockY, block.barrier.type)
                elseif block.safe then
                    self:drawHeartSymbol(blockX, blockY)
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
function RenderManager:drawBarrierSymbol(x, y, barrierType)
    local blockSize = self.gridSize
    local margin = blockSize * 0.2
    local centerX = x + blockSize / 2
    local centerY = y + blockSize / 2
    local size = blockSize * 0.3
    
    love.graphics.setColor(self.COLORS.symbol)
    
    if barrierType == "horizontal" then
        -- Draw right-pointing arrow
        love.graphics.polygon('fill',
            centerX - size, centerY - size/2,
            centerX + size, centerY,
            centerX - size, centerY + size/2
        )
    elseif barrierType == "vertical" then
        -- Draw up-pointing arrow
        love.graphics.polygon('fill',
            centerX - size/2, centerY + size,
            centerX, centerY - size,
            centerX + size/2, centerY + size
        )
    elseif barrierType == "cross" then
        -- Draw plus sign
        love.graphics.rectangle('fill',
            centerX - size/4, centerY - size,
            size/2, size*2
        )
        love.graphics.rectangle('fill',
            centerX - size, centerY - size/4,
            size*2, size/2
        )
    end
end

function RenderManager:drawHeartSymbol(x, y)
    local blockSize = self.gridSize
    local size = blockSize * 0.2
    local centerX = x + blockSize / 2
    local centerY = y + blockSize / 2
    
    love.graphics.setColor(self.COLORS.symbol)
    
    -- Draw heart shape using circles and triangles
    love.graphics.circle('fill', centerX - size, centerY - size/2, size)
    love.graphics.circle('fill', centerX + size, centerY - size/2, size)
    love.graphics.polygon('fill',
        centerX - size*1.5, centerY - size/2,
        centerX + size*1.5, centerY - size/2,
        centerX, centerY + size*1.5
    )
end

return RenderManager