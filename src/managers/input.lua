local Timer = require('src.timer')

local InputManager = {}

function InputManager:new(moveDelay, gridSize)
    local manager = {
        lastMove = 0,
        moveDelay = moveDelay or 0.15,
        gridSize = gridSize or 32,
        game = nil
    }
    setmetatable(manager, { __index = self })
    return manager
end

function InputManager:init(game)
    if game then 
        self.game = game
    end
end

function InputManager:handleMouseClick(x, y, game)
    if not game then return end
    
    -- Check if in tetris mode - if so, ignore mouse clicks
    local inTetrisMode = false
    if game.tetris and game.tetris.isInTetrisMode then
        inTetrisMode = game.tetris:isInTetrisMode()
    end
    if inTetrisMode then return end
    
    -- First check if it's a UI click (refresh button)
    if game.ui and game.ui:isRefreshButtonClicked(x, y) then
        game:refresh()
        return
    end
    
    -- Convert to grid coordinates
    local gridX = math.floor(x / self.gridSize) + 1
    local gridY = math.floor(y / self.gridSize) + 1
    
    -- Validate position and grid access
    if not game:isValidPosition(gridX, gridY) then return end
    if not game.grid or not game.grid.grid then return end
    
    local block = game.grid.grid[gridY][gridX]
    if not block then return end
    
    if block.highlighted then
        -- Toggle block selection
        block.selected = not block.selected
        
        -- Safely try to get selected blocks
        local selected = {}
        if game.grid.getSelectedBlocks then
            selected = game.grid:getSelectedBlocks()
        else
            -- Fallback to getLargestConnectedGroup if available
            if game.grid.getLargestConnectedGroup then
                selected = game.grid:getLargestConnectedGroup()
            end
        end
        
        -- Check for tetrimino combinations
        if #selected >= 4 then
            -- Check if findCombinations exists
            local combinations = {}
            if game.findCombinations then
                combinations = game:findCombinations(selected, 4)
            else
                -- If no combination function, just try the current selection
                combinations = {selected}
            end
            
            for _, combo in ipairs(combinations) do
                if game.tetrimino and game.tetrimino.detectTetrimino then
                    local tetriminoType = game.tetrimino:detectTetrimino(combo)
                    if tetriminoType then
                        -- Found a valid tetrimino!
                        if game.startTetriminoTransition then
                            game:startTetriminoTransition(combo, tetriminoType)
                        else
                            -- Fallback to handleMatchedTetrimino if available
                            if game.tetrimino.handleMatchedTetrimino then
                                game.tetrimino:handleMatchedTetrimino(tetriminoType, combo, game.grid)
                            end
                        end
                        break  -- Only handle one tetrimino at a time
                    end
                end
            end
        end
    end
end

function InputManager:handleKeyPressed(key, game)
    if not game or not game.tetris then return end
    
    if key == "tab" then
        game.tetris:tryEnterTetrisMode()
        return
    end
    
    -- Safely check for tetris mode
    local inTetrisMode = false
    if game.tetris.isInTetrisMode then
        inTetrisMode = game.tetris:isInTetrisMode()
    end
    
    if inTetrisMode then
        -- Handle Tetris mode controls
        if key == "w" then
            game.tetris:hardDrop()
        elseif key == "r" then
            game.tetris:rotateActivePiece()
        end
    else
        -- Handle Navigation mode controls
        if key == "r" then
            game:rotateAxolotl()
        end
    end
end

function InputManager:update(dt, game)
    if not game then return end
    
    self.lastMove = self.lastMove + dt
    
    -- Update timers
    Timer.update(dt)
    
    -- Safely check for tetris mode
    local inTetrisMode = false
    if game.tetris and game.tetris.isInTetrisMode then
        inTetrisMode = game.tetris:isInTetrisMode()
    end
    
    if inTetrisMode then
        -- Update Tetris game state
        if game.tetris.update then
            game.tetris:update(dt)
        end
    else
        -- Handle Navigation mode movement
        if self.lastMove >= self.moveDelay then
            if love.keyboard.isDown('w') then
                game:moveAxolotl(0, -1)
                self.lastMove = 0
            elseif love.keyboard.isDown('s') then
                game:moveAxolotl(0, 1)
                self.lastMove = 0
            elseif love.keyboard.isDown('a') then
                game:moveAxolotl(-1, 0)
                self.lastMove = 0
            elseif love.keyboard.isDown('d') then
                game:moveAxolotl(1, 0)
                self.lastMove = 0
            end
        end
    end
end

return InputManager