-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local BULB_COLORS = {
    [1] = {
        bulbColor = { 0.9, 0.9, 0.8, 0.3 },
        glowColor = { 1.0, 0.9, 0.6 },
        filamentColor = { 1.0, 0.8, 0.3 }
    },
    [2] = {
        bulbColor = { 0.7, 0.8, 1.0, 0.3 },
        glowColor = { 0.6, 0.8, 1.0 },
        filamentColor = { 0.8, 0.9, 1.0 }
    },
    [3] = {
        bulbColor = { 0.8, 1.0, 0.8, 0.3 },
        glowColor = { 0.6, 1.0, 0.6 },
        filamentColor = { 0.9, 1.0, 0.7 }
    },
    [4] = {
        bulbColor = { 0.9, 0.7, 1.0, 0.3 },
        glowColor = { 0.8, 0.6, 1.0 },
        filamentColor = { 1.0, 0.8, 1.0 }
    }
}

local CONNECTIONS = {
    straight = {
        [0] = { "up", "down" },
        [1] = { "left", "right" },
        [2] = { "up", "down" },
        [3] = { "left", "right" },
    },
    corner = {
        [0] = { "up", "right" },
        [1] = { "right", "down" },
        [2] = { "down", "left" },
        [3] = { "left", "up" },
    },
    t_junction = {
        [0] = { "up", "right", "down" },
        [1] = { "right", "down", "left" },
        [2] = { "down", "left", "up" },
        [3] = { "left", "up", "right" },
    },
    cross = { [0] = { "up", "right", "down", "left" } },
    source = {
        [0] = { "right" },
        [1] = { "down" },
        [2] = { "left" },
        [3] = { "up" },
    },
    target = { [0] = { "up", "right", "down", "left" } }
}

local ipairs = ipairs

local line = love.graphics.line
local circle = love.graphics.circle
local setColor = love.graphics.setColor
local rectangle = love.graphics.rectangle

local Tile = {}
Tile.__index = Tile

function Tile.new(x, y, tileType, rotation, bulbType)
    local instance = setmetatable({}, Tile)

    instance.x = x
    instance.y = y
    instance.type = tileType or "empty"
    instance.rotation = rotation or 0 -- 0, 1, 2, 3 for 0°, 90°, 180°, 270°
    instance.powered = false
    instance.bulbType = bulbType or 1

    return instance
end

function Tile:rotate(clockwise)
    clockwise = clockwise ~= false -- Default to clockwise if not specified
    if clockwise then
        self.rotation = (self.rotation + 1) % 4
    else
        self.rotation = (self.rotation - 1) % 4
        if self.rotation < 0 then
            self.rotation = 3
        end
    end
    return self.rotation
end

function Tile:getConnections()
    local t = CONNECTIONS[self.type]
    if not t then return {} end
    return t[self.rotation % 4] or t[0] or {}
end

function Tile:drawLaserGenerator(x, y, gridSize, isPowered)
    local centerX = x + gridSize / 2
    local centerY = y + gridSize / 2
    local bodyWidth = gridSize * 0.6
    local bodyHeight = gridSize * 0.4

    -- Generator body (metal casing)
    setColor(0.3, 0.3, 0.4)
    rectangle("fill", centerX - bodyWidth / 2, centerY - bodyHeight / 2, bodyWidth, bodyHeight, 5)

    -- Generator details
    setColor(0.5, 0.5, 0.6)
    rectangle("line", centerX - bodyWidth / 2, centerY - bodyHeight / 2, bodyWidth, bodyHeight, 5)

    -- Heat sink fins
    local finCount = 5
    local finWidth = bodyWidth * 0.8
    local finHeight = bodyHeight * 0.15
    for i = 1, finCount do
        local finX = centerX - finWidth / 2
        local finY = centerY - bodyHeight / 2 - (i * finHeight * 0.8)
        setColor(0.4, 0.4, 0.5)
        rectangle("fill", finX, finY, finWidth, finHeight)
    end

    -- Laser emitter lens
    local lensSize = gridSize * 0.2
    local lensX, lensY

    -- Position lens based on rotation (output direction)
    if self.rotation == 0 then -- Right
        lensX = centerX + bodyWidth / 2
        lensY = centerY
    elseif self.rotation == 1 then -- Down
        lensX = centerX
        lensY = centerY + bodyWidth / 2
    elseif self.rotation == 2 then -- Left
        lensX = centerX - bodyWidth / 2
        lensY = centerY
    else -- Up
        lensX = centerX
        lensY = centerY - bodyWidth / 2
    end

    -- Lens with glow effect
    if isPowered then
        -- Inner bright lens
        setColor(0.0, 0.8, 1.0)
        circle("fill", lensX, lensY, lensSize)
        setColor(1.0, 1.0, 1.0)
        circle("fill", lensX, lensY, lensSize * 0.5)

        -- Outer glow
        setColor(0.0, 0.6, 1.0, 0.3)
        circle("fill", lensX, lensY, lensSize * 1.5)
    else
        -- Inactive lens
        setColor(0.2, 0.2, 0.3)
        circle("fill", lensX, lensY, lensSize)
        setColor(0.4, 0.4, 0.5)
        circle("line", lensX, lensY, lensSize)
    end

    -- Status indicator LED
    local ledSize = gridSize * 0.08
    local ledX = centerX - bodyWidth / 3
    local ledY = centerY + bodyHeight / 3

    if isPowered then
        setColor(0.0, 1.0, 0.0) -- Green when powered
    else
        setColor(0.3, 0.0, 0.0) -- Red when unpowered
    end
    circle("fill", ledX, ledY, ledSize)
end

function Tile:drawLightBulb(x, y, gridSize, isPowered)
    local centerX = x + gridSize / 2
    local centerY = y + gridSize / 2
    local bulbRadius = gridSize * 0.25
    local baseWidth = gridSize * 0.3
    local baseHeight = gridSize * 0.15

    local bulb_type = BULB_COLORS[self.bulbType]
    local bulbColor, glowColor, filamentColor = bulb_type.bulbColor, bulb_type.glowColor, bulb_type.filamentColor

    -- Metal base/socket
    setColor(0.3, 0.3, 0.3)
    rectangle("fill", centerX - baseWidth / 2, centerY + bulbRadius - baseHeight / 3, baseWidth, baseHeight, 3)

    -- Glass bulb
    if isPowered then
        -- Powered bulb with glow
        setColor(glowColor[1], glowColor[2], glowColor[3], 0.6)
        circle("fill", centerX, centerY, bulbRadius * 1.3) -- Outer glow

        setColor(bulbColor[1], bulbColor[2], bulbColor[3], bulbColor[4])
        circle("fill", centerX, centerY, bulbRadius) -- Bulb glass

        -- Bright filament when powered
        setColor(filamentColor[1], filamentColor[2], filamentColor[3])
        local filamentPoints = {
            centerX - bulbRadius * 0.3, centerY - bulbRadius * 0.2,
            centerX + bulbRadius * 0.1, centerY + bulbRadius * 0.3,
            centerX - bulbRadius * 0.1, centerY + bulbRadius * 0.1,
            centerX + bulbRadius * 0.3, centerY - bulbRadius * 0.1
        }
        love.graphics.setLineWidth(2)
        love.graphics.line(filamentPoints)
        love.graphics.setLineWidth(1)

        -- Additional inner glow
        setColor(1.0, 1.0, 0.8, 0.4)
        circle("fill", centerX, centerY, bulbRadius * 0.5)
    else
        -- Unpowered bulb
        setColor(bulbColor[1] * 0.5, bulbColor[2] * 0.5, bulbColor[3] * 0.5, bulbColor[4])
        circle("fill", centerX, centerY, bulbRadius) -- Bulb glass

        setColor(0.5, 0.5, 0.5)
        circle("line", centerX, centerY, bulbRadius) -- Bulb outline

        -- Dim filament when unpowered
        setColor(0.3, 0.3, 0.2)
        local filamentPoints = {
            centerX - bulbRadius * 0.3, centerY - bulbRadius * 0.2,
            centerX + bulbRadius * 0.1, centerY + bulbRadius * 0.3,
            centerX - bulbRadius * 0.1, centerY + bulbRadius * 0.1,
            centerX + bulbRadius * 0.3, centerY - bulbRadius * 0.1
        }
        love.graphics.setLineWidth(1)
        love.graphics.line(filamentPoints)
    end

    -- Base details
    setColor(0.2, 0.2, 0.2)
    rectangle("line", centerX - baseWidth / 2, centerY + bulbRadius - baseHeight / 3, baseWidth, baseHeight, 3)

    -- Screw threads on base
    setColor(0.4, 0.4, 0.4)
    for i = 1, 3 do
        local threadY = centerY + bulbRadius - baseHeight / 3 + (i * baseHeight / 4)
        love.graphics.line(centerX - baseWidth / 2, threadY, centerX + baseWidth / 2, threadY)
    end
end

function Tile:draw(offsetX, offsetY, gridSize, isPowered)
    local x = self.x * gridSize + offsetX
    local y = self.y * gridSize + offsetY

    -- Tile background
    if isPowered then
        setColor(0.3, 0.6, 1.0, 0.3)
    else
        setColor(0.1, 0.1, 0.2, 0.8)
    end
    rectangle("fill", x, y, gridSize, gridSize)

    -- Tile border
    setColor(0.3, 0.3, 0.5)
    rectangle("line", x, y, gridSize, gridSize)

    -- Draw connections based on type
    local centerX = x + gridSize / 2
    local centerY = y + gridSize / 2

    love.graphics.setLineWidth(3)

    if isPowered then
        setColor(0.3, 0.8, 1.0) -- Powered - blue
    else
        setColor(0.5, 0.5, 0.7) -- Unpowered - gray
    end

    local connections = self:getConnections()

    for _, dir in ipairs(connections) do
        if dir == "up" then
            line(centerX, centerY, centerX, y)
        elseif dir == "right" then
            line(centerX, centerY, x + gridSize, centerY)
        elseif dir == "down" then
            line(centerX, centerY, centerX, y + gridSize)
        elseif dir == "left" then
            line(centerX, centerY, x, centerY)
        end
    end

    -- Special rendering for source and target
    if self.type == "source" then
        self:drawLaserGenerator(x, y, gridSize, isPowered)
    elseif self.type == "target" then
        self:drawLightBulb(x, y, gridSize, isPowered)
    end

    love.graphics.setLineWidth(1)
end

return Tile
