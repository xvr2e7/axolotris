local UIManager = {
    SIDEBAR_OFFSET = 32,
    SIDEBAR_WIDTH = 64,
    ITEM_SIZE = 48,
    ITEM_PADDING = 8,
    BADGE_SIZE = 20,
    PREVIEW_SCALE = 0.8,
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
    -- Position sidebar at left edge with small padding
    local sidebarX = 16
    local sidebarY = (love.graphics.getHeight() - (self.gridHeight * self.gridSize)) / 2
    
    -- Draw sidebar background
    renderManager:drawRect(
        sidebarX, 
        sidebarY,
        self.SIDEBAR_WIDTH,
        self.gridHeight * self.gridSize,
        {0.1, 0.1, 0.15, 0.9}
    )
    
    -- Draw sidebar border
    renderManager:drawRect(
        sidebarX,
        sidebarY,
        self.SIDEBAR_WIDTH,
        self.gridHeight * self.gridSize,
        {0.2, 0.2, 0.25},
        "line"
    )
    
    -- Draw tetrimino icons and counts
    local itemX = sidebarX + (self.SIDEBAR_WIDTH - self.ITEM_SIZE) / 2
    local itemY = sidebarY + self.ITEM_PADDING
    
    for type, pattern in pairs(tetriminoManager.TETRIMINOES) do
        -- Draw icon background
        renderManager:drawRect(
            itemX,
            itemY,
            self.ITEM_SIZE,
            self.ITEM_SIZE,
            {0.15, 0.15, 0.2, 0.5},
            "fill"
        )
        
        -- Draw tetrimino preview
        self:drawTetriminoPreview(
            type,
            pattern,
            itemX,
            itemY,
            tetriminoManager,
            renderManager
        )
        
        -- Draw count badge
        local count = tetriminoManager.tetriminoCounts[type] or 0
        self:drawTetriminoCount(
            count,
            itemX + self.ITEM_SIZE - self.BADGE_SIZE/2,
            itemY - self.BADGE_SIZE/2,
            renderManager
        )
        
        itemY = itemY + self.ITEM_SIZE + self.ITEM_PADDING
    end
end

function UIManager:drawTetriminoPreview(type, pattern, x, y, tetriminoManager, renderManager)
    -- Calculate pattern bounds
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    
    for _, pos in ipairs(pattern[1]) do
        minX = math.min(minX, pos[1])
        maxX = math.max(maxX, pos[1])
        minY = math.min(minY, pos[2])
        maxY = math.max(maxY, pos[2])
    end
    
    -- Calculate scale to fit in icon
    local patternWidth = (maxX - minX + 1)
    local patternHeight = (maxY - minY + 1)
    local scale = math.min(
        (self.ITEM_SIZE * self.PREVIEW_SCALE) / (patternWidth * self.gridSize),
        (self.ITEM_SIZE * self.PREVIEW_SCALE) / (patternHeight * self.gridSize)
    )
    
    -- Center the pattern in the icon
    local centerX = x + self.ITEM_SIZE/2
    local centerY = y + self.ITEM_SIZE/2
    
    -- Draw each block of the tetrimino
    for _, pos in ipairs(pattern[1]) do
        local blockX = centerX + (pos[1] - (maxX + minX)/2) * self.gridSize * scale
        local blockY = centerY + (pos[2] - (maxY + minY)/2) * self.gridSize * scale
        local blockSize = self.gridSize * scale
        
        renderManager:drawRect(
            blockX,
            blockY,
            blockSize - 1,
            blockSize - 1,
            tetriminoManager.COLORS[type]
        )
    end
end

function UIManager:drawTetriminoCount(count, x, y, renderManager)
    -- Draw badge circle
    renderManager:drawRect(
        x, y,
        self.BADGE_SIZE,
        self.BADGE_SIZE,
        {0.3, 0.3, 0.35, 0.9},
        "fill"
    )
    
    -- Draw count text
    local font = love.graphics.getFont()
    local text = tostring(count)
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    
    renderManager:drawText(
        text,
        x + (self.BADGE_SIZE - textWidth)/2,
        y + (self.BADGE_SIZE - textHeight)/2,
        {0.9, 0.9, 0.9},
        1
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