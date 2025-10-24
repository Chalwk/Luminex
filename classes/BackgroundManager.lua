-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local table_insert = table.insert

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.particles = {}
    instance.laserBeams = {}
    instance.time = 0
    instance:initParticles()
    instance:initLaserBeams()
    return instance
end

function BackgroundManager:initLaserBeams()
    self.laserBeams = {}
    for i = 1, 4 do
        table_insert(self.laserBeams, {
            x1 = math_random(0, 1200),
            y1 = math_random(0, 800),
            x2 = math_random(0, 1200),
            y2 = math_random(0, 800),
            width = math_random(1, 3),
            speed = math_random(0.5, 2),
            phase = math_random() * math_pi * 2,
            color = {
                math_random(0.8, 1.0),
                math_random(0.2, 0.4),
                math_random(0.1, 0.3)
            }
        })
    end
end

function BackgroundManager:initParticles()
    self.particles = {}
    for i = 1, 60 do
        table_insert(self.particles, {
            x = math_random() * 1200,
            y = math_random() * 800,
            size = math_random(1, 2),
            speed = math_random(30, 100),
            angle = math_random() * math_pi * 2,
            pulseSpeed = math_random(2, 5),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 2),
            life = math_random(5, 15),
            maxLife = math_random(5, 15),
            color = {
                math_random(0.8, 1.0),
                math_random(0.2, 0.4),
                math_random(0.1, 0.3)
            }
        })
    end
end

function BackgroundManager:update(dt)
    self.time = self.time + dt

    -- Update laser beams
    for _, beam in ipairs(self.laserBeams) do
        beam.phase = beam.phase + beam.speed * dt
    end

    -- Update particles
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt

        if particle.life <= 0 then
            table.remove(self.particles, i)
        else
            particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
            particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt

            if particle.x < -100 then particle.x = 1300 end
            if particle.x > 1300 then particle.x = -100 end
            if particle.y < -100 then particle.y = 900 end
            if particle.y > 900 then particle.y = -100 end
        end
    end

    while #self.particles < 60 do
        table_insert(self.particles, {
            x = math_random() * 1200,
            y = -50,
            size = math_random(1, 2),
            speed = math_random(30, 100),
            angle = math_random(0.2, 0.8) * math_pi,
            pulseSpeed = math_random(2, 5),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 2),
            life = math_random(5, 15),
            maxLife = math_random(5, 15),
            color = {
                math_random(0.8, 1.0),
                math_random(0.2, 0.4),
                math_random(0.1, 0.3)
            }
        })
    end
end

function BackgroundManager:draw(screenWidth, screenHeight, gameState)
    local time = love.timer.getTime()

    -- Deep space background
    love.graphics.setColor(0.05, 0.02, 0.08)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Laser grid pattern
    love.graphics.setColor(0.15, 0.05, 0.25, 0.3)
    local gridSize = 80
    for x = 0, screenWidth, gridSize do
        love.graphics.line(x, 0, x, screenHeight)
    end
    for y = 0, screenHeight, gridSize do
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Draw laser beams
    for _, beam in ipairs(self.laserBeams) do
        local alpha = (math_sin(beam.phase) + 1) * 0.15 + 0.1
        love.graphics.setColor(beam.color[1], beam.color[2], beam.color[3], alpha)
        love.graphics.setLineWidth(beam.width)
        love.graphics.line(beam.x1, beam.y1, beam.x2, beam.y2)
    end
    love.graphics.setLineWidth(1)

    -- Glowing nodes at grid intersections
    love.graphics.setColor(0.4, 0.1, 0.8, 0.4)
    for x = gridSize / 2, screenWidth, gridSize do
        for y = gridSize / 2, screenHeight, gridSize do
            local pulse = (math_sin(time * 2 + x * 0.01 + y * 0.01) + 1) * 0.5
            love.graphics.setColor(0.3, 0.1, 0.6, 0.2 + pulse * 0.2)
            love.graphics.circle("fill", x, y, 2 + pulse * 2)
        end
    end

    -- Particles
    for _, particle in ipairs(self.particles) do
        local lifeProgress = particle.life / particle.maxLife
        local pulse = (math_sin(particle.pulsePhase + time * particle.pulseSpeed) + 1) * 0.5
        local currentSize = particle.size * (0.7 + pulse * 0.3)
        local alpha = lifeProgress * (0.2 + pulse * 0.3)

        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)

        if particle.type == 1 then
            love.graphics.circle("fill", particle.x, particle.y, currentSize)
        else
            love.graphics.rectangle("fill", particle.x - currentSize, particle.y - currentSize,
                currentSize * 2, currentSize * 2)
        end
    end

    -- Central glow effect
    local centerPulse = (math_sin(time * 1.5) + 1) * 0.2 + 0.3
    love.graphics.setColor(0.3, 0.1, 0.5, centerPulse * 0.1)
    love.graphics.circle("fill", screenWidth / 2, screenHeight / 2, 200)
end

return BackgroundManager
