local UIManager = {
    SIDEBAR_OFFSET = 32,
    SIDEBAR_WIDTH = 4 * 32,
    ITEM_HEIGHT = 2.5 * 32,
    ITEM_PADDING = 32 * 0.5,
    PREVIEW_SCALE = 0.4,
    MODE_INDICATOR_SIZE = 32,
    SCREEN_PADDING = 16,
    MESSAGE_BOX_WIDTH = 300,
    MESSAGE_BOX_HEIGHT = 200,
    MESSAGE_PADDING = 20,
    MESSAGE_BUTTON_WIDTH = 160,
    MESSAGE_BUTTON_HEIGHT = 40  
}

function UIManager:new(gridWidth, gridHeight, gridSize)
    local manager = {
        gridWidth = gridWidth,
        gridHeight = gridHeight,
        gridSize = gridSize,
        sidebarOffset = gridSize * 2,
        sidebarWidth = gridSize * 4,
        itemHeight = gridSize * 2.5,
        itemPadding = gridSize * 0.5,
        previewScale = 0.4,
        modeIndicatorSize = gridSize,
        screenPadding = gridSize * 0.5,
        windowWidth = love.graphics.getWidth(),
        windowHeight = love.graphics.getHeight()
    }
    setmetatable(manager, {__index = self})
    return manager
end

function UIManager:draw(tetriminoManager, renderManager)  -- Removed unused tetrisManager
    -- Draw sidebar (in game space)
    self:drawSidebar(tetriminoManager, renderManager)
end

function UIManager:drawScreenUI(renderManager, tetrisManager)
    -- Safety check for render manager
    if not renderManager then return end
    
    -- draw mode indicator
    if tetrisManager then
        self:drawModeIndicator(tetrisManager, renderManager)
    end
end

function UIManager:drawPauseMenu(game, renderManager)
    if not game.isPaused then return end
    
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, self.windowWidth, self.windowHeight)
    
    -- Menu panel dimensions
    local menuWidth = 200
    local menuHeight = 150
    local menuX = (self.windowWidth - menuWidth) / 2
    local menuY = (self.windowHeight - menuHeight) / 2
    
    -- Draw menu background
    renderManager:drawRect(
        menuX, menuY,
        menuWidth, menuHeight,
        renderManager.COLORS.ui.background
    )
    
    -- Draw menu border
    renderManager:drawRect(
        menuX, menuY,
        menuWidth, menuHeight,
        renderManager.COLORS.ui.border,
        "line"
    )
    
    -- Draw "PAUSED" text
    local font = love.graphics.getFont()
    local pausedText = "PAUSED"
    local textWidth = font:getWidth(pausedText)
    renderManager:drawText(
        pausedText,
        menuX + (menuWidth - textWidth) / 2,
        menuY + 10,
        renderManager.COLORS.ui.text
    )
    
    -- Button dimensions
    local buttonWidth = 160
    local buttonHeight = 40
    local buttonX = menuX + (menuWidth - buttonWidth) / 2
    
    -- Draw Resume button
    local resumeY = menuY + 40
    local resumeColor = game.pauseMenu.isResumeHovered and
        {0.3, 0.6, 0.3} or renderManager.COLORS.ui.background
    renderManager:drawRect(
        buttonX, resumeY,
        buttonWidth, buttonHeight,
        resumeColor
    )
    renderManager:drawRect(
        buttonX, resumeY,
        buttonWidth, buttonHeight,
        renderManager.COLORS.ui.border,
        "line"
    )
    local resumeText = "Resume"
    local resumeTextWidth = font:getWidth(resumeText)
    renderManager:drawText(
        resumeText,
        buttonX + (buttonWidth - resumeTextWidth) / 2,
        resumeY + (buttonHeight - font:getHeight()) / 2,
        renderManager.COLORS.ui.text
    )
    
    -- Draw Restart button
    local restartY = resumeY + buttonHeight + 20
    local restartColor = game.pauseMenu.isRestartHovered and
        {0.6, 0.3, 0.3} or renderManager.COLORS.ui.background
    renderManager:drawRect(
        buttonX, restartY,
        buttonWidth, buttonHeight,
        restartColor
    )
    renderManager:drawRect(
        buttonX, restartY,
        buttonWidth, buttonHeight,
        renderManager.COLORS.ui.border,
        "line"
    )
    local restartText = "Restart"
    local restartTextWidth = font:getWidth(restartText)
    renderManager:drawText(
        restartText,
        buttonX + (buttonWidth - restartTextWidth) / 2,
        restartY + (buttonHeight - font:getHeight()) / 2,
        renderManager.COLORS.ui.text
    )
end

function UIManager:drawSidebar(tetriminoManager, renderManager)
    
    local sidebarX = 16  -- Small padding from left edge
    local sidebarY = (love.graphics.getHeight() - (self.gridHeight * self.gridSize)) / 2
    
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
    local itemY = sidebarY + self.itemPadding
    
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
    -- Safety checks
    if not tetrisManager or not renderManager then return end
    
    -- Position mode indicator in top right with new measurements
    local indicatorX = self.windowWidth - self.modeIndicatorSize - self.screenPadding
    local indicatorY = self.screenPadding
    
    -- Draw mode box
    renderManager:drawRect(
        indicatorX,
        indicatorY,
        self.modeIndicatorSize,
        self.modeIndicatorSize * 0.75,
        renderManager.COLORS.ui.background
    )
    
    renderManager:drawRect(
        indicatorX,
        indicatorY,
        self.modeIndicatorSize,
        self.modeIndicatorSize * 0.75,
        renderManager.COLORS.ui.border,
        "line"
    )
    
    -- Draw mode indicators
    local fontSize = love.graphics.getFont():getHeight()
    local textY = indicatorY + (self.modeIndicatorSize * 0.75 - fontSize) / 2
    
    -- Safely check tetris mode
    local inTetrisMode = false
    if tetrisManager.isInTetrisMode then
        inTetrisMode = tetrisManager:isInTetrisMode()
    end
    
    -- Navigation mode indicator
    love.graphics.setColor(
        inTetrisMode and 
        renderManager.COLORS.ui.modeInactive or 
        renderManager.COLORS.ui.modeActive
    )
    love.graphics.print(
        "N",
        indicatorX + self.modeIndicatorSize * 0.25,
        textY
    )
    
    -- Tetris mode indicator
    love.graphics.setColor(
        inTetrisMode and 
        renderManager.COLORS.ui.modeActive or 
        renderManager.COLORS.ui.modeInactive
    )
    love.graphics.print(
        "T",
        indicatorX + self.modeIndicatorSize * 0.6,
        textY
    )
    
    -- Draw session counter if available
    if tetrisManager.sessionCount then
        local counterY = indicatorY + self.modeIndicatorSize * 0.75 + self.screenPadding
        renderManager:drawRect(
            indicatorX,
            counterY,
            self.modeIndicatorSize,
            self.modeIndicatorSize * 0.5,
            renderManager.COLORS.ui.background
        )
        
        renderManager:drawRect(
            indicatorX,
            counterY,
            self.modeIndicatorSize,
            self.modeIndicatorSize * 0.5,
            renderManager.COLORS.ui.border,
            "line"
        )
        
        love.graphics.setColor(renderManager.COLORS.ui.counter)
        local counterText = string.format("%d/10", tetrisManager.sessionCount)
        love.graphics.print(
            counterText,
            indicatorX + (self.modeIndicatorSize - love.graphics.getFont():getWidth(counterText)) / 2,
            counterY + (self.modeIndicatorSize * 0.5 - fontSize) / 2
        )
    end
end

function UIManager:drawMessageBox(title, message, buttonText, isButtonHovered)
    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, self.windowWidth, self.windowHeight)
    
    -- Calculate message box dimensions
    local font = love.graphics.getFont()
    local messageLines = {}
    for line in message:gmatch("([^\n]*)\n?") do
        table.insert(messageLines, line)
    end
    
    -- Calculate required width for text
    local maxTextWidth = 0
    for _, line in ipairs(messageLines) do
        maxTextWidth = math.max(maxTextWidth, font:getWidth(line))
    end
    maxTextWidth = math.max(maxTextWidth, font:getWidth(title))
    
    -- Ensure minimum box width while allowing for larger text
    local boxWidth = math.max(self.MESSAGE_BOX_WIDTH, maxTextWidth + self.MESSAGE_PADDING * 3)
    
    -- Calculate box height based on content
    local lineHeight = font:getHeight() * 1.2
    local messageHeight = lineHeight * #messageLines
    local boxHeight = self.MESSAGE_PADDING * 4 +
                     lineHeight +
                     messageHeight +
                     self.MESSAGE_BUTTON_HEIGHT
    
    -- Calculate positions
    local boxX = (self.windowWidth - boxWidth) / 2
    local boxY = (self.windowHeight - boxHeight) / 2
    
    -- Draw message box background
    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle('fill', 
        boxX, boxY, 
        boxWidth, 
        boxHeight
    )
    
    -- Draw border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle('line',
        boxX, boxY,
        boxWidth,
        boxHeight
    )
    
    -- Draw title
    love.graphics.setColor(0.9, 0.9, 0.9)
    local titleX = boxX + (boxWidth - font:getWidth(title)) / 2
    local titleY = boxY + self.MESSAGE_PADDING
    love.graphics.print(title, titleX, titleY)
    
    -- Draw message text
    local messageY = titleY + lineHeight + self.MESSAGE_PADDING
    for _, line in ipairs(messageLines) do
        local lineX = boxX + (boxWidth - font:getWidth(line)) / 2
        love.graphics.print(line, lineX, messageY)
        messageY = messageY + lineHeight
    end
    
    -- Draw button
    local buttonWidth = self.MESSAGE_BUTTON_WIDTH
    local buttonX = boxX + (boxWidth - buttonWidth) / 2
    local buttonY = boxY + boxHeight - self.MESSAGE_BUTTON_HEIGHT - self.MESSAGE_PADDING
    
    if isButtonHovered then
        love.graphics.setColor(0.3, 0.6, 0.3)
    else
        love.graphics.setColor(0.15, 0.15, 0.2)
    end
    
    love.graphics.rectangle('fill',
        buttonX, buttonY,
        buttonWidth,
        self.MESSAGE_BUTTON_HEIGHT
    )
    
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle('line',
        buttonX, buttonY,
        buttonWidth,
        self.MESSAGE_BUTTON_HEIGHT
    )
    
    -- Draw button text
    love.graphics.setColor(0.9, 0.9, 0.9)
    local buttonTextX = buttonX + (buttonWidth - font:getWidth(buttonText)) / 2
    local buttonTextY = buttonY + (self.MESSAGE_BUTTON_HEIGHT - font:getHeight()) / 2
    love.graphics.print(buttonText, buttonTextX, buttonTextY)
end

return UIManager