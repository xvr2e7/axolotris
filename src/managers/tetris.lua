local TetrisManager = {
    MODES = {
        NAVIGATION = "navigation", 
        TETRIS = "tetris"
    },
    
    -- Tetris game constants
    DROP_SPEED = 1.0,          -- Seconds per drop
    SOFT_DROP_MULTIPLIER = 4,  -- Speed multiplier when holding down
    MOVE_DELAY = 0.05         -- Delay between moves
}

function TetrisManager:new()
    local manager = {
        currentMode = self.MODES.NAVIGATION,
        sessionCount = 0,
        game = nil,
        
        -- Tetris game state
        activePiece = nil,     -- Current falling piece
        dropTimer = 0,         -- Time until next drop
        moveTimer = 0,         -- Time until next move
        pieceQueue = {},       -- Randomized queue of available pieces
        isDropping = false,    -- Soft drop flag
        ghostPiece = nil       -- Ghost piece position
    }
    setmetatable(manager, { __index = self })
    return manager
end

function TetrisManager:init(game)
    self.game = game
end

-- Core tetris mode entry
function TetrisManager:hasTetriminos()
    if not self.game or not self.game.tetrimino or not self.game.tetrimino.tetriminoCounts then 
        return false 
    end
    
    -- Check if player has any tetriminos available
    for _, count in pairs(self.game.tetrimino.tetriminoCounts) do
        if count and count > 0 then
            return true
        end
    end
    return false
end

function TetrisManager:isInTetrisMode()
    return self.currentMode == self.MODES.TETRIS
end

function TetrisManager:canEnterTetrisMode()
    return self.currentMode == self.MODES.NAVIGATION and self:hasTetriminos()
end

function TetrisManager:tryEnterTetrisMode()
    -- Check if we can enter tetris mode
    if not self:canEnterTetrisMode() then
        return false
    end
    
    -- Increment session counter
    self.sessionCount = self.sessionCount + 1
    
    -- Check if trying to start 11th session
    if self.sessionCount > 10 then
        self.sessionCount = self.sessionCount - 1
        if self.game and self.game.handleLoss then
            self.game:handleLoss("no_more_sessions")
        end
        return false
    end
    
    self.currentMode = self.MODES.TETRIS
    
    -- Create randomized piece queue from available tetriminoes
    self.pieceQueue = {}
    for type, count in pairs(self.game.tetrimino.tetriminoCounts) do
        for i = 1, count do
            table.insert(self.pieceQueue, type)
        end
    end
    
    -- Randomize queue order
    for i = #self.pieceQueue, 2, -1 do
        local j = love.math.random(i)
        self.pieceQueue[i], self.pieceQueue[j] = self.pieceQueue[j], self.pieceQueue[i]
    end
    
    -- Clear tetrimino counts
    for type, _ in pairs(self.game.tetrimino.tetriminoCounts) do
        self.game.tetrimino.tetriminoCounts[type] = 0
    end
    
    -- Spawn first piece
    self:spawnNextPiece()
    
    return true
end

-- Piece spawning
function TetrisManager:spawnNextPiece()
    if #self.pieceQueue == 0 then
        if not self.activePiece then
            self:exitTetrisMode()
        end
        return
    end
    
    -- Get next piece type
    local pieceType = table.remove(self.pieceQueue, 1)
    
    -- Create new active piece
    self.activePiece = {
        type = pieceType,
        pattern = self.game.tetrimino.TETRIMINOES[pieceType][1],
        color = self.game.tetrimino.COLORS[pieceType],
        x = math.floor(self.game.GRID_WIDTH / 2),
        y = 1,
        rotation = 0
    }
    
    -- Update ghost piece
    self:updateGhostPiece()
    
    -- Check for immediate collision (game over condition)
    if self:checkCollision(self.activePiece) then
        -- Signal game over condition rather than silently exiting
        if self.game and self.game.handleLoss then
            self.game:handleLoss("stack_too_high")
        end
    end
end

-- Collision detection
function TetrisManager:checkCollision(piece)
    if not piece or not self.game then return false end
    
    for _, block in ipairs(piece.pattern) do
        local testX = piece.x + block[1]
        local testY = piece.y + block[2]
        
        -- Check bounds
        if testX < 1 or testX > self.game.GRID_WIDTH or 
           testY < 1 or testY > self.game.GRID_HEIGHT then
            return true
        end
        
        local gridBlock = self.game.grid.grid[testY][testX]
        
        -- Check for:
        -- 1. Barrier blocks
        -- 2. Safe blocks
        -- 3. Previously locked tetrimino blocks
        -- 4. Axolotl position
        if gridBlock.barrier or
           gridBlock.safe or 
           gridBlock.locked or
           (testX == self.game.axolotl.x and testY == self.game.axolotl.y) then
            return true
        end
    end
    
    return false
end

-- Movement and rotation
function TetrisManager:moveActivePiece(dx, dy)
    if not self.activePiece then return false end
    
    local testPiece = {
        type = self.activePiece.type,
        pattern = self.activePiece.pattern,
        color = self.activePiece.color,
        x = self.activePiece.x + dx,
        y = self.activePiece.y + dy,
        rotation = self.activePiece.rotation
    }
    
    if not self:checkCollision(testPiece) then
        self.activePiece = testPiece
        self:updateGhostPiece()
        return true
    end
    
    return false
end

function TetrisManager:rotateActivePiece()
    if not self.activePiece then return false end
    
    local rotated = self.game.tetrimino:rotatePattern(self.activePiece.pattern)
    
    local testPiece = {
        type = self.activePiece.type,
        pattern = rotated,
        color = self.activePiece.color,
        x = self.activePiece.x,
        y = self.activePiece.y,
        rotation = (self.activePiece.rotation + 90) % 360
    }
    
    if not self:checkCollision(testPiece) then
        self.activePiece = testPiece
        self:updateGhostPiece()
        return true
    end
    
    return false
end

-- Ghost piece projection
function TetrisManager:updateGhostPiece()
    if not self.activePiece then
        self.ghostPiece = nil
        return
    end
    
    self.ghostPiece = {
        type = self.activePiece.type,
        pattern = self.activePiece.pattern,
        color = self.activePiece.color,
        x = self.activePiece.x,
        y = self.activePiece.y,
        rotation = self.activePiece.rotation
    }
    
    -- Project down until collision
    while not self:checkCollision(self.ghostPiece) do
        self.ghostPiece.y = self.ghostPiece.y + 1
    end
    -- Back up one step
    self.ghostPiece.y = self.ghostPiece.y - 1
end

-- Hard drop
function TetrisManager:hardDrop()
    if not self.activePiece then return end
    
    while self:moveActivePiece(0, 1) do end
    self:lockPiece()
end

-- Main update loop
function TetrisManager:update(dt)
    if not self:isInTetrisMode() or not self.activePiece then return end
    
    -- Update move timer
    self.moveTimer = math.max(0, self.moveTimer - dt)
    
    -- Handle held movement keys
    if self.moveTimer == 0 then
        if love.keyboard.isDown('a') then
            self:moveActivePiece(-1, 0)
            self.moveTimer = self.MOVE_DELAY
        elseif love.keyboard.isDown('d') then
            self:moveActivePiece(1, 0)
            self.moveTimer = self.MOVE_DELAY
        end
    end
    
    -- Update drop timer
    local dropSpeed = self.DROP_SPEED
    if love.keyboard.isDown('s') then
        dropSpeed = dropSpeed / self.SOFT_DROP_MULTIPLIER
    end
    
    self.dropTimer = self.dropTimer + dt
    if self.dropTimer >= dropSpeed then
        self.dropTimer = 0
        if not self:moveActivePiece(0, 1) then
            self:lockPiece()
        end
    end
end

-- Draw functions
function TetrisManager:drawActivePiece(renderManager)
    if not self.activePiece then return end
    
    -- Draw ghost piece first
    if self.ghostPiece then
        for _, block in ipairs(self.ghostPiece.pattern) do
            local x = (self.ghostPiece.x + block[1] - 1) * renderManager.gridSize
            local y = (self.ghostPiece.y + block[2] - 1) * renderManager.gridSize
            
            -- Draw semi-transparent ghost block
            love.graphics.setColor(
                self.ghostPiece.color[1],
                self.ghostPiece.color[2],
                self.ghostPiece.color[3],
                0.3
            )
            love.graphics.rectangle(
                'fill',
                x + 1,
                y + 1,
                renderManager.gridSize - 2,
                renderManager.gridSize - 2
            )
        end
    end
    
    -- Draw active piece
    for _, block in ipairs(self.activePiece.pattern) do
        local x = (self.activePiece.x + block[1] - 1) * renderManager.gridSize
        local y = (self.activePiece.y + block[2] - 1) * renderManager.gridSize
        
        love.graphics.setColor(self.activePiece.color)
        love.graphics.rectangle(
            'fill',
            x + 1,
            y + 1,
            renderManager.gridSize - 2,
            renderManager.gridSize - 2
        )
    end
end

function TetrisManager:checkLineClears()
    local linesToClear = {}
    
    -- Check each row
    for y = 1, self.game.GRID_HEIGHT do
        local complete = true
        -- Check if row is filled (including barriers and safe blocks)
        for x = 1, self.game.GRID_WIDTH do
            local block = self.game.grid.grid[y][x]
            if not (block.locked or block.barrier or block.safe) then
                complete = false
                break
            end
        end
        if complete then
            table.insert(linesToClear, y)
        end
    end
    
    -- Process line clears
    if #linesToClear > 0 then
        self:clearLines(linesToClear)
    end
end

function TetrisManager:clearLines(lines)
    local isDoubleLineClear = #lines >= 2
    
    -- First handle barriers in the cleared lines
    for _, y in ipairs(lines) do
        for x = 1, self.game.GRID_WIDTH do
            local block = self.game.grid.grid[y][x]
            
            if block.barrier then
                if isDoubleLineClear then
                    -- Double line clear: destroy all barriers
                    self:clearBarrier(x, y)
                else
                    -- Single line clear: behavior depends on barrier strength
                    if block.barrier.strength == "primary" then
                        -- Weaken primary barriers
                        self:weakenBarrier(x, y)
                    else
                        -- Clear weak/weakened barriers
                        self:clearBarrier(x, y)
                    end
                end
            elseif block.locked and not block.safe then
                -- Only clear locked (tetris) blocks that aren't safe
                self:clearBlock(x, y)
            end
        end
    end
    
    -- Then collapse lines
    self:collapseLines(lines)
end

function TetrisManager:clearBlock(x, y)
    local block = self.game.grid.grid[y][x]
    block.locked = false
    block.color = self.game.grid.colors.original
    block.tetrisColor = nil
end

function TetrisManager:clearBarrier(x, y)
    local block = self.game.grid.grid[y][x]
    local barrierType = block.barrier.type
    
    -- Clear barrier block itself
    block.barrier = nil
    block.color = self.game.grid.colors.original
    
    -- Clear barrier field projections
    if barrierType == "horizontal" or barrierType == "cross" then
        for ix = 1, self.game.GRID_WIDTH do
            if ix ~= x then
                local projBlock = self.game.grid.grid[y][ix]
                if not projBlock.safe then
                    projBlock.disabled = false
                    if not projBlock.tetrisColor then
                        projBlock.color = self.game.grid.colors.original
                    end
                end
            end
        end
    end
    
    if barrierType == "vertical" or barrierType == "cross" then
        for iy = 1, self.game.GRID_HEIGHT do
            if iy ~= y then
                local projBlock = self.game.grid.grid[iy][x]
                if not projBlock.safe then
                    projBlock.disabled = false
                    if not projBlock.tetrisColor then
                        projBlock.color = self.game.grid.colors.original
                    end
                end
            end
        end
    end
end

function TetrisManager:weakenBarrier(x, y)
    local block = self.game.grid.grid[y][x]
    
    -- Convert to weakened barrier
    block.barrier.strength = "weak"
    block.color = self.game.grid.colors.weakBarrier
end

function TetrisManager:collapseLines(clearedLines)
    -- Sort lines in ascending order
    table.sort(clearedLines)
    
    -- Process one cleared line at a time
    for _, clearedY in ipairs(clearedLines) do
        -- Move blocks down, starting from the cleared line and going upward
        for y = clearedY, 2, -1 do
            for x = 1, self.game.GRID_WIDTH do
                local block = self.game.grid.grid[y][x]
                local blockAbove = self.game.grid.grid[y-1][x]
                
                -- Only move blocks that should be moved (locked tetris blocks)
                if not block.barrier and not block.safe then
                    if blockAbove.locked then
                        -- Copy only relevant properties from block above
                        block.locked = true
                        block.color = blockAbove.tetrisColor
                        block.tetrisColor = blockAbove.tetrisColor
                        
                        -- Clear the block above
                        blockAbove.locked = false
                        blockAbove.color = self.game.grid.colors.original
                        blockAbove.tetrisColor = nil
                    else
                        -- If block above isn't locked, just clear this block
                        block.locked = false
                        block.color = self.game.grid.colors.original
                        block.tetrisColor = nil
                    end
                end
            end
        end
    end
end

-- Piece locking
function TetrisManager:lockPiece()
    if not self.activePiece then return end

    -- Lock piece to grid first
    for _, block in ipairs(self.activePiece.pattern) do
        local gridX = self.activePiece.x + block[1]
        local gridY = self.activePiece.y + block[2]

        if gridY >= 1 and gridY <= self.game.GRID_HEIGHT and
           gridX >= 1 and gridX <= self.game.GRID_WIDTH then
            local gridBlock = self.game.grid.grid[gridY][gridX]
            gridBlock.color = self.activePiece.color
            gridBlock.tetrisColor = self.activePiece.color
            gridBlock.locked = true
        end
    end

    -- Clear active and ghost pieces
    self.activePiece = nil
    self.ghostPiece = nil

    -- Check for line clears
    self:checkLineClears()

    -- Check for classic Tetris loss condition - pieces reaching the very top
    local causesLoss = false
    for x = 1, self.game.GRID_WIDTH do
        if self.game.grid.grid[1][x].locked then
            causesLoss = true
            break
        end
    end

    if causesLoss then
        -- Trigger game over
        if self.game.handleLoss then
            self.game:handleLoss()
        end
    else
        -- Spawn next piece only if game isn't over
        self:spawnNextPiece()
    end
end

function TetrisManager:exitTetrisMode()
    if self.currentMode == self.MODES.TETRIS then
        self.currentMode = self.MODES.NAVIGATION
        self.activePiece = nil
        self.ghostPiece = nil
        self.pieceQueue = {}
        self.dropTimer = 0
        self.moveTimer = 0
        
        -- Tell input manager to ignore held keys until they're released
        if self.game and self.game.input then
            self.game.input:setIgnoreHeldKeys(true)
        end
    end
end

return TetrisManager