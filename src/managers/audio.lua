local AudioManager = {}

function AudioManager:new()
    local manager = {
        music = nil,
        volume = 1.0
    }
    setmetatable(manager, { __index = self })
    return manager
end

function AudioManager:loadMusic(filepath)
    -- Load music file as streaming source for memory efficiency
    self.music = love.audio.newSource(filepath, "stream")
    -- Loop music continuously
    self.music:setLooping(true)
    self.music:setVolume(self.volume)
end

function AudioManager:play()
    if self.music then
        love.audio.play(self.music)
    end
end

function AudioManager:stop()
    if self.music then
        love.audio.stop(self.music)
    end
end

function AudioManager:setVolume(volume)
    self.volume = math.max(0, math.min(1, volume))
    if self.music then
        self.music:setVolume(self.volume)
    end
end

return AudioManager