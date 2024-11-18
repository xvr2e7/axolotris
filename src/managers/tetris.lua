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
    if self:canEnterTetrisMode() then
        self.currentMode = self.MODES.TETRIS
        self.sessionCount = self.sessionCount + 1
        
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
    return false
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
        self:exitTetrisMode()
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
        if gridBlock.barrier or
           gridBlock.safe or 
           gridBlock.locked then
            return true
        end
        
        -- Check collision with axolotl position
        if testX == self.game.axolotl.x and 
           testY == self.game.axolotl.y then
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

-- Piece locking
function TetrisManager:lockPiece()
    if not self.activePiece then return end
    
    for _, block in ipairs(self.activePiece.pattern) do
        local gridX = self.activePiece.x + block[1]
        local gridY = self.activePiece.y + block[2]
        
        if gridY >= 1 and gridY <= self.game.GRID_HEIGHT and
           gridX >= 1 and gridX <= self.game.GRID_WIDTH then
            local gridBlock = self.game.grid.grid[gridY][gridX]
            gridBlock.color = self.activePiece.color
            gridBlock.tetrisColor = self.activePiece.color  -- Store original tetris color
            gridBlock.locked = true
        end
    end
    
    -- Clear active and ghost pieces
    self.activePiece = nil
    self.ghostPiece = nil
    
    -- Spawn next piece
    self:spawnNextPiece()
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

function TetrisManager:exitTetrisMode()
    if self.currentMode == self.MODES.TETRIS then
        self.currentMode = self.MODES.NAVIGATION
        self.activePiece = nil
        self.ghostPiece = nil
        self.pieceQueue = {}
        self.dropTimer = 0
        self.moveTimer = 0
    end
end

return TetrisManager