-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_sin = math.sin

local Laser = {}
Laser.__index = Laser

function Laser.new(gridSize, source)
    local instance = setmetatable({}, Laser)

    instance.gridSize = gridSize
    instance.source = source
    instance.beamSegments = {}
    instance.time = 0

    return instance
end

function Laser:update(dt, mirrors)
    self.time = self.time + dt
    self.beamSegments = self:calculateBeamPath(mirrors)
end

function Laser:calculateBeamPath(mirrors)
    local segments = {}
    local mirrorMap = {}

    -- Create mirror lookup table
    for _, mirror in ipairs(mirrors) do
        mirrorMap[mirror.x .. "," .. mirror.y] = mirror
    end

    -- Start from laser source
    local x, y, dir = self.source.x, self.source.y, self.source.dir
    local visited = {}

    while true do
        local key = x .. "," .. y .. "," .. dir
        if visited[key] then break end
        visited[key] = true

        -- Calculate next position
        local nextX, nextY = x, y
        if dir == "right" then
            nextX = x + 1
        elseif dir == "left" then
            nextX = x - 1
        elseif dir == "down" then
            nextY = y + 1
        elseif dir == "up" then
            nextY = y - 1
        end

        -- Add current segment
        table.insert(segments, {
            startX = x, startY = y,
            endX = nextX, endY = nextY,
            dir = dir
        })

        -- Check bounds
        if nextX < 0 or nextX >= 10 or nextY < 0 or nextY >= 10 then break end

        -- Check for mirror at next position
        local mirrorKey = nextX .. "," .. nextY
        local mirror = mirrorMap[mirrorKey]

        if mirror then
            -- Change direction based on mirror type
            if mirror.angle == 0 then -- 45° mirror (\)
                if dir == "right" then dir = "down"
                elseif dir == "left" then dir = "up"
                elseif dir == "up" then dir = "left"
                elseif dir == "down" then dir = "right" end
            else -- 135° mirror (/)
                if dir == "right" then dir = "up"
                elseif dir == "left" then dir = "down"
                elseif dir == "up" then dir = "right"
                elseif dir == "down" then dir = "left" end
            end
        end

        x, y = nextX, nextY

        -- Safety check
        if #segments > 50 then break end
    end

    return segments
end

function Laser:checkTargetsHit(targets)
    local beamPositions = {}
    for _, segment in ipairs(self.beamSegments) do
        beamPositions[segment.startX .. "," .. segment.startY] = true
        beamPositions[segment.endX .. "," .. segment.endY] = true
    end

    for _, target in ipairs(targets) do
        if not beamPositions[target.x .. "," .. target.y] then
            return false
        end
    end

    return #targets > 0
end

function Laser:draw(offsetX, offsetY)
    -- Draw beam segments as continuous lines
    for i, segment in ipairs(self.beamSegments) do
        local startScreenX = segment.startX * self.gridSize + offsetX + self.gridSize / 2
        local startScreenY = segment.startY * self.gridSize + offsetY + self.gridSize / 2
        local endScreenX = segment.endX * self.gridSize + offsetX + self.gridSize / 2
        local endScreenY = segment.endY * self.gridSize + offsetY + self.gridSize / 2

        local pulse = (math_sin(self.time * 8 + i * 0.5) + 1) * 0.3 + 0.4

        -- Outer glow
        love.graphics.setLineWidth(8)
        love.graphics.setColor(1, 0.2, 0.2, 0.2 * pulse)
        love.graphics.line(startScreenX, startScreenY, endScreenX, endScreenY)

        -- Main beam
        love.graphics.setLineWidth(5)
        love.graphics.setColor(1, 0.5, 0.2, 0.6 * pulse)
        love.graphics.line(startScreenX, startScreenY, endScreenX, endScreenY)

        -- Inner core
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 0.8, 0.4, 0.9 * pulse)
        love.graphics.line(startScreenX, startScreenY, endScreenX, endScreenY)

        -- Sparkle effect at segment joints
        if i > 1 then
            love.graphics.setColor(1, 1, 1, pulse * 0.8)
            love.graphics.circle("fill", startScreenX, startScreenY, 2)
        end
    end

    love.graphics.setLineWidth(1)

    -- Draw laser source
    self:drawLaserSource(offsetX, offsetY)
end

function Laser:drawLaserSource(offsetX, offsetY)
    local x = self.source.x * self.gridSize + offsetX
    local y = self.source.y * self.gridSize + offsetY

    -- Base
    love.graphics.setColor(0.1, 0.3, 0.8)
    love.graphics.rectangle("fill", x + 8, y + 8, self.gridSize - 16, self.gridSize - 16)

    -- Emitter
    love.graphics.setColor(0.3, 0.6, 1.0)
    love.graphics.rectangle("fill", x + 12, y + 12, self.gridSize - 24, self.gridSize - 24)

    -- Direction indicator with glow
    local pulse = (math_sin(self.time * 6) + 1) * 0.3 + 0.4
    love.graphics.setColor(0.5, 0.8, 1.0, pulse)

    local centerX = x + self.gridSize / 2
    local centerY = y + self.gridSize / 2

    if self.source.dir == "right" then
        love.graphics.polygon("fill",
            centerX + 10, centerY,
            centerX + 2, centerY - 6,
            centerX + 2, centerY + 6
        )
    elseif self.source.dir == "left" then
        love.graphics.polygon("fill",
            centerX - 10, centerY,
            centerX - 2, centerY - 6,
            centerX - 2, centerY + 6
        )
    elseif self.source.dir == "down" then
        love.graphics.polygon("fill",
            centerX, centerY + 10,
            centerX - 6, centerY + 2,
            centerX + 6, centerY + 2
        )
    elseif self.source.dir == "up" then
        love.graphics.polygon("fill",
            centerX, centerY - 10,
            centerX - 6, centerY - 2,
            centerX + 6, centerY - 2
        )
    end
end

return Laser