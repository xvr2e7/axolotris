local GridManager = {}

function GridManager:new(width, height)
    local manager = {
        width = width,
        height = height,
        grid = {},
        selectedBlocks = {},
        originalBlockColor = {0.6, 0.4, 0.4},
        highlightedColor = {0.8, 0.6, 0.6},
        selectedColor = {0.5, 0.5, 0.5},
        barrierColor = {0.3, 0.3, 0.3},
        weakBarrierColor = {0.4, 0.4, 0.4},
        safeBlockColor = {0.5, 0.8, 0.5},
        disabledColor = {0.9, 0.9, 0.9}
    }
    setmetatable(manager, { __index = self })
    self:initializeGrid(manager)
    return manager
end

function GridManager:initializeGrid(manager)
    -- Initialize empty grid
    for y = 1, manager.height do
        manager.grid[y] = {}
        for x = 1, manager.width do
            manager.grid[y][x] = {
                type = "normal",
                selected = false,
                highlighted = false,
                color = manager.originalBlockColor,
                barrier = nil,
                disabled = false,
                safe = false,
                targetColor = nil,
                transitionStart = 0,
                transitionDuration = 0.5
            }
        end
    end
    
    -- Place barriers and safe blocks between buffer zone and bottom (rows 2-13)
    self:placeBarriersAndSafeBlocks(manager)
end

function GridManager:findConnectedBlocks(startX, startY)
    local connected = {}
    local visited = {}
    
    local function visit(x, y)
        local key = x .. "," .. y
        if visited[key] then return end
        
        local block = self.grid[y][x]
        if not block or not block.selected then return end
        
        visited[key] = true
        table.insert(connected, {x = x, y = y})
        
        -- Check all adjacent positions
        local adjacentPositions = {
            {x = x+1, y = y},
            {x = x-1, y = y},
            {x = x, y = y+1},
            {x = x, y = y-1}
        }
        
        for _, pos in ipairs(adjacentPositions) do
            if pos.x >= 1 and pos.x <= self.width and 
               pos.y >= 1 and pos.y <= self.height then
                visit(pos.x, pos.y)
            end
        end
    end
    
    visit(startX, startY)
    return connected
end

function GridManager:getConnectedGroups()
    local visited = {}
    local groups = {}
    
    for y = 1, self.height do
        for x = 1, self.width do
            local key = x .. "," .. y
            if not visited[key] and self.grid[y][x].selected then
                local connected = self:findConnectedBlocks(x, y)
                if #connected > 0 then
                    table.insert(groups, connected)
                    -- Mark all blocks in this group as visited
                    for _, block in ipairs(connected) do
                        visited[block.x .. "," .. block.y] = true
                    end
                end
            end
        end
    end
    
    return groups
end

function GridManager:selectBlock(x, y)
    if self.grid[y] and self.grid[y][x] then
        local block = self.grid[y][x]
        -- Only allow selection if block is highlighted and not disabled
        if block.highlighted and (not block.disabled or block.safe) then
            block.selected = not block.selected
            block.color = block.selected and self.selectedColor or 
                         (block.safe and self.safeBlockColor or
                         (block.disabled and self.disabledColor or
                         self.originalBlockColor))
            
            if block.selected then
                table.insert(self.selectedBlocks, {x = x, y = y})
            else
                for i = #self.selectedBlocks, 1, -1 do
                    local selected = self.selectedBlocks[i]
                    if selected.x == x and selected.y == y then
                        table.remove(self.selectedBlocks, i)
                        break
                    end
                end
            end
            return true
        end
    end
    return false
end

function GridManager:getLargestConnectedGroup()
    local groups = self:getConnectedGroups()
    if #groups == 0 then return {} end
    
    local largestGroup = groups[1]
    for _, group in ipairs(groups) do
        if #group > #largestGroup then
            largestGroup = group
        end
    end
    
    return largestGroup
end

function GridManager:clearBlockSelection(blocks)
    -- Create a lookup table for quick checking
    local blockLookup = {}
    for _, block in ipairs(blocks) do
        local key = block.x .. "," .. block.y
        blockLookup[key] = true
    end
    
    -- Remove only the specified blocks from selection
    local newSelectedBlocks = {}
    for _, selected in ipairs(self.selectedBlocks) do
        local key = selected.x .. "," .. selected.y
        if not blockLookup[key] then
            table.insert(newSelectedBlocks, selected)
        else
            -- Clear selection state for this block
            self.grid[selected.y][selected.x].selected = false
        end
    end
    
    self.selectedBlocks = newSelectedBlocks
end

function GridManager:startBlockTransition(blocks, color)
    local currentTime = love.timer.getTime()
    for _, pos in ipairs(blocks) do
        local block = self.grid[pos.y][pos.x]
        block.color = block.color or self.originalBlockColor
        block.targetColor = color
        block.transitionStart = currentTime
        block.transitionDuration = 0.5
        
        -- Store highlight state
        block.previousHighlightState = block.highlighted
    end
end

function GridManager:revertBlocks(blocks)
    -- Store block states before transition
    local blockStates = {}
    for _, pos in ipairs(blocks) do
        local block = self.grid[pos.y][pos.x]
        blockStates[pos.x .. "," .. pos.y] = {
            highlighted = block.highlighted,
            type = block.type
        }
    end
    
    -- Revert blocks to original state
    for _, pos in ipairs(blocks) do
        local key = pos.x .. "," .. pos.y
        local block = self.grid[pos.y][pos.x]
        
        -- Reset block to original state while preserving highlight
        block.selected = false
        block.color = self.originalBlockColor
        block.targetColor = nil
        block.type = blockStates[key].type
        block.highlighted = blockStates[key].highlighted
        
        -- Restore highlight state if it was previously stored
        if block.previousHighlightState ~= nil then
            block.highlighted = block.previousHighlightState
            block.previousHighlightState = nil
        end
    end
end

function GridManager:placeBarriersAndSafeBlocks(manager)
    local function isValidPosition(x, y, axolotlX)
        -- Check if position is within valid range (rows 2-13)
        if y < 2 or y > 13 then return false end
        -- Avoid axolotl's spawn column
        if x == axolotlX then return false end
        -- Check if position is already occupied
        if manager.grid[y][x].barrier or manager.grid[y][x].safe then
            return false
        end
        return true
    end

    -- Axolotl spawns at middle of bottom row
    local axolotlX = math.floor(manager.width / 2)

    -- Place 10 barriers
    local barrierTypes = { "horizontal", "vertical", "cross" }
    local barrierStrengths = { "primary", "weak" }
    local barriersPlaced = 0

    while barriersPlaced < 10 do
        local x = love.math.random(1, manager.width)
        local y = love.math.random(2, 13)

        if isValidPosition(x, y, axolotlX) then
            local barrierType = barrierTypes[love.math.random(1, #barrierTypes)]
            local strength = barrierStrengths[love.math.random(1, #barrierStrengths)]

            manager.grid[y][x].barrier = {
                type = barrierType,
                strength = strength
            }
            manager.grid[y][x].color = strength == "primary" and manager.barrierColor or manager.weakBarrierColor

            -- Apply barrier effects (whitening)
            if barrierType == "horizontal" or barrierType == "cross" then
                for ix = 1, manager.width do
                    if ix ~= x and not manager.grid[y][ix].safe then
                        manager.grid[y][ix].disabled = true
                        manager.grid[y][ix].color = manager.disabledColor
                    end
                end
            end

            if barrierType == "vertical" or barrierType == "cross" then
                for iy = 1, manager.height do
                    if iy ~= y and not manager.grid[iy][x].safe then
                        manager.grid[iy][x].disabled = true
                        manager.grid[iy][x].color = manager.disabledColor
                    end
                end
            end

            barriersPlaced = barriersPlaced + 1
        end
    end

    -- Place 10 safe blocks
    local safeBlocksPlaced = 0
    while safeBlocksPlaced < 10 do
        local x = love.math.random(1, manager.width)
        local y = love.math.random(2, 13)

        if isValidPosition(x, y, axolotlX) then
            manager.grid[y][x].safe = true
            manager.grid[y][x].color = manager.safeBlockColor
            safeBlocksPlaced = safeBlocksPlaced + 1
        end
    end
end

return GridManager