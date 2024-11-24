local Timer = require('src.timer')

local InputManager = {}

function InputManager:new(moveDelay, gridSize)
    local manager = {
        lastMove = 0,
        moveDelay = moveDelay or 0.15,
        gridSize = gridSize or 32,
        game = nil,
        ignoreHeldKeys = false  -- New flag to handle mode transitions
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
    if not game then return end
    
    -- Handle escape key for pause menu
    if key == "escape" then
        game:togglePause()
        return
    end
    
    -- Debug hotkey for instant victory testing
    if key == "v" then
        -- Move axolotl to middle of top row (exit position)
        game.axolotl.x = math.floor(game.GRID_WIDTH / 2)
        game.axolotl.y = 1
        -- This will trigger victory check on next update
        return
    end
    
    -- Don't handle other inputs if game is paused
    if game.isPaused then return end
    
    -- Handle tab key for tetris mode switching
    if key == "tab" then
        if game.tetris then
            game.tetris:tryEnterTetrisMode()
        end
        return
    end
    
    -- Safely check for tetris mode
    local inTetrisMode = false
    if game.tetris and game.tetris.isInTetrisMode then
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

function InputManager:setIgnoreHeldKeys(ignore)
    self.ignoreHeldKeys = ignore
    -- Reset lastMove to prevent immediate movement
    if ignore then
        self.lastMove = 0
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
        -- Only process movement if we're not ignoring held keys
        if not self.ignoreHeldKeys and self.lastMove >= self.moveDelay then
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
        
        -- If any movement keys were released, we can start accepting held keys again
        if self.ignoreHeldKeys and not (love.keyboard.isDown('w') or 
                                       love.keyboard.isDown('s') or 
                                       love.keyboard.isDown('a') or 
                                       love.keyboard.isDown('d')) then
            self.ignoreHeldKeys = false
        end
    end
end

return InputManager