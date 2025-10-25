-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs

local line = love.graphics.line
local circle = love.graphics.circle
local setColor = love.graphics.setColor
local rectangle = love.graphics.rectangle

local Tile = {}
Tile.__index = Tile

function Tile.new(x, y, tileType, rotation)
    local instance = setmetatable({}, Tile)

    instance.x = x
    instance.y = y
    instance.type = tileType or "empty"
    instance.rotation = rotation or 0 -- 0, 1, 2, 3 for 0°, 90°, 180°, 270°
    instance.powered = false

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
    -- Returns which sides are connected based on tile type and rotation
    local connections = {}

    if self.type == "straight" then
        if self.rotation % 2 == 0 then
            connections = { "up", "down" }    -- Vertical
        else
            connections = { "left", "right" } -- Horizontal
        end
    elseif self.type == "corner" then
        if self.rotation == 0 then
            connections = { "up", "right" }
        elseif self.rotation == 1 then
            connections = { "right", "down" }
        elseif self.rotation == 2 then
            connections = { "down", "left" }
        else
            connections = { "left", "up" }
        end
    elseif self.type == "t_junction" then
        if self.rotation == 0 then
            connections = { "up", "right", "down" }
        elseif self.rotation == 1 then
            connections = { "right", "down", "left" }
        elseif self.rotation == 2 then
            connections = { "down", "left", "up" }
        else
            connections = { "left", "up", "right" }
        end
    elseif self.type == "cross" then
        connections = { "up", "right", "down", "left" }
    elseif self.type == "source" then
        -- Source has one output direction
        if self.rotation == 0 then
            connections = { "right" } -- Output to right
        elseif self.rotation == 1 then
            connections = { "down" }
        elseif self.rotation == 2 then
            connections = { "left" }
        else
            connections = { "up" }
        end
    elseif self.type == "target" then
        -- Target accepts from all directions
        connections = { "up", "right", "down", "left" }
    end

    return connections
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
        setColor(0.2, 0.8, 0.2) -- Green source
        circle("fill", centerX, centerY, gridSize / 4)
    elseif self.type == "target" then
        setColor(1.0, 0.8, 0.2) -- Yellow target
        circle("line", centerX, centerY, gridSize / 3)
        if isPowered then
            setColor(1.0, 1.0, 0.0)
            circle("fill", centerX, centerY, gridSize / 6)
        end
    end

    love.graphics.setLineWidth(1)
end

return Tile
