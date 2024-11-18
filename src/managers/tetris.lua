local TetrisManager = {
    MODES = {
        NAVIGATION = "navigation",
        TETRIS = "tetris"
    }
}

function TetrisManager:new()
    local manager = {
        currentMode = self.MODES.NAVIGATION,
        sessionCount = 0,
        game = nil
    }
    setmetatable(manager, { __index = self })
    return manager
end

function TetrisManager:init(game)
    self.game = game
end

function TetrisManager:hasTetriminos()
    -- Check if player has any tetriminos available
    for _, count in pairs(self.game.tetrimino.tetriminoCounts) do
        if count > 0 then
            return true
        end
    end
    return false
end

function TetrisManager:canEnterTetrisMode()
    return self.currentMode == self.MODES.NAVIGATION and self:hasTetriminos()
end

function TetrisManager:tryEnterTetrisMode()
    if self:canEnterTetrisMode() then
        self.currentMode = self.MODES.TETRIS
        self.sessionCount = self.sessionCount + 1
        return true
    end
    return false
end

function TetrisManager:exitTetrisMode()
    if self.currentMode == self.MODES.TETRIS then
        self.currentMode = self.MODES.NAVIGATION
    end
end

function TetrisManager:isInTetrisMode()
    return self.currentMode == self.MODES.TETRIS
end

return TetrisManager