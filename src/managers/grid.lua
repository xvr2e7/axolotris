local GridManager = {}

function GridManager:new(width, height)
    local manager = {
        width = width,
        height = height,
        grid = {},
        selectedBlocks = {},
        colors = {
            original = {0.6, 0.4, 0.4},
            highlighted = {0.8, 0.6, 0.6},
            selected = {0.5, 0.5, 0.5},
            barrier = {0.3, 0.3, 0.3},
            weakBarrier = {0.4, 0.4, 0.4},
            safeBlock = {0.5, 0.8, 0.5},
            safeBlockSelected = {0.4, 0.7, 0.4},
            disabled = {0.9, 0.9, 0.9, 0.7},
            exit = {0.8, 0.8, 0.4}
        }
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
                color = manager.colors.original,
                barrier = nil,
                disabled = false,
                safe = false,
                showHeart = false,
                isExit = false,
                targetColor = nil,
                transitionStart = 0,
                transitionDuration = 0.5
            }
        end
    end
    
    -- Set up exit in the middle of top row
    local exitX1 = math.floor(manager.width/2)
    local exitX2 = exitX1 + 1
    manager.grid[1][exitX1].isExit = true
    manager.grid[1][exitX2].isExit = true
    manager.grid[1][exitX1].color = manager.colors.exit
    manager.grid[1][exitX2].color = manager.colors.exit
    
    -- Place barriers and safe blocks
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
        -- Only allow selection if block is highlighted and not barrier
        if block.highlighted and not block.barrier then
            block.selected = not block.selected
            
            if block.selected then
                -- Store current color before changing to selected color
                block.previousColor = block.color
                block.color = self.colors.selected
            else
                -- When deselecting, restore the appropriate color
                if block.locked and block.tetrisColor then
                    -- For locked tetris blocks, restore tetris color
                    block.color = block.tetrisColor
                elseif block.highlighted then
                    -- For highlighted blocks, use highlighted state
                    if block.locked and block.tetrisColor then
                        -- Create highlighted version of tetris color
                        block.color = {
                            math.min(1, block.tetrisColor[1] + 0.2),
                            math.min(1, block.tetrisColor[2] + 0.2),
                            math.min(1, block.tetrisColor[3] + 0.2)
                        }
                    else
                        block.color = self.colors.highlighted
                    end
                else
                    -- Otherwise restore original color
                    block.color = block.previousColor or self.colors.original
                end
                block.previousColor = nil
            end
            
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
            -- Clear selection state and restore appropriate color
            local block = self.grid[selected.y][selected.x]
            block.selected = false
            
            -- Restore color based on block state
            if block.locked and block.tetrisColor then
                if block.highlighted then
                    -- Create highlighted version of tetris color
                    block.color = {
                        math.min(1, block.tetrisColor[1] + 0.2),
                        math.min(1, block.tetrisColor[2] + 0.2),
                        math.min(1, block.tetrisColor[3] + 0.2)
                    }
                else
                    block.color = block.tetrisColor
                end
            else
                block.color = block.highlighted and 
                            self.colors.highlighted or 
                            self.colors.original
            end
        end
    end
    
    self.selectedBlocks = newSelectedBlocks
end

function GridManager:startBlockTransition(blocks, targetColor)
    local currentTime = love.timer.getTime()
    for _, pos in ipairs(blocks) do
        local block = self.grid[pos.y][pos.x]
        -- Store the block's original color if not already stored
        block.originalColor = block.color
        block.targetColor = targetColor
        block.transitionStart = currentTime
        block.transitionDuration = 0.2
        
        -- Store selection and highlight state
        block.wasHighlighted = block.highlighted
    end
end

function GridManager:revertBlocks(blocks)
    local currentTime = love.timer.getTime()
    for _, pos in ipairs(blocks) do
        local block = self.grid[pos.y][pos.x]
        -- Start transition back to original color
        block.targetColor = block.originalColor
        block.transitionStart = currentTime
        block.transitionDuration = 0.2
    end
end

function GridManager:placeBarriersAndSafeBlocks(manager)
    local function isInBufferZone(y)
        return y <= 7  -- Buffer zone is top 7 rows
    end
    
    local function isInSpawnProtectedZone(x, y, axolotlX)
        -- Check if position affects the 3x3 spawn area
        local spawnAreaTop = manager.height - 2
        local spawnAreaLeft = axolotlX - 1
        local spawnAreaRight = axolotlX + 1

        -- For horizontal barriers, check row overlap
        if y >= spawnAreaTop and y <= manager.height then
            return true
        end
        
        -- For vertical barriers, check column overlap
        if x >= spawnAreaLeft and x <= spawnAreaRight then
            return true
        end

        return false
    end

    local function isValidPosition(x, y, axolotlX)
        -- Check if position is within valid range
        if isInBufferZone(y) then return false end
        if y == manager.height then return false end
        
        -- Check if position is in spawn protected zone
        if isInSpawnProtectedZone(x, y, axolotlX) then return false end
        
        -- Check if position is already occupied
        if manager.grid[y][x].barrier or 
           manager.grid[y][x].safe or 
           manager.grid[y][x].isExit then
            return false
        end
        
        return true
    end

    -- Axolotl spawns at middle of bottom row
    local axolotlX = math.floor(manager.width / 2)
    
    -- Place 10 barriers
    local barrierTypes = {"horizontal", "vertical", "cross"}
    local barrierStrengths = {"primary", "weak"}
    local barriersPlaced = 0
    
    while barriersPlaced < 10 do
        local x = love.math.random(1, manager.width)
        local y = love.math.random(8, manager.height - 1)
        
        if isValidPosition(x, y, axolotlX) then
            local barrierType = barrierTypes[love.math.random(1, #barrierTypes)]
            local strength = barrierStrengths[love.math.random(1, #barrierStrengths)]
            
            -- Set barrier block
            manager.grid[y][x].barrier = {
                type = barrierType,
                strength = strength
            }
            manager.grid[y][x].color = strength == "primary" and 
                                     manager.colors.barrier or 
                                     manager.colors.weakBarrier
            
            -- Apply barrier field effects
            if barrierType == "horizontal" or barrierType == "cross" then
                for ix = 1, manager.width do
                    if ix ~= x and 
                       not manager.grid[y][ix].safe and 
                       not manager.grid[y][ix].barrier and
                       not isInBufferZone(y) then
                        manager.grid[y][ix].disabled = true
                        manager.grid[y][ix].color = manager.colors.disabled
                    end
                end
            end
            
            if barrierType == "vertical" or barrierType == "cross" then
                for iy = 1, manager.height do
                    if iy ~= y and 
                       not manager.grid[iy][x].safe and
                       not manager.grid[iy][x].barrier and
                       not isInBufferZone(iy) then
                        manager.grid[iy][x].disabled = true
                        manager.grid[iy][x].color = manager.colors.disabled
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
        local y = love.math.random(8, manager.height - 1)
        
        if isValidPosition(x, y, axolotlX) then
            manager.grid[y][x].safe = true
            manager.grid[y][x].showHeart = true
            manager.grid[y][x].color = manager.colors.safeBlock
            safeBlocksPlaced = safeBlocksPlaced + 1
        end
    end
end


return GridManager