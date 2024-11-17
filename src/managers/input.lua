local Timer = require('src.timer')

local InputManager = {}

function InputManager:new(moveDelay, gridSize)
    local manager = {
        lastMove = 0,
        moveDelay = moveDelay or 0.15,
        gridSize = gridSize or 32
    }
    setmetatable(manager, { __index = self })
    return manager
end

function InputManager:handleMouseClick(x, y, game)
    local gridX = math.floor(x / self.gridSize) + 1
    local gridY = math.floor(y / self.gridSize) + 1
    
    if game:isValidPosition(gridX, gridY) then
        local block = game.grid.grid[gridY][gridX]
        if block.highlighted then
            -- Toggle block selection
            block.selected = not block.selected
            
            -- Get all selected blocks
            local selected = game.grid:getSelectedBlocks()
            
            -- If we have 4 or more selected blocks
            if #selected >= 4 then
                -- Check all possible combinations of 4 blocks
                local combinations = game:findCombinations(selected, 4)
                
                for _, combo in ipairs(combinations) do
                    local tetriminoType = game.tetrimino:detectTetrimino(combo)
                    if tetriminoType then
                        -- Found a valid tetrimino! Start transition
                        game:startTetriminoTransition(combo, tetriminoType)
                        break  -- Only handle one tetrimino at a time
                    end
                end
            end
        end
    end
end

function InputManager:update(dt, game)
    self.lastMove = self.lastMove + dt

    -- Update timers
    Timer.update(dt)

    -- Handle input with move delay
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
        elseif love.keyboard.isDown('r') then
            game:rotateAxolotl()
            self.lastMove = 0
        end
    end
end

return InputManager