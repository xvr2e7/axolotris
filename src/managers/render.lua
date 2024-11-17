local RenderManager = {
    COLORS = {
        background = {0.1, 0.1, 0.15},
        grid = {0.2, 0.2, 0.25},
        gridLine = {0.3, 0.3, 0.35, 0.5},
        trapBlock = {0.6, 0.4, 0.4},
        highlighted = {0.8, 0.6, 0.6},
        selected = {0.5, 0.5, 0.5},
        axolotl = { 0.9, 0.5, 0.7 },
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

    -- Draw blocks with proper color transitions
    local currentTime = love.timer.getTime()
    for y = 1, self.gridHeight do
        for x = 1, self.gridWidth do
            local block = gridManager.grid[y][x]
            if block then
                if block.color and block.targetColor then
                    local progress = (currentTime - block.transitionStart) / block.transitionDuration
                    if progress < 1 then
                        -- Interpolate colors
                        local r = block.color[1] + (block.targetColor[1] - block.color[1]) * progress
                        local g = block.color[2] + (block.targetColor[2] - block.color[2]) * progress
                        local b = block.color[3] + (block.targetColor[3] - block.color[3]) * progress
                        love.graphics.setColor(r, g, b)
                    else
                        love.graphics.setColor(block.targetColor)
                    end
                elseif block.selected then
                    love.graphics.setColor(self.COLORS.selected)
                elseif block.highlighted then
                    love.graphics.setColor(self.COLORS.highlighted)
                else
                    love.graphics.setColor(self.COLORS.trapBlock)
                end
                
                love.graphics.rectangle("fill",
                    (x-1) * self.gridSize + 1,
                    (y-1) * self.gridSize + 1,
                    self.gridSize - 2,
                    self.gridSize - 2
                )
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

return RenderManager