local AudioManager = {}

function AudioManager:new()
    local manager = {
        music = nil,
        volume = 1.0,
        wasPaused = false  -- Track if audio was paused by menu
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
        -- Only start playing if not already playing
        if not self.music:isPlaying() then
            love.audio.play(self.music)
        end
    end
end

function AudioManager:stop()
    if self.music then
        love.audio.stop(self.music)
    end
end

function AudioManager:pause()
    if self.music and self.music:isPlaying() then
        self.wasPaused = true
        self.music:pause()
    end
end

function AudioManager:resume()
    if self.music and self.wasPaused then
        self.wasPaused = false
        self.music:play()
    end
end

function AudioManager:restart()
    if self.music then
        -- Stop current playback
        self.music:stop()
        -- Reset to beginning
        self.music:seek(0)
        -- Start playing
        self.music:play()
    end
end

function AudioManager:setVolume(volume)
    self.volume = math.max(0, math.min(1, volume))
    if self.music then
        self.music:setVolume(self.volume)
    end
end

return AudioManager