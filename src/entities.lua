-- entities.lua
local Entities = {}

function Entities.newBlock(blockType)
    return {
        type = blockType,
        selected = false,
        highlighted = false
    }
end

function Entities.newAxolotl(x, y)
    return {
        x = x,
        y = y,
        rotation = 0, -- 0: up, 90: right, 180: down, 270: left
        canRotate = false,
        -- Define the relative positions of reachable blocks based on rotation
        getRamiBlocks = function(self)
            local blocks = {}
            if self.rotation == 0 then -- Facing up
                return {
                    {dx = -1, dy = 0}, -- Left
                    {dx = 0, dy = -1},  -- Up
                    {dx = 1, dy = 0}   -- Right
                }
            elseif self.rotation == 90 then -- Facing right
                return {
                    {dx = 0, dy = -1}, -- Up
                    {dx = 1, dy = 0},  -- Right
                    {dx = 0, dy = 1}   -- Down
                }
            elseif self.rotation == 180 then -- Facing down
                return {
                    {dx = -1, dy = 0}, -- Left
                    {dx = 0, dy = 1},  -- Down
                    {dx = 1, dy = 0}   -- Right
                }
            else -- Facing left
                return {
                    {dx = 0, dy = -1}, -- Up
                    {dx = -1, dy = 0}, -- Left
                    {dx = 0, dy = 1}   -- Down
                }
            end
        end
    }
end

return Entities