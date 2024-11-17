local Entities = {}

-- Block entity
function Entities.newBlock(blockType)
    return {
        type = blockType,
        selected = false
    }
end

-- Axolotl entity
function Entities.newAxolotl(x, y)
    return {
        x = x,
        y = y,
        rotation = 0,
        movementArea = {
            minX = x - 1,
            maxX = x + 2,
            minY = y - 1,
            maxY = y + 2
        }
    }
end

return Entities