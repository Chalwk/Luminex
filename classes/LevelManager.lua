-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local table_insert = table.insert

local opposites = {
    up = "down",
    down = "up",
    left = "right",
    right = "left"
}

local LevelManager = {}
LevelManager.__index = LevelManager

function LevelManager.new(gridSize)
    local instance = setmetatable({}, LevelManager)
    instance.gridSize = gridSize
    instance.levels = {}
    instance:initLevels()
    return instance
end

function LevelManager:initLevels()
    self.levels = {
        { -- Level 1: Simple straight line (5x3)
            name = "First Connection",
            grid = {
                { "source", "straight", "straight", "straight", "target" },
                { "empty",  "empty",    "empty",    "empty",    "empty" },
                { "empty",  "empty",    "empty",    "empty",    "empty" }
            },
            rotations = {
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0 }
        },
        { -- Level 2: Right angle (5x3)
            name = "The Corner",
            grid = {
                { "source", "straight", "corner", "empty",    "empty" },
                { "empty",  "empty",    "corner", "straight", "target" },
                { "empty",  "empty",    "empty",  "empty",    "empty" }
            },
            rotations = {
                1, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0 }
        },
        { -- Level 3: Split path (5x3)
            name = "Double Trouble",
            grid = {
                { "source", "straight", "t_junction", "straight", "target" },
                { "empty",  "empty",    "corner",     "corner",   "empty" },
                { "empty",  "empty",    "empty",      "corner",   "target" }
            },
            rotations = {
                1, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0 }
        },
        { -- Level 4: Crossroads (4x4)
            name = "Crossroads",
            grid = {
                { "empty",  "empty",    "empty",    "empty" },
                { "source", "cross",    "straight", "target" },
                { "empty",  "straight", "empty",    "empty" },
                { "empty",  "target",   "empty",    "empty" }
            },
            rotations = {
                1, 0, 0, 0,
                0, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 0, 0 }
        },
        { -- Level 5: Spiral (5x4)
            name = "The Spiral",
            grid = {
                { "source", "straight", "corner",   "corner", "corner" },
                { "empty",  "empty",    "straight", "target", "straight" },
                { "empty",  "empty",    "corner",   "corner", "straight" },
                { "empty",  "empty",    "empty",    "empty",  "empty" }
            },
            rotations = {
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0 }
        },
        { -- Level 6: Double Source (5x4)
            name = "Twin Beams",
            grid = {
                { "source", "straight", "t_junction", "straight", "target" },
                { "empty",  "empty",    "corner",     "empty",    "empty" },
                { "source", "straight", "t_junction", "straight", "target" },
                { "empty",  "empty",    "empty",      "empty",    "empty" }
            },
            rotations = {
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0 }
        },
        { -- Level 7: Maze (5x4)
            name = "The Maze",
            grid = {
                { "source", "straight", "corner",   "corner",     "corner" },
                { "empty",  "empty",    "straight", "t_junction", "straight" },
                { "empty",  "empty",    "corner",   "straight",   "target" },
                { "empty",  "empty",    "empty",    "corner",     "corner" }
            },
            rotations = {
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0 }
        },
        { -- Level 8: Complex Junction (5x5)
            name = "Junction Box",
            grid = {
                { "empty", "source",   "empty",    "empty",      "empty" },
                { "empty", "cross",    "straight", "t_junction", "target" },
                { "empty", "straight", "empty",    "corner",     "corner" },
                { "empty", "target",   "empty",    "corner",     "corner" },
                { "empty", "empty",    "empty",    "target",     "corner" }
            },
            rotations = {
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 1, 0, 1, 0,
                0, 0, 0, 0, 1,
                0, 0, 0, 0, 0 }
        },
        { -- Level 9: Figure Eight (5x5)
            name = "Figure Eight",
            grid = {
                { "source", "straight", "corner",   "corner",   "corner" },
                { "empty",  "empty",    "straight", "cross",    "straight" },
                { "empty",  "empty",    "corner",   "straight", "target" },
                { "empty",  "empty",    "corner",   "corner",   "corner" },
                { "empty",  "empty",    "empty",    "empty",    "empty" }
            },
            rotations = {
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0,
                0, 0, 0, 0, 0 }
        },
        { -- Level 10: Master Challenge (6x5)
            name = "Master Challenge",
            grid = {
                { "source", "straight", "t_junction", "straight", "t_junction", "target" },
                { "empty",  "empty",    "corner",     "empty",    "corner",     "empty" },
                { "source", "straight", "cross",      "straight", "t_junction", "target" },
                { "empty",  "empty",    "straight",   "empty",    "corner",     "empty" },
                { "empty",  "empty",    "target",     "empty",    "empty",      "empty" }
            },
            rotations = {
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0 }
        },
        { -- Level 11: The Vortex (6x5)
            name = "The Vortex",
            grid = {
                { "source", "straight", "corner",   "corner",   "corner",   "corner" },
                { "empty",  "empty",    "straight", "cross",    "straight", "straight" },
                { "empty",  "empty",    "corner",   "straight", "target",   "empty" },
                { "empty",  "empty",    "corner",   "corner",   "corner",   "corner" },
                { "empty",  "empty",    "empty",    "empty",    "empty",    "target" }
            },
            rotations = {
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0 }
        },
        { -- Level 12: Dual Maze (6x6)
            name = "Dual Maze",
            grid = {
                { "source", "straight", "t_junction", "straight", "t_junction", "target" },
                { "empty",  "empty",    "corner",     "empty",    "corner",     "empty" },
                { "source", "straight", "straight",   "cross",    "t_junction", "target" },
                { "empty",  "empty",    "corner",     "corner",   "straight",     "empty" },
                { "empty",  "empty",    "target",     "empty",    "target",     "empty" },
                { "empty",  "empty",    "empty",      "empty",    "empty",      "empty" }
            },
            rotations = {
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0 }
        },
        { -- Level 13: The Grid (6x5)
            name = "The Grid",
            grid = {
                { "source", "straight", "cross",    "straight", "cross",    "target" },
                { "empty",  "empty",    "straight", "empty",    "straight", "empty" },
                { "source", "straight", "cross",    "straight", "cross",    "target" },
                { "empty",  "empty",    "straight", "empty",    "straight", "empty" },
                { "target", "straight", "cross",    "straight", "cross",    "target" }
            },
            rotations = {
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0 }
        },
        { -- Level 14: Ultimate Challenge (7x6)
            name = "Ultimate Challenge",
            grid = {
                { "source", "straight", "t_junction", "straight", "cross",      "straight", "target" },
                { "empty",  "empty",    "corner",     "empty",    "straight",   "empty",    "empty" },
                { "source", "straight", "cross",      "straight", "t_junction", "straight", "target" },
                { "empty",  "empty",    "corner",     "empty",    "corner",     "empty",    "empty" },
                { "source", "straight", "t_junction", "straight", "cross",      "straight", "target" },
                { "empty",  "empty",    "empty",      "empty",    "empty",      "empty",    "empty" }
            },
            rotations = {
                0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0 }
        },
        { -- Level 15: Final Boss (8x7)
            name = "Final Boss",
            grid = {
                { "source", "straight", "cross",    "straight", "cross",    "straight", "cross",    "target" },
                { "empty",  "empty",    "straight", "empty",    "straight", "empty",    "straight", "empty" },
                { "source", "straight", "cross",    "straight", "cross",    "straight", "cross",    "target" },
                { "empty",  "empty",    "straight", "empty",    "straight", "empty",    "straight", "empty" },
                { "source", "straight", "cross",    "straight", "cross",    "straight", "cross",    "target" },
                { "empty",  "empty",    "straight", "empty",    "straight", "empty",    "straight", "empty" },
                { "target", "straight", "cross",    "straight", "cross",    "straight", "cross",    "target" }
            },
            rotations = {
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0 }
        }
    }
end

function LevelManager:loadLevel(levelNumber)
    if levelNumber < 1 or levelNumber > #self.levels then levelNumber = 1 end

    self.currentLevel = levelNumber
    local levelData = self.levels[levelNumber]

    -- Create tiles from grid
    self.tiles = {}
    self.sources = {}
    self.targets = {}

    local rotationIndex = 1
    for y, row in ipairs(levelData.grid) do
        self.tiles[y] = {}
        for x, tileType in ipairs(row) do
            local rotation = levelData.rotations[rotationIndex] or 0
            local tile = require("classes/Tile").new(x - 1, y - 1, tileType, rotation)
            self.tiles[y][x] = tile

            if tileType == "source" then
                table_insert(self.sources, tile)
            elseif tileType == "target" then
                table_insert(self.targets, tile)
            end

            rotationIndex = rotationIndex + 1
        end
    end

    self.gridWidth = #levelData.grid[1]
    self.gridHeight = #levelData.grid
end

function LevelManager:rotateTile(gridX, gridY, clockwise)
    if self.tiles[gridY + 1] and self.tiles[gridY + 1][gridX + 1] then
        local tile = self.tiles[gridY + 1][gridX + 1]
        if tile.type ~= "target" then
            return tile:rotate(clockwise)
        end
    end
    return false
end

function LevelManager:draw(offsetX, offsetY)
    for y, row in ipairs(self.tiles) do
        for x, tile in ipairs(row) do
            tile:draw(offsetX, offsetY, self.gridSize, tile.powered)
        end
    end
end

function LevelManager:calculatePowerFlow()
    -- Reset all power states
    for y, row in ipairs(self.tiles) do
        for x, tile in ipairs(row) do
            tile.powered = false
        end
    end

    -- Start BFS from all sources
    local queue = {}
    for _, source in ipairs(self.sources) do
        source.powered = true
        table_insert(queue, source)
    end

    while #queue > 0 do
        local current = table.remove(queue, 1)
        local connections = current:getConnections()

        -- Check each connection direction
        for _, dir in ipairs(connections) do
            local nx, ny = current.x, current.y

            if dir == "up" then
                ny = ny - 1
            elseif dir == "right" then
                nx = nx + 1
            elseif dir == "down" then
                ny = ny + 1
            elseif dir == "left" then
                nx = nx - 1
            end

            -- Check if neighbor exists and get its tile
            if self.tiles[ny + 1] and self.tiles[ny + 1][nx + 1] then
                local neighbor = self.tiles[ny + 1][nx + 1]

                if not neighbor.powered then
                    local neighborConnections = neighbor:getConnections()
                    local oppositeDir = self:getOppositeDirection(dir)

                    -- Check if neighbor connects back to current tile
                    if self:hasDirection(neighborConnections, oppositeDir) then
                        neighbor.powered = true
                        table_insert(queue, neighbor)
                    end
                end
            end
        end
    end
end

function LevelManager:hasDirection(connections, dir)
    for _, connection in ipairs(connections) do
        if connection == dir then return true end
    end
    return false
end

function LevelManager:isLevelComplete()
    self:calculatePowerFlow() -- Ensure power flow is calculated
    for _, target in ipairs(self.targets) do
        if not target.powered then return false end
    end
    return #self.targets > 0
end

function LevelManager:getOppositeDirection(dir)
    return opposites[dir]
end

function LevelManager:getTargets()
    return self.targets
end

function LevelManager:getLevelCount()
    return #self.levels
end

function LevelManager:getLevelName(levelNumber)
    if levelNumber >= 1 and levelNumber <= #self.levels then
        return self.levels[levelNumber].name
    end
    return "Unknown Level"
end

return LevelManager
