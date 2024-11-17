local GridManager = {}

function GridManager:new(width, height)
    local manager = {
        width = width,
        height = height,
        grid = {},
        selectedBlocks = {},
        originalBlockColor = {0.6, 0.4, 0.4},
        highlightedColor = {0.8, 0.6, 0.6},
        selectedColor = {0.5, 0.5, 0.5}
    }
    setmetatable(manager, { __index = self })
    self:initializeGrid(manager)
    return manager
end

function GridManager:initializeGrid(manager)
    for y = 1, manager.height do
        manager.grid[y] = {}
        for x = 1, manager.width do
            manager.grid[y][x] = {
                type = "trap",
                selected = false,
                highlighted = false,
                color = manager.originalBlockColor,
                targetColor = nil,
                transitionStart = 0,
                transitionDuration = 0.5
            }
        end
    end
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
        -- Only allow selection/deselection if block is highlighted
        if block.highlighted then
            block.selected = not block.selected
            -- Update block color based on selection state
            block.color = block.selected and self.selectedColor or self.originalBlockColor
            
            if block.selected then
                table.insert(self.selectedBlocks, {x = x, y = y})
            else
                -- Remove from selected blocks
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

return GridManager