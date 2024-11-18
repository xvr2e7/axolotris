local Timer = require('src.timer')

local TetriminoManager = {
    TETRIMINOES = {
        I = {{{0,0}, {0,1}, {0,2}, {0,3}}},
        J = {{{0,0}, {0,1}, {0,2}, {-1,2}}},
        L = {{{0,0}, {0,1}, {0,2}, {1,2}}},
        O = {{{0,0}, {1,0}, {0,1}, {1,1}}},
        S = {{{0,0}, {1,0}, {-1,1}, {0,1}}},
        T = {{{0,0}, {-1,1}, {0,1}, {1,1}}},
        Z = {{{-1,0}, {0,0}, {0,1}, {1,1}}}
    },
    
    COLORS = {
        I = {0.0, 0.8, 0.8}, -- Cyan
        J = {0.0, 0.0, 0.8}, -- Blue
        L = {0.8, 0.4, 0.0}, -- Orange
        O = {0.8, 0.8, 0.0}, -- Yellow
        S = {0.0, 0.8, 0.0}, -- Green
        T = {0.8, 0.0, 0.8}, -- Purple
        Z = {0.8, 0.0, 0.0}  -- Red
    }
}

function TetriminoManager:new()
    local manager = {
        tetriminoCounts = {}
    }
    setmetatable(manager, {__index = self})
    return manager
end

function TetriminoManager:rotatePattern(pattern)
    print("Rotating pattern:")
    for _, p in ipairs(pattern) do
        print(string.format("  Before: (%d, %d)", p[1], p[2]))
    end
    
    local rotated = {}
    for _, p in ipairs(pattern) do
        -- Rotate 90 degrees clockwise: (x,y) -> (-y,x)
        table.insert(rotated, {-p[2], p[1]})
    end
    
    print("After rotation:")
    for _, p in ipairs(rotated) do
        print(string.format("  After: (%d, %d)", p[1], p[2]))
    end
    
    return rotated
end

function TetriminoManager:normalizePattern(pattern)
    print("Normalizing pattern:")
    for _, p in ipairs(pattern) do
        print(string.format("  Before: (%d, %d)", p[1], p[2]))
    end
    
    -- Find minimum x and y coordinates
    local minX, minY = math.huge, math.huge
    for _, p in ipairs(pattern) do
        minX = math.min(minX, p[1])
        minY = math.min(minY, p[2])
    end
    
    -- Translate pattern so minimum coordinates are at origin
    local normalized = {}
    for _, p in ipairs(pattern) do
        table.insert(normalized, {p[1] - minX, p[2] - minY})
    end
    
    print("After normalization:")
    for _, p in ipairs(normalized) do
        print(string.format("  After: (%d, %d)", p[1], p[2]))
    end
    
    return normalized
end

function TetriminoManager:patternsMatch(pattern1, pattern2)
    print("\nComparing patterns:")
    print("Pattern 1:")
    for _, p in ipairs(pattern1) do
        print(string.format("  (%d, %d)", p[1], p[2]))
    end
    print("Pattern 2:")
    for _, p in ipairs(pattern2) do
        print(string.format("  (%d, %d)", p[1], p[2]))
    end

    if #pattern1 ~= #pattern2 then 
        print("Patterns have different lengths")
        return false 
    end

    -- Normalize both patterns
    local norm1 = self:normalizePattern(pattern1)
    local norm2 = self:normalizePattern(pattern2)

    -- Sort both patterns
    local function sortCoords(a, b)
        if a[1] == b[1] then
            return a[2] < b[2]
        end
        return a[1] < b[1]
    end
    
    table.sort(norm1, sortCoords)
    table.sort(norm2, sortCoords)

    -- Compare sorted patterns
    for i = 1, #norm1 do
        if norm1[i][1] ~= norm2[i][1] or norm1[i][2] ~= norm2[i][2] then
            print(string.format("Mismatch at position %d: (%d,%d) vs (%d,%d)", 
                i, norm1[i][1], norm1[i][2], norm2[i][1], norm2[i][2]))
            return false
        end
    end

    print("Patterns match!")
    return true
end

function TetriminoManager:detectTetrimino(blocks)
    print("\nDetecting tetrimino from " .. #blocks .. " blocks")
    if #blocks ~= 4 then 
        print("Wrong number of blocks")
        return nil 
    end
    
    -- Convert blocks to relative coordinates
    local pattern = {}
    local baseX = blocks[1].x
    local baseY = blocks[1].y
    
    for _, block in ipairs(blocks) do
        table.insert(pattern, {
            block.x - baseX,
            block.y - baseY
        })
    end

    print("\nTesting input pattern:")
    for _, p in ipairs(pattern) do
        print(string.format("  (%d, %d)", p[1], p[2]))
    end
    
    -- Try each tetrimino type
    for type, basePattern in pairs(self.TETRIMINOES) do
        print("\nTesting against " .. type .. " tetrimino")
        local testPattern = basePattern[1] -- Get first rotation
        
        -- Try all 4 rotations
        for i = 1, 4 do
            print("\nRotation " .. i)
            
            if self:patternsMatch(pattern, testPattern) then
                print("Match found: " .. type)
                -- Increment count
                self.tetriminoCounts[type] = (self.tetriminoCounts[type] or 0) + 1
                return type
            end
            
            testPattern = self:rotatePattern(testPattern)
        end
    end
    
    print("No match found")
    return nil
end

function TetriminoManager:handleMatchedTetrimino(type, blocks, gridManager)
    if not type or not blocks or not gridManager then return end
    
    -- Get the classic Tetris color for this piece type
    local tetriminoColor = self.COLORS[type]
    if not tetriminoColor then return end
    
    -- Store colors and states for reversion
    for _, pos in ipairs(blocks) do
        local block = gridManager.grid[pos.y][pos.x]
        block.previousColor = block.color
        -- If block has a tetris color, store it for later reversion
        if block.tetrisColor then
            block.revertToTetrisColor = block.tetrisColor
        end
        block.wasHighlighted = block.highlighted
        block.color = tetriminoColor
    end
    
    -- Schedule reversion after delay
    Timer.after(0.2, function()
        if gridManager and gridManager.revertBlocks then
            for _, pos in ipairs(blocks) do
                local block = gridManager.grid[pos.y][pos.x]
                -- Revert to tetris color if it exists, otherwise normal state
                if block.revertToTetrisColor then
                    block.color = block.revertToTetrisColor
                    block.revertToTetrisColor = nil
                else
                    block.color = block.wasHighlighted and 
                        gridManager.colors.highlighted or 
                        gridManager.colors.original
                end
            end
            gridManager:clearBlockSelection(blocks)
        end
    end)
end

return TetriminoManager