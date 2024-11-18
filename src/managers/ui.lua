local UIManager = {
    SIDEBAR_OFFSET = 32 * 2,
    SIDEBAR_WIDTH = 4 * 32,
    ITEM_HEIGHT = 2.5 * 32,
    ITEM_PADDING = 32 * 0.5,
    PREVIEW_SCALE = 0.4,
    REFRESH_BUTTON_SIZE = 32,
    REFRESH_BUTTON_PADDING = 16
}

function UIManager:new(gridWidth, gridHeight, gridSize)
    local manager = {
        gridWidth = gridWidth,
        gridHeight = gridHeight,
        gridSize = gridSize,
        -- Calculate derived values
        sidebarOffset = gridSize * 2,
        sidebarWidth = gridSize * 4,
        itemHeight = gridSize * 2.5,
        itemPadding = gridSize * 0.5,
        previewScale = 0.4,
        refreshButtonSize = gridSize,
        refreshButtonPadding = gridSize * 0.5,
        -- Store window dimensions for refresh button positioning
        windowWidth = love.graphics.getWidth(),
        windowHeight = love.graphics.getHeight()
    }
    setmetatable(manager, {__index = self})
    return manager
end

function UIManager:isRefreshButtonClicked(x, y)
    -- Account for the actual screen position
    local buttonX = self.windowWidth - self.refreshButtonSize - self.refreshButtonPadding
    local buttonY = self.refreshButtonPadding
    
    return x >= buttonX and x <= buttonX + self.refreshButtonSize and
           y >= buttonY and y <= buttonY + self.refreshButtonSize
end

function UIManager:drawRefreshButton(renderManager)
    local buttonX = self.windowWidth - self.refreshButtonSize - self.refreshButtonPadding
    local buttonY = self.refreshButtonPadding
    
    -- Draw button background
    renderManager:drawRect(
        buttonX,
        buttonY,
        self.refreshButtonSize,
        self.refreshButtonSize,
        renderManager.COLORS.ui.background
    )
    
    -- Draw button border
    renderManager:drawRect(
        buttonX,
        buttonY,
        self.refreshButtonSize,
        self.refreshButtonSize,
        renderManager.COLORS.ui.border,
        "line"
    )
    
    -- Draw simple circle in the center
    love.graphics.setColor(renderManager.COLORS.ui.text)
    love.graphics.setLineWidth(2)
    
    local centerX = buttonX + self.refreshButtonSize / 2
    local centerY = buttonY + self.refreshButtonSize / 2
    local radius = self.refreshButtonSize * 0.3
    
    love.graphics.circle('line', centerX, centerY, radius)
    
    -- Reset line width
    love.graphics.setLineWidth(1)
end

function UIManager:draw(tetriminoManager, renderManager)  -- Removed unused tetrisManager
    -- Draw sidebar (in game space)
    self:drawSidebar(tetriminoManager, renderManager)
end

function UIManager:drawScreenUI(renderManager, tetrisManager)  -- Removed unused tetriminoManager
    self:drawRefreshButton(renderManager)
    self:drawModeIndicator(tetrisManager, renderManager)
end

function UIManager:drawSidebar(tetriminoManager, renderManager)
    local sidebarX = -self.sidebarWidth - self.sidebarOffset
    local sidebarY = 0
    
    -- Draw sidebar background
    renderManager:drawRect(
        sidebarX, 
        sidebarY,
        self.sidebarWidth,
        self.gridHeight * self.gridSize,
        renderManager.COLORS.ui.background
    )
    
    -- Draw sidebar border
    renderManager:drawRect(
        sidebarX,
        sidebarY,
        self.sidebarWidth,
        self.gridHeight * self.gridSize,
        renderManager.COLORS.ui.border,
        "line"
    )
    
    -- Draw tetrimino previews and counts
    local itemX = sidebarX + self.itemPadding
    local itemY = self.itemPadding
    
    for type, pattern in pairs(tetriminoManager.TETRIMINOES) do
        -- Draw preview background
        renderManager:drawRect(
            itemX,
            itemY,
            self.sidebarWidth - self.itemPadding * 2,
            self.itemHeight - self.itemPadding,
            renderManager.COLORS.ui.shadow
        )
        
        -- Draw tetrimino preview using pattern
        self:drawTetriminoPreview(
            type,
            pattern,
            itemX,
            itemY,
            tetriminoManager,
            renderManager
        )
        
        -- Draw count
        local count = tetriminoManager.tetriminoCounts[type] or 0
        self:drawTetriminoCount(
            count,
            itemX,
            itemY,
            renderManager
        )
        
        itemY = itemY + self.itemHeight
    end
end

function UIManager:drawTetriminoPreview(type, pattern, x, y, tetriminoManager, renderManager)
    -- Calculate pattern bounds
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    
    for _, pos in ipairs(pattern[1]) do -- pattern[1] is first rotation
        minX = math.min(minX, pos[1])
        maxX = math.max(maxX, pos[1])
        minY = math.min(minY, pos[2])
        maxY = math.max(maxY, pos[2])
    end
    
    -- Calculate pattern dimensions
    local patternWidth = (maxX - minX + 1) * self.gridSize * self.previewScale
    local patternHeight = (maxY - minY + 1) * self.gridSize * self.previewScale
    
    -- Calculate centered position
    local previewAreaWidth = self.sidebarWidth - self.itemPadding * 2
    local previewAreaHeight = self.itemHeight - self.itemPadding
    
    local centerX = x + (previewAreaWidth - patternWidth) / 2
    local centerY = y + (previewAreaHeight - patternHeight) / 2
    
    -- Adjust for pattern offset to ensure centering
    centerX = centerX - minX * self.gridSize * self.previewScale
    centerY = centerY - minY * self.gridSize * self.previewScale
    
    -- Draw each block of the tetrimino
    for _, pos in ipairs(pattern[1]) do
        renderManager:drawRect(
            centerX + pos[1] * self.gridSize * self.previewScale,
            centerY + pos[2] * self.gridSize * self.previewScale,
            self.gridSize * self.previewScale - 1,
            self.gridSize * self.previewScale - 1,
            tetriminoManager.COLORS[type]
        )
    end
end

function UIManager:drawTetriminoCount(count, x, y, renderManager)
    local TEXT_SCALE = 1.2
    local font = love.graphics.getFont()

    -- Calculate text dimensions
    local textWidth = font:getWidth(tostring(count)) * TEXT_SCALE
    local textHeight = font:getHeight() * TEXT_SCALE

    -- Position in bottom right of preview area
    local textX = x + (self.sidebarWidth - self.itemPadding * 2) - textWidth
    local textY = y + (self.itemHeight - self.itemPadding) - textHeight

    -- Draw shadow with slight offset
    renderManager:drawText(
        tostring(count),
        textX + 1,
        textY + 1,
        renderManager.COLORS.ui.shadow,
        TEXT_SCALE
    )

    -- Draw main text
    renderManager:drawText(
        tostring(count),
        textX,
        textY,
        renderManager.COLORS.ui.text,
        TEXT_SCALE
    )
end

function UIManager:drawModeIndicator(tetrisManager, renderManager)
    if not tetrisManager then return end
    
    local indicatorX = self.windowWidth - self.refreshButtonSize - self.refreshButtonPadding
    local indicatorY = self.refreshButtonPadding * 2 + self.refreshButtonSize
    
    -- Draw mode box
    renderManager:drawRect(
        indicatorX,
        indicatorY,
        self.refreshButtonSize,
        self.refreshButtonSize * 0.75,
        renderManager.COLORS.ui.background
    )
    
    renderManager:drawRect(
        indicatorX,
        indicatorY,
        self.refreshButtonSize,
        self.refreshButtonSize * 0.75,
        renderManager.COLORS.ui.border,
        "line"
    )
    
    -- Draw mode indicators
    local fontSize = love.graphics.getFont():getHeight()
    local textY = indicatorY + (self.refreshButtonSize * 0.75 - fontSize) / 2
    
    -- Navigation mode indicator
    love.graphics.setColor(
        tetrisManager:isInTetrisMode() and 
        renderManager.COLORS.ui.modeInactive or 
        renderManager.COLORS.ui.modeActive
    )
    love.graphics.print(
        "N",
        indicatorX + self.refreshButtonSize * 0.25,
        textY
    )
    
    -- Tetris mode indicator
    love.graphics.setColor(
        tetrisManager:isInTetrisMode() and 
        renderManager.COLORS.ui.modeActive or 
        renderManager.COLORS.ui.modeInactive
    )
    love.graphics.print(
        "T",
        indicatorX + self.refreshButtonSize * 0.6,
        textY
    )
    
    -- Draw session counter
    local counterY = indicatorY + self.refreshButtonSize * 0.75 + self.refreshButtonPadding
    renderManager:drawRect(
        indicatorX,
        counterY,
        self.refreshButtonSize,
        self.refreshButtonSize * 0.5,
        renderManager.COLORS.ui.background
    )
    
    renderManager:drawRect(
        indicatorX,
        counterY,
        self.refreshButtonSize,
        self.refreshButtonSize * 0.5,
        renderManager.COLORS.ui.border,
        "line"
    )
    
    love.graphics.setColor(renderManager.COLORS.ui.counter)
    -- Format counter as "X/10"
    local counterText = string.format("%d/10", tetrisManager.sessionCount)
    love.graphics.print(
        counterText,
        indicatorX + (self.refreshButtonSize - love.graphics.getFont():getWidth(counterText)) / 2,
        counterY + (self.refreshButtonSize * 0.5 - fontSize) / 2
    )
end

return UIManager