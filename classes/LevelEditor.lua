-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs

local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove

local line = love.graphics.line
local print = love.graphics.print
local printf = love.graphics.printf
local circle = love.graphics.circle
local setFont = love.graphics.setFont
local setColor = love.graphics.setColor
local rectangle = love.graphics.rectangle
local setLineWidth = love.graphics.setLineWidth

local PALETTE_X = 20
local PALETTE_Y = 60
local BUTTON_SIZE = 40
local BUTTON_SPACING = 10

local toolMap = {
    ["1"] = "empty",
    ["2"] = "straight",
    ["3"] = "corner",
    ["4"] = "t_junction",
    ["5"] = "cross",
    ["6"] = "source",
    ["7"] = "target",
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

local BULB_COLORS = {
    [1] = { 1.0, 0.9, 0.6 },
    [2] = { 0.6, 0.8, 1.0 },
    [3] = { 0.6, 1.0, 0.6 },
    [4] = { 0.8, 0.6, 1.0 }
}

local LevelEditor = {}
LevelEditor.__index = LevelEditor

function LevelEditor.new()
    local instance = setmetatable({}, LevelEditor)

    instance.screenWidth = 1200
    instance.screenHeight = 800
    instance.gridSize = 60
    instance.boardOffsetX = 0
    instance.boardOffsetY = 0

    instance.gridWidth = 5
    instance.gridHeight = 5
    instance.tiles = {}
    instance.sources = {}
    instance.targets = {}

    instance.currentTool = "straight"
    instance.currentRotation = 0
    instance.currentBulbType = 1

    instance.uiState = "main" -- main, save, load
    instance.levelName = "Custom Level"
    instance.filename = "custom_level.lua"

    instance.availableTileTypes = { "empty", "straight", "corner", "t_junction", "cross", "source", "target" }

    instance:initializeGrid()

    return instance
end

function LevelEditor:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:calculateBoard()
end

function LevelEditor:calculateBoard()
    self.boardOffsetX = (self.screenWidth - self.gridWidth * self.gridSize) / 2
    self.boardOffsetY = (self.screenHeight - self.gridHeight * self.gridSize) / 2 + 20
end

function LevelEditor:initializeGrid()
    self.tiles = {}
    self.sources = {}
    self.targets = {}

    for y = 0, self.gridHeight - 1 do
        self.tiles[y] = {}
        for x = 0, self.gridWidth - 1 do
            self.tiles[y][x] = {
                type = "empty",
                rotation = 0,
                bulbType = 1,
                x = x,
                y = y
            }
        end
    end
end

function LevelEditor:resizeGrid(newWidth, newHeight)
    local oldTiles = self.tiles

    self.gridWidth = newWidth
    self.gridHeight = newHeight
    self.tiles = {}
    self.sources = {}
    self.targets = {}

    for y = 0, self.gridHeight - 1 do
        self.tiles[y] = {}
        for x = 0, self.gridWidth - 1 do
            if oldTiles[y] and oldTiles[y][x] then
                self.tiles[y][x] = oldTiles[y][x]
            else
                self.tiles[y][x] = {
                    type = "empty",
                    rotation = 0,
                    bulbType = 1,
                    x = x,
                    y = y
                }
            end

            -- Update sources and targets
            local tile = self.tiles[y][x]
            if tile.type == "source" then
                table_insert(self.sources, tile)
            elseif tile.type == "target" then
                table_insert(self.targets, tile)
            end
        end
    end

    self:calculateBoard()
end

function LevelEditor:update(dt)
    -- Update any animations or effects if needed
end

function LevelEditor:draw()
    -- Draw editor background
    setColor(0.05, 0.03, 0.08, 0.9)
    rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    -- Draw editor board
    self:drawBoard()

    -- Draw tiles
    self:drawTiles()

    -- Draw UI
    self:drawUI()

    -- Draw current tool info
    self:drawToolInfo()
end

function LevelEditor:drawBoard()
    -- Board background
    setColor(0.08, 0.05, 0.12, 0.9)
    rectangle("fill",
        self.boardOffsetX,
        self.boardOffsetY,
        self.gridWidth * self.gridSize,
        self.gridHeight * self.gridSize
    )

    -- Draw grid lines
    setColor(0.3, 0.3, 0.5, 0.4)
    setLineWidth(1)

    -- Vertical grid lines
    for x = 0, self.gridWidth do
        line(
            self.boardOffsetX + x * self.gridSize,
            self.boardOffsetY,
            self.boardOffsetX + x * self.gridSize,
            self.boardOffsetY + self.gridHeight * self.gridSize
        )
    end

    -- Horizontal grid lines
    for y = 0, self.gridHeight do
        line(
            self.boardOffsetX,
            self.boardOffsetY + y * self.gridSize,
            self.boardOffsetX + self.gridWidth * self.gridSize,
            self.boardOffsetY + y * self.gridSize
        )
    end

    -- Board border
    setColor(0.5, 0.2, 0.8)
    setLineWidth(3)
    rectangle("line",
        self.boardOffsetX,
        self.boardOffsetY,
        self.gridWidth * self.gridSize,
        self.gridHeight * self.gridSize
    )
    setLineWidth(1)
end

function LevelEditor:drawTiles()
    for y = 0, self.gridHeight - 1 do
        for x = 0, self.gridWidth - 1 do
            local tile = self.tiles[y][x]
            if tile and tile.type ~= "empty" then
                self:drawTile(tile, x, y)
            end
        end
    end
end

function LevelEditor:drawTile(tile, gridX, gridY)
    local x = self.boardOffsetX + gridX * self.gridSize
    local y = self.boardOffsetY + gridY * self.gridSize

    -- Tile background
    setColor(0.15, 0.1, 0.2, 0.8)
    rectangle("fill", x, y, self.gridSize, self.gridSize)

    -- Draw connections based on type
    local centerX = x + self.gridSize / 2
    local centerY = y + self.gridSize / 2

    setLineWidth(3)
    setColor(0.5, 0.5, 0.7)

    local connections = self:getConnections(tile.type, tile.rotation)

    for _, dir in ipairs(connections) do
        if dir == "up" then
            line(centerX, centerY, centerX, y)
        elseif dir == "right" then
            line(centerX, centerY, x + self.gridSize, centerY)
        elseif dir == "down" then
            line(centerX, centerY, centerX, y + self.gridSize)
        elseif dir == "left" then
            line(centerX, centerY, x, centerY)
        end
    end

    -- Special rendering for source and target
    if tile.type == "source" then
        self:drawLaserGenerator(x, y, tile.rotation)
    elseif tile.type == "target" then
        self:drawLightBulb(x, y, tile.bulbType)
    end

    setLineWidth(1)

    -- Tile border
    setColor(0.7, 0.7, 0.9)
    rectangle("line", x, y, self.gridSize, self.gridSize)
end

function LevelEditor:getConnections(tileType, rotation)
    local t = CONNECTIONS[tileType]
    if not t then return {} end
    return t[rotation % 4] or t[0] or {}
end

function LevelEditor:drawLaserGenerator(x, y, rotation)
    local centerX = x + self.gridSize / 2
    local centerY = y + self.gridSize / 2
    local bodyWidth = self.gridSize * 0.6
    local bodyHeight = self.gridSize * 0.4

    -- Generator body
    setColor(0.3, 0.3, 0.4)
    rectangle("fill", centerX - bodyWidth / 2, centerY - bodyHeight / 2, bodyWidth, bodyHeight, 5)

    -- Generator details
    setColor(0.5, 0.5, 0.6)
    rectangle("line", centerX - bodyWidth / 2, centerY - bodyHeight / 2, bodyWidth, bodyHeight, 5)

    -- Laser emitter lens
    local lensSize = self.gridSize * 0.2
    local lensX, lensY

    if rotation == 0 then -- Right
        lensX = centerX + bodyWidth / 2
        lensY = centerY
    elseif rotation == 1 then -- Down
        lensX = centerX
        lensY = centerY + bodyWidth / 2
    elseif rotation == 2 then -- Left
        lensX = centerX - bodyWidth / 2
        lensY = centerY
    else -- Up
        lensX = centerX
        lensY = centerY - bodyWidth / 2
    end

    setColor(0.0, 0.8, 1.0)
    circle("fill", lensX, lensY, lensSize)
end

function LevelEditor:drawLightBulb(x, y, bulbType)
    local centerX = x + self.gridSize / 2
    local centerY = y + self.gridSize / 2
    local bulbRadius = self.gridSize * 0.25

    local color = BULB_COLORS[bulbType] or BULB_COLORS[1]
    setColor(color[1], color[2], color[3], 0.8)
    circle("fill", centerX, centerY, bulbRadius)

    -- Bulb type indicator
    setColor(1, 1, 1)
    print(bulbType, centerX - 3, centerY - 5)
end

function LevelEditor:drawUI()
    setColor(1, 1, 1)

    -- Title
    setFont(self.fonts.medium)
    printf("LEVEL EDITOR", 0, 20, self.screenWidth, "center")

    -- Grid size info
    print("Grid: " .. self.gridWidth .. "x" .. self.gridHeight, 20, 20)

    -- Tool palette
    self:drawToolPalette()

    -- Instructions
    setColor(1, 1, 1, 0.7)
    printf("Left Click: Place | Right Click: Rotate | R: Reset Tile | +/-: Resize Grid",
        0, self.screenHeight - 30, self.screenWidth, "center")
    printf("S: Save Level | L: Load Level | ESC: Back to Menu",
        0, self.screenHeight - 55, self.screenWidth, "center")
    printf("1-7: Select Tile Types | B: Cycle Bulb Types (for Target)",
        0, self.screenHeight - 80, self.screenWidth, "center")
end

function LevelEditor:drawToolPalette()
    setColor(0.1, 0.1, 0.2, 0.9)
    rectangle("fill", PALETTE_X - 10, PALETTE_Y - 10,
        #self.availableTileTypes * (BUTTON_SIZE + BUTTON_SPACING) + 10,
        BUTTON_SIZE + 20)

    for i, tool in ipairs(self.availableTileTypes) do
        local x = PALETTE_X + (i - 1) * (BUTTON_SIZE + BUTTON_SPACING)
        local y = PALETTE_Y

        -- Button background
        if tool == self.currentTool then
            setColor(0.3, 0.8, 1.0, 0.8)
        else
            setColor(0.2, 0.2, 0.4, 0.8)
        end
        rectangle("fill", x, y, BUTTON_SIZE, BUTTON_SIZE, 5)

        -- Button border
        setColor(0.5, 0.5, 0.7)
        rectangle("line", x, y, BUTTON_SIZE, BUTTON_SIZE, 5)

        -- Tool icon and number
        setColor(1, 1, 1)
        if tool == "empty" then
            -- Empty square
            setColor(0.5, 0.5, 0.5)
            rectangle("line", x + 10, y + 10, BUTTON_SIZE - 20, BUTTON_SIZE - 20)
        else
            -- First letter of tool name
            local letter = tool:sub(1, 1):upper()
            print(letter, x + BUTTON_SIZE / 2 - 3, y + BUTTON_SIZE / 2 - 5)
        end

        -- Number key indicator
        setColor(0.8, 0.8, 0.3)
        print(i, x + 3, y + 3)
    end

    -- Rotation indicator
    if self.currentTool ~= "empty" and self.currentTool ~= "target" and self.currentTool ~= "cross" then
        setColor(1, 1, 1)
        print("Rotation: " .. self.currentRotation, PALETTE_X, PALETTE_Y + BUTTON_SIZE + 10)
    end

    -- Bulb type indicator for target
    if self.currentTool == "target" then
        setColor(1, 1, 1)
        print("Bulb Type: " .. self.currentBulbType, PALETTE_X, PALETTE_Y + BUTTON_SIZE + 10)
    end
end

function LevelEditor:drawToolInfo()
    local infoX = self.screenWidth - 200
    local infoY = 60

    setColor(0.1, 0.1, 0.2, 0.9)
    rectangle("fill", infoX - 10, infoY - 10, 180, 80)

    setColor(1, 1, 1)
    print("Current Tool:", infoX, infoY)
    print(self.currentTool:gsub("^%l", string.upper), infoX, infoY + 25)

    if self.currentTool == "target" then
        print("Bulb: " .. self.currentBulbType, infoX, infoY + 45)
    elseif self.currentTool ~= "empty" and self.currentTool ~= "cross" then
        print("Rot: " .. self.currentRotation, infoX, infoY + 45)
    end
end

function LevelEditor:handleMousePress(x, y, button)
    -- Convert screen coordinates to grid coordinates
    local gridX = math_floor((x - self.boardOffsetX) / self.gridSize)
    local gridY = math_floor((y - self.boardOffsetY) / self.gridSize)

    if gridX >= 0 and gridX < self.gridWidth and
        gridY >= 0 and gridY < self.gridHeight then
        if button == 1 then     -- Left click - place tile
            self:placeTile(gridX, gridY)
        elseif button == 2 then -- Right click - rotate tile
            self:rotateTile(gridX, gridY)
        end
    end

    -- Check tool palette clicks
    self:checkToolPaletteClick(x, y)
end

function LevelEditor:placeTile(gridX, gridY)
    local tile = self.tiles[gridY][gridX]

    -- Remove from sources/targets if it was one
    if tile.type == "source" then
        for i, source in ipairs(self.sources) do
            if source.x == gridX and source.y == gridY then
                table_remove(self.sources, i)
                break
            end
        end
    elseif tile.type == "target" then
        for i, target in ipairs(self.targets) do
            if target.x == gridX and target.y == gridY then
                table_remove(self.targets, i)
                break
            end
        end
    end

    -- Update tile
    tile.type = self.currentTool
    tile.rotation = self.currentRotation

    if self.currentTool == "target" then
        tile.bulbType = self.currentBulbType
        table_insert(self.targets, tile)
    elseif self.currentTool == "source" then
        table_insert(self.sources, tile)
    end
end

function LevelEditor:rotateTile(gridX, gridY)
    local tile = self.tiles[gridY][gridX]
    if tile.type ~= "empty" and tile.type ~= "cross" and tile.type ~= "target" then
        tile.rotation = (tile.rotation + 1) % 4
    end
end

function LevelEditor:checkToolPaletteClick(x, y)
    for i, tool in ipairs(self.availableTileTypes) do
        local btnX = PALETTE_X + (i - 1) * (BUTTON_SIZE + BUTTON_SPACING)
        local btnY = PALETTE_Y

        if x >= btnX and x <= btnX + BUTTON_SIZE and
            y >= btnY and y <= btnY + BUTTON_SIZE then
            self.currentTool = tool
            if tool == "target" then
                self.currentBulbType = 1
            else
                self.currentRotation = 0
            end
            return
        end
    end
end

function LevelEditor:handleKeyPress(key)
    if toolMap[key] then
        self.currentTool = toolMap[key]
        self.currentRotation = 0
        if key == "7" then
            self.currentBulbType = 1
        end
    elseif key == "b" and self.currentTool == "target" then
        self.currentBulbType = (self.currentBulbType % 4) + 1
    elseif key == "=" or key == "+" then
        self:resizeGrid(self.gridWidth + 1, self.gridHeight + 1)
    elseif key == "-" then
        if self.gridWidth > 3 and self.gridHeight > 3 then
            self:resizeGrid(self.gridWidth - 1, self.gridHeight - 1)
        end
    elseif key == "s" then
        self:saveLevel()
    elseif key == "l" then
        self:loadLevel()
    end
end

function LevelEditor:saveLevel()
    -- Convert tiles to level format
    local grid = {}
    local rotations = {}
    local bulbTypes = {}

    for y = 0, self.gridHeight - 1 do
        grid[y + 1] = {}
        for x = 0, self.gridWidth - 1 do
            local tile = self.tiles[y][x]
            grid[y + 1][x + 1] = tile.type

            table_insert(rotations, tile.rotation)

            if tile.type == "target" then
                table_insert(bulbTypes, tile.bulbType)
            end
        end
    end

    -- Create level data
    local levelData = {
        name = self.levelName,
        grid = grid,
        rotations = rotations,
        bulbTypes = bulbTypes
    }

    -- Convert to Lua code
    local luaCode = self:levelToLua(levelData)

    -- Save to file
    local writeSuccess, message = love.filesystem.write("assets/levels/" .. self.filename, luaCode)

    if writeSuccess then
        print("Level saved successfully as: assets/levels/" .. self.filename)
    else
        print("Error saving level: " .. tostring(message))
    end
end

function LevelEditor:levelToLua(levelData)
    local lua = "return {\n"

    -- Name
    lua = lua .. "    name = \"" .. levelData.name .. "\",\n"

    -- Grid
    lua = lua .. "    grid = {\n"
    for y, row in ipairs(levelData.grid) do
        lua = lua .. "        { "
        for x, tileType in ipairs(row) do
            lua = lua .. "\"" .. tileType .. "\""
            if x < #row then lua = lua .. ", " end
        end
        lua = lua .. " }"
        if y < #levelData.grid then lua = lua .. ",\n" else lua = lua .. "\n" end
    end
    lua = lua .. "    },\n"

    -- Rotations
    local columns = #levelData.grid[1] -- Get the number of columns from the first row
    lua = lua .. "    rotations = {\n        "
    for i, rotation in ipairs(levelData.rotations) do
        lua = lua .. rotation
        if i < #levelData.rotations then lua = lua .. ", " end
        if i % columns == 0 and i < #levelData.rotations then
            lua = lua .. "\n        "
        end
    end
    lua = lua .. "\n    },\n"

    -- Bulb types
    if #levelData.bulbTypes > 0 then
        lua = lua .. "    bulbTypes = { "
        for i, bulbType in ipairs(levelData.bulbTypes) do
            lua = lua .. bulbType
            if i < #levelData.bulbTypes then lua = lua .. ", " end
        end
        lua = lua .. " }\n"
    else
        lua = lua .. "    bulbTypes = { 1 }\n"
    end

    lua = lua .. "}"
    return lua
end

function LevelEditor:loadLevel()
    -- TODO: Implement level loading
end

function LevelEditor:setFonts(fonts)
    self.fonts = fonts
end

return LevelEditor
