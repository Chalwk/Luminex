-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local newAudioSource = love.audio.newSource
local playSound = love.audio.play

local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager.new()
    local instance = setmetatable({
        sounds = {
            rotate = newAudioSource("assets/sounds/rotate.mp3", "static"),
            connect = newAudioSource("assets/sounds/connect.mp3", "static"),
            win = newAudioSource("assets/sounds/win.mp3", "static"),
            background = newAudioSource("assets/sounds/background.mp3", "stream")
        }
    }, SoundManager)

    for _, sound in pairs(instance.sounds) do
        instance:setVolume(sound, 0.7)
    end

    instance:play("background", true)

    return instance
end

function SoundManager:play(soundName, loop)
    if loop then self.sounds[soundName]:setLooping(true) end
    self.sounds[soundName]:stop()
    self.sounds[soundName]:play()
end

function SoundManager:setVolume(sound, volume)
    sound:setVolume(volume)
end

return SoundManager
