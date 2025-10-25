local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager.new()
    local instance = setmetatable({}, SoundManager)

    instance.sounds = {
        rotate = love.audio.newSource("assets/sounds/rotate.mp3", "static"),
        connect = love.audio.newSource("assets/sounds/connect.mp3", "static"),
        win = love.audio.newSource("assets/sounds/win.mp3", "static"),
    }

    -- Set volumes
    for _, sound in pairs(instance.sounds) do
        sound:setVolume(0.7)
    end

    return instance
end

function SoundManager:play(soundName)
    if self.sounds[soundName] then
        self.sounds[soundName]:stop()
        self.sounds[soundName]:play()
    end
end

function SoundManager:setVolume(volume)
    for _, sound in pairs(self.sounds) do
        sound:setVolume(volume)
    end
end

return SoundManager
