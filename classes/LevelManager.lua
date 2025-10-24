-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local table_insert = table.insert

local LevelManager = {}
LevelManager.__index = LevelManager

function LevelManager.new(gridSize)
    local instance = setmetatable({}, LevelManager)

    instance.gridSize = gridSize
    instance.levels = {}
    instance.currentLevel = nil
    instance.mirrors = {}
    instance.targets = {}
    instance.laserSource = nil

    instance:initLevels()

    return instance
end

function LevelManager:initLevels()
    -- Level format: mirrors = {x, y, angle}, targets = {x, y}, laser = {x, y, dir}
    -- Grid is 10x10 (0-9 in both directions) but levels use 1-indexed thinking
    -- Note: x=5,y=2 in code = 6th column, 3rd row visually
    self.levels = {
        { -- level 1
            name = "First Light",
            mirrors = {
                { x = 5, y = 2, angle = 1 }
            },
            targets = {
                { x = 5, y = 4 }
            },
            laser = { x = 1, y = 2, dir = "right" }
        },
        { -- level 2
            name = "Double Reflection",
            mirrors = {
                { x = 3, y = 3, angle = 1 },
                { x = 3, y = 8, angle = 1 }
            },
            targets = {
                { x = 8, y = 8 }
            },
            laser = { x = 1, y = 3, dir = "right" }
        },
        { -- level 3
            name = "Cross Path",
            mirrors = {
                { x = 4, y = 4, angle = 1 },
                { x = 4, y = 8, angle = 1 }
            },
            targets = {
                { x = 8, y = 8 }
            },
            laser = { x = 1, y = 4, dir = "right" }
        },
        { -- level 4
            name = "Twin Targets",
            mirrors = {
                { x = 3, y = 3, angle = 0 },
                { x = 6, y = 3, angle = 1 },
                { x = 3, y = 8, angle = 0 }
            },
            targets = {
                { x = 8, y = 1 },
                { x = 8, y = 8 }
            },
            laser = { x = 1, y = 3, dir = "right" }
        },
        { -- level 5
            name = "Mirror Maze",
            mirrors = {
                { x = 2, y = 2, angle = 0 },
                { x = 7, y = 2, angle = 1 },
                { x = 2, y = 7, angle = 1 },
                { x = 7, y = 7, angle = 0 }
            },
            targets = {
                { x = 8, y = 4 },
                { x = 8, y = 5 }
            },
            laser = { x = 0, y = 4, dir = "right" }
        },
        { -- level 6
            name = "Laser Gate",
            mirrors = {
                { x = 2, y = 3, angle = 0 },
                { x = 4, y = 5, angle = 1 },
                { x = 6, y = 3, angle = 1 }
            },
            targets = {
                { x = 8, y = 7 }
            },
            laser = { x = 0, y = 3, dir = "right" }
        },
        { -- level 7
            name = "The Splitter",
            mirrors = {
                { x = 4, y = 2, angle = 0 },
                { x = 4, y = 6, angle = 1 },
                { x = 7, y = 4, angle = 0 }
            },
            targets = {
                { x = 8, y = 1 },
                { x = 8, y = 8 }
            },
            laser = { x = 1, y = 4, dir = "right" }
        },
        { -- level 8
            name = "Cornered",
            mirrors = {
                { x = 2, y = 2, angle = 1 },
                { x = 2, y = 7, angle = 0 },
                { x = 7, y = 2, angle = 0 },
                { x = 7, y = 7, angle = 1 }
            },
            targets = {
                { x = 4, y = 4 },
                { x = 5, y = 5 }
            },
            laser = { x = 0, y = 4, dir = "right" }
        },
        { -- level 9
            name = "Final Challenge",
            mirrors = {
                { x = 1, y = 3, angle = 0 },
                { x = 3, y = 1, angle = 1 },
                { x = 5, y = 3, angle = 0 },
                { x = 7, y = 1, angle = 1 },
                { x = 3, y = 7, angle = 1 },
                { x = 7, y = 5, angle = 0 }
            },
            targets = {
                { x = 8, y = 8 },
                { x = 9, y = 9 }
            },
            laser = { x = 0, y = 3, dir = "right" }
        }
    }
end

function LevelManager:loadLevel(levelNumber)
    if levelNumber < 1 or levelNumber > #self.levels then
        levelNumber = 1 -- Loop back to first level
    end

    self.currentLevel = levelNumber
    local levelData = self.levels[levelNumber]

    -- Load mirrors
    self.mirrors = {}
    for _, mirrorData in ipairs(levelData.mirrors) do
        table_insert(self.mirrors, {
            x = mirrorData.x,
            y = mirrorData.y,
            angle = mirrorData.angle or 0
        })
    end

    -- Load targets
    self.targets = {}
    for _, targetData in ipairs(levelData.targets) do
        table_insert(self.targets, {
            x = targetData.x,
            y = targetData.y
        })
    end

    -- Load laser source
    self.laserSource = levelData.laser
end

function LevelManager:rotateMirror(gridX, gridY)
    for _, mirror in ipairs(self.mirrors) do
        if mirror.x == gridX and mirror.y == gridY then
            mirror.angle = (mirror.angle + 1) % 2
            return true
        end
    end
    return false
end

function LevelManager:draw(offsetX, offsetY)
    -- Draw targets
    for _, target in ipairs(self.targets) do
        local x = target.x * self.gridSize + offsetX
        local y = target.y * self.gridSize + offsetY

        love.graphics.setColor(0.3, 0.8, 0.3)
        love.graphics.rectangle("fill", x + 8, y + 8, self.gridSize - 16, self.gridSize - 16)

        love.graphics.setColor(0.6, 1.0, 0.6)
        love.graphics.rectangle("line", x + 10, y + 10, self.gridSize - 20, self.gridSize - 20)

        -- Target symbol
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("line", x + self.gridSize / 2, y + self.gridSize / 2, 6)
        love.graphics.circle("fill", x + self.gridSize / 2, y + self.gridSize / 2, 2)
    end

    -- Draw mirrors
    for _, mirror in ipairs(self.mirrors) do
        local x = mirror.x * self.gridSize + offsetX
        local y = mirror.y * self.gridSize + offsetY

        love.graphics.setColor(0.8, 0.8, 1.0)
        love.graphics.rectangle("fill", x + 4, y + 4, self.gridSize - 8, self.gridSize - 8)

        -- Mirror surface
        love.graphics.setColor(0.9, 0.9, 1.0, 0.8)
        if mirror.angle == 0 then
            love.graphics.line(x + 6, y + 6, x + self.gridSize - 6, y + self.gridSize - 6)
            love.graphics.line(x + 7, y + 6, x + self.gridSize - 5, y + self.gridSize - 6)
        else
            love.graphics.line(x + self.gridSize - 6, y + 6, x + 6, y + self.gridSize - 6)
            love.graphics.line(x + self.gridSize - 7, y + 6, x + 5, y + self.gridSize - 6)
        end

        -- Border
        love.graphics.setColor(0.6, 0.6, 1.0)
        love.graphics.rectangle("line", x + 4, y + 4, self.gridSize - 8, self.gridSize - 8)
    end
end

function LevelManager:getMirrors()
    return self.mirrors
end

function LevelManager:getTargets()
    return self.targets
end

function LevelManager:getLaserSource()
    return self.laserSource
end

function LevelManager:getLevelCount()
    return #self.levels
end

function LevelManager:getBestMoves(levelNumber)
    -- TODO: load from a file
    return nil
end

function LevelManager:saveBestMoves(levelNumber, moves)
    -- TODO: save to a file
end

function LevelManager:getLevelName(levelNumber)
    if levelNumber >= 1 and levelNumber <= #self.levels then
        return self.levels[levelNumber].name
    end
    return "Unknown Level"
end

return LevelManager
