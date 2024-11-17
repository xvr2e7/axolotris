local Timer = require 'src/timer'
local Entities = require 'src/entities'

local Game = {
    GRID_SIZE = 32,
    GRID_WIDTH = 12,
    GRID_HEIGHT = 21,
    SIDEBAR_WIDTH = 6, -- Width for tetrimino showcase
    COLORS = {
        background = {0.1, 0.1, 0.15},
        grid = {0.2, 0.2, 0.25},
        gridLine = {0.3, 0.3, 0.35, 0.5},
        trapBlock = {0.6, 0.4, 0.4},
        highlighted = {0.8, 0.6, 0.6},
        selected = {0.5, 0.5, 0.5},
        axolotl = {0.9, 0.5, 0.7},
        -- Classic tetrimino colors
        tetrimino = {
            I = {0.0, 0.8, 0.8}, -- Cyan
            J = {0.0, 0.0, 0.8}, -- Blue
            L = {0.8, 0.4, 0.0}, -- Orange
            O = {0.8, 0.8, 0.0}, -- Yellow
            S = {0.0, 0.8, 0.0}, -- Green
            T = {0.8, 0.0, 0.8}, -- Purple
            Z = {0.8, 0.0, 0.0}  -- Red
        }
    },
    -- Tetrimino definitions (relative coordinates)
    TETRIMINOES = {
        I = {{{0,0}, {0,1}, {0,2}, {0,3}}},
        J = {{{0,0}, {0,1}, {0,2}, {-1,2}}},
        L = {{{0,0}, {0,1}, {0,2}, {1,2}}},
        O = {{{0,0}, {1,0}, {0,1}, {1,1}}},
        S = {{{0,0}, {1,0}, {-1,1}, {0,1}}},
        T = {{{0,0}, {-1,1}, {0,1}, {1,1}}},
        Z = {{{-1,0}, {0,0}, {0,1}, {1,1}}}
    }
}

function Game:isValidPosition(x, y)
    return x >= 1 and x <= self.GRID_WIDTH and
           y >= 1 and y <= self.GRID_HEIGHT
end

function Game:canRotate()
    local ax, ay = self.axolotl.x, self.axolotl.y
    -- Check if we have space to rotate (not at edges)
    return ax > 1 and ax < self.GRID_WIDTH and ay > 1 and ay < self.GRID_HEIGHT
end

function Game:updateHighlights()
    -- Reset all highlights
    for y = 1, self.GRID_HEIGHT do
        for x = 1, self.GRID_WIDTH do
            self.grid[y][x].highlighted = false
        end
    end
    
    -- Apply new highlights based on axolotl position and rotation
    local ramiBlocks = self.axolotl:getRamiBlocks()
    for _, block in ipairs(ramiBlocks) do
        local x = self.axolotl.x + block.dx
        local y = self.axolotl.y + block.dy
        if self:isValidPosition(x, y) then
            self.grid[y][x].highlighted = true
        end
    end
end

function Game:handleMouseClick(mouseX, mouseY)
    local gridX = math.floor(mouseX / self.GRID_SIZE) + 1
    local gridY = math.floor(mouseY / self.GRID_SIZE) + 1

    if self:isValidPosition(gridX, gridY) then
        local block = self.grid[gridY][gridX]
        if block.highlighted then
            block.selected = not block.selected

            -- Check for tetrimino after selection change
            local selected = self:getSelectedBlocks()
            local tetriminoType = self:detectTetrimino(selected)

            if tetriminoType then
                self:startTetriminoTransition(selected, tetriminoType)
            end
        end
    end
end

function Game:moveAxolotl(dx, dy)
    local newX = self.axolotl.x + dx
    local newY = self.axolotl.y + dy
    
    if self:isValidPosition(newX, newY) then
        self.axolotl.x = newX
        self.axolotl.y = newY
        self:updateHighlights()
    end
end

function Game:rotateAxolotl()
    if self:canRotate() then
        self.axolotl.rotation = (self.axolotl.rotation + 90) % 360
        self:updateHighlights()
    end
end

function Game:update(dt)
    self.lastMove = self.lastMove + dt
    
    -- Update timers
    Timer.update(dt)
    
    -- Handle input with move delay
    if self.lastMove >= self.MOVE_DELAY then
        if love.keyboard.isDown('w') then
            self:moveAxolotl(0, -1)
            self.lastMove = 0
        elseif love.keyboard.isDown('s') then
            self:moveAxolotl(0, 1)
            self.lastMove = 0
        elseif love.keyboard.isDown('a') then
            self:moveAxolotl(-1, 0)
            self.lastMove = 0
        elseif love.keyboard.isDown('d') then
            self:moveAxolotl(1, 0)
            self.lastMove = 0
        elseif love.keyboard.isDown('r') then
            self:rotateAxolotl()
            self.lastMove = 0
        end
    end
end

function Game:getSelectedBlocks()
    local selected = {}
    for y = 1, self.GRID_HEIGHT do
        for x = 1, self.GRID_WIDTH do
            if self.grid[y][x].selected then
                table.insert(selected, {x = x, y = y, block = self.grid[y][x]})
            end
        end
    end
    return selected
end

function Game:rotatePattern(pattern)
    local rotated = {}
    for _, p in ipairs(pattern) do
        table.insert(rotated, {-p[2], p[1]}) -- 90-degree rotation
    end
    return rotated
end

function Game:normalizePattern(pattern)
    -- Find minimum x and y
    local minX, minY = math.huge, math.huge
    for _, p in ipairs(pattern) do
        minX = math.min(minX, p[1])
        minY = math.min(minY, p[2])
    end
    -- Normalize by subtracting minimum
    local normalized = {}
    for _, p in ipairs(pattern) do
        table.insert(normalized, {p[1] - minX, p[2] - minY})
    end
    return normalized
end

function Game:patternsMatch(pattern1, pattern2)
    if #pattern1 ~= #pattern2 then return false end
    
    -- Create copies of patterns for sorting
    local sorted1 = {}
    local sorted2 = {}
    
    -- Copy patterns
    for _, p in ipairs(pattern1) do
        table.insert(sorted1, {x = p[1], y = p[2]})
    end
    for _, p in ipairs(pattern2) do
        table.insert(sorted2, {x = p[1], y = p[2]})
    end
    
    -- Sort based on coordinates
    local function sortCoords(a, b)
        if a.x == b.x then
            return a.y < b.y
        end
        return a.x < b.x
    end
    
    table.sort(sorted1, sortCoords)
    table.sort(sorted2, sortCoords)
    
    -- Compare sorted patterns
    for i = 1, #sorted1 do
        if sorted1[i].x ~= sorted2[i].x or sorted1[i].y ~= sorted2[i].y then
            return false
        end
    end
    
    return true
end


function Game:detectTetrimino(selected)
    if #selected ~= 4 then return nil end

    -- Convert selected blocks to relative pattern
    local pattern = {}
    local baseX, baseY = selected[1].x, selected[1].y

    for _, pos in ipairs(selected) do
        table.insert(pattern, { pos.x - baseX, pos.y - baseY })
    end

    -- Normalize pattern
    pattern = self:normalizePattern(pattern)

    -- Debug output
    print("Testing pattern:")
    for _, p in ipairs(pattern) do
        print(string.format("(%d, %d)", p[1], p[2]))
    end

    -- Check against all tetrimino patterns
    for type, basePatterns in pairs(self.TETRIMINOES) do
        local testPattern = basePatterns[1] -- Get first rotation

        -- Try all rotations
        for i = 1, 4 do
            local rotatedPattern = testPattern
            if i > 1 then
                rotatedPattern = self:rotatePattern(testPattern)
            end

            -- Normalize rotated pattern
            local normalizedRotation = self:normalizePattern(rotatedPattern)

            -- Debug output
            print("Testing against " .. type .. " rotation " .. i)
            for _, p in ipairs(normalizedRotation) do
                print(string.format("(%d, %d)", p[1], p[2]))
            end

            if self:patternsMatch(pattern, normalizedRotation) then
                print("Match found: " .. type)
                return type
            end

            testPattern = rotatedPattern
        end
    end

    print("No match found")
    return nil
end

function Game:printPattern(pattern, label)
    print(label or "Pattern:")
    for _, p in ipairs(pattern) do
        print(string.format("(%d, %d)", p[1], p[2]))
    end
end

function Game:startTetriminoTransition(blocks, type)
    local color = self.COLORS.tetrimino[type]
    for _, pos in ipairs(blocks) do
        local block = self.grid[pos.y][pos.x]
        block.color = block.color or self.COLORS.selected
        block.targetColor = color
        block.transitionStart = love.timer.getTime()
        block.tetriminoType = type
    end
    
    -- Update counter
    self.tetriminoCounts[type] = (self.tetriminoCounts[type] or 0) + 1
    
    -- Schedule cleanup using our Timer utility
    Timer.after(0.6, function()
        for _, pos in ipairs(blocks) do
            local block = self.grid[pos.y][pos.x]
            block.selected = false
            block.color = nil
            block.targetColor = nil
            block.tetriminoType = nil
        end
    end)
end

function Game:draw()
    -- Draw background
    love.graphics.setColor(self.COLORS.background)
    love.graphics.rectangle("fill", 0, 0,
        self.GRID_WIDTH * self.GRID_SIZE,
        self.GRID_HEIGHT * self.GRID_SIZE)
    
    -- Draw grid lines
    love.graphics.setColor(self.COLORS.gridLine)
    for y = 0, self.GRID_HEIGHT do
        love.graphics.line(
            0, y * self.GRID_SIZE,
            self.GRID_WIDTH * self.GRID_SIZE, y * self.GRID_SIZE
        )
    end
    for x = 0, self.GRID_WIDTH do
        love.graphics.line(
            x * self.GRID_SIZE, 0,
            x * self.GRID_SIZE, self.GRID_HEIGHT * self.GRID_SIZE
        )
    end
    
    -- Draw blocks with proper color transitions
    local currentTime = love.timer.getTime()
    for y = 1, self.GRID_HEIGHT do
        for x = 1, self.GRID_WIDTH do
            local block = self.grid[y][x]
            if block then
                if block.color and block.targetColor then
                    local progress = (currentTime - block.transitionStart) / block.transitionDuration
                    if progress < 1 then
                        -- Interpolate colors
                        local r = block.color[1] + (block.targetColor[1] - block.color[1]) * progress
                        local g = block.color[2] + (block.targetColor[2] - block.color[2]) * progress
                        local b = block.color[3] + (block.targetColor[3] - block.color[3]) * progress
                        love.graphics.setColor(r, g, b)
                    else
                        love.graphics.setColor(block.targetColor)
                    end
                elseif block.selected then
                    love.graphics.setColor(self.COLORS.selected)
                elseif block.highlighted then
                    love.graphics.setColor(self.COLORS.highlighted)
                else
                    love.graphics.setColor(self.COLORS.trapBlock)
                end
                
                love.graphics.rectangle("fill",
                    (x-1) * self.GRID_SIZE + 1,
                    (y-1) * self.GRID_SIZE + 1,
                    self.GRID_SIZE - 2,
                    self.GRID_SIZE - 2
                )
            end
        end
    end
    
    -- Draw tetrimino showcase
    local showcaseX = -self.SIDEBAR_WIDTH * self.GRID_SIZE
    local showcaseY = 0
    
    for type, pattern in pairs(self.TETRIMINOES) do
        -- Draw tetrimino
        love.graphics.setColor(self.COLORS.tetrimino[type])
        for _, pos in ipairs(pattern[1]) do
            love.graphics.rectangle("fill",
                showcaseX + (pos[1] + 2) * self.GRID_SIZE + 1,
                showcaseY + pos[2] * self.GRID_SIZE + 1,
                self.GRID_SIZE - 2,
                self.GRID_SIZE - 2
            )
        end
        
        -- Draw count
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(
            tostring(self.tetriminoCounts[type] or 0),
            showcaseX + 4 * self.GRID_SIZE,
            showcaseY + self.GRID_SIZE
        )
        
        showcaseY = showcaseY + 4 * self.GRID_SIZE
    end
    
    -- Draw axolotl
    love.graphics.setColor(self.COLORS.axolotl)
    love.graphics.push()
    love.graphics.translate(
        (self.axolotl.x-0.5) * self.GRID_SIZE,
        (self.axolotl.y-0.5) * self.GRID_SIZE
    )
    love.graphics.rotate(math.rad(self.axolotl.rotation))
    
    -- Main body
    love.graphics.rectangle("fill",
        -self.GRID_SIZE/3,
        -self.GRID_SIZE/3,
        self.GRID_SIZE*2/3,
        self.GRID_SIZE*2/3
    )
    
    -- Direction indicator
    love.graphics.polygon("fill",
        0, -self.GRID_SIZE/3,
        self.GRID_SIZE/4, 0,
        -self.GRID_SIZE/4, 0
    )
    
    love.graphics.pop()
end

function Game:new()
    local game = {
        grid = {},
        selectedBlocks = {},
        lastMove = 0,
        MOVE_DELAY = 0.15,
        tetriminoCounts = {} -- Track count of each tetrimino type
    }
    
    setmetatable(game, {__index = self})
    
    -- Initialize grid
    for y = 1, self.GRID_HEIGHT do
        game.grid[y] = {}
        for x = 1, self.GRID_WIDTH do
            game.grid[y][x] = Entities.newBlock("trap")
        end
    end
    
    -- Create axolotl at bottom center
    game.axolotl = Entities.newAxolotl(
        math.floor(self.GRID_WIDTH / 2),
        self.GRID_HEIGHT - 1
    )
    
    game:updateHighlights()
    
    return game
end

return Game