-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs

local math_floor = math.floor
local math_min, math_max = math.min, math.max
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

local LevelEditor = {}
LevelEditor.__index = LevelEditor

function LevelEditor.new(helpers)
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

    instance.lastMessage = ""
    instance.messageTimer = 0

    instance.helpers = helpers

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
    if self.messageTimer > 0 then
        self.messageTimer = self.messageTimer - dt
        if self.messageTimer <= 0 then
            self.lastMessage = ""
            self.messageTimer = 0
        end
    end
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
    local t = self.helpers.CONNECTIONS[tileType]
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

    local colors = self.helpers.BULB_COLORS
    local bulbData = colors[bulbType] or colors[1]

    local bulbColor = bulbData.bulbColor
    setColor(bulbColor[1], bulbColor[2], bulbColor[3], bulbColor[4] or 0.8)
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

    if self.lastMessage ~= "" then
        setColor(1, 1, 0, 1) -- yellow text
        print(self.lastMessage, 5, self.screenHeight / 1.3)
    end
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
    if self.helpers.TOOL_MAP[key] then
        self.currentTool = self.helpers.TOOL_MAP[key]
        self.currentRotation = 0
        if key == "7" then self.currentBulbType = 1 end
    elseif key == "b" and self.currentTool == "target" then
        self.currentBulbType = (self.currentBulbType % 4) + 1
    elseif key == "=" or key == "+" then
        local newWidth = math_min(self.gridWidth + 1, 14)
        local newHeight = math_min(self.gridHeight + 1, 14)
        self:resizeGrid(newWidth, newHeight)
    elseif key == "-" then
        local newWidth = math_max(self.gridWidth - 1, 3)
        local newHeight = math_max(self.gridHeight - 1, 3)
        self:resizeGrid(newWidth, newHeight)
    elseif key == "s" then
        self:saveLevel()
    elseif key == "l" then
        self:loadLevel()
    elseif key == "r" then
        self:resetCurrentTile()
    end
end

function LevelEditor:resetCurrentTile()
    local x, y = love.mouse.getPosition()

    -- Convert screen coordinates to grid coordinates
    local gridX = math_floor((x - self.boardOffsetX) / self.gridSize)
    local gridY = math_floor((y - self.boardOffsetY) / self.gridSize)

    if gridX >= 0 and gridX < self.gridWidth and
        gridY >= 0 and gridY < self.gridHeight then
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

        -- Reset tile to empty
        tile.type = "empty"
        tile.rotation = 0
        tile.bulbType = 1

        self.lastMessage = "Tile reset at " .. gridX .. "," .. gridY
        self.messageTimer = 2
    else
        self.lastMessage = "Click on a tile first, then press R to reset"
        self.messageTimer = 2
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
    local luaCode = self.helpers.levelToLua(levelData)

    -- Save to file - use Love2D's save directory
    local success, message = love.filesystem.write(self.filename, luaCode)

    if success then
        local saveDir = love.filesystem.getSaveDirectory()
        self.lastMessage = "File saved to: " .. saveDir .. "/" .. self.filename
    else
        self.lastMessage = "Error saving level: " .. tostring(message)
        print("Save error details: ", message)
    end
    self.messageTimer = 3
end

function LevelEditor:loadLevel()
    -- Load from Love2D's save directory
    if not love.filesystem.getInfo(self.filename) then
        self.lastMessage = "Level file not found: " .. self.filename
        self.messageTimer = 3
        return
    end

    local contents, size = love.filesystem.read(self.filename)
    if not contents then
        self.lastMessage = "Error reading level: " .. self.filename
        self.messageTimer = 3
        return
    end

    -- Safely compile the string
    local chunk, compileError = loadstring(contents)
    if not chunk then
        self.lastMessage = "Error compiling level: " .. compileError
        self.messageTimer = 3
        return
    end

    -- Safely execute the compiled function
    local success, levelData = pcall(chunk)
    if not success then
        self.lastMessage = "Error executing level: " .. levelData
        self.messageTimer = 3
        return
    end

    if type(levelData) ~= "table" then
        self.lastMessage = "Invalid level format in: " .. self.filename
        self.messageTimer = 3
        return
    end

    -- Resize grid to match saved level
    local gridH = #levelData.grid
    local gridW = #levelData.grid[1] or 5
    self:resizeGrid(gridW, gridH)

    -- Apply tiles
    local rotationIndex = 1
    local bulbIndex = 1
    for y = 0, gridH - 1 do
        for x = 0, gridW - 1 do
            local tileType = levelData.grid[y + 1][x + 1]
            local tile = self.tiles[y][x]
            tile.type = tileType
            tile.rotation = levelData.rotations[rotationIndex] or 0

            if tileType == "target" then
                tile.bulbType = levelData.bulbTypes[bulbIndex] or 1
                bulbIndex = bulbIndex + 1
            end

            rotationIndex = rotationIndex + 1
        end
    end

    self.levelName = levelData.name or "Custom Level"
    self.lastMessage = "Level loaded: " .. self.filename
    self.messageTimer = 3
end

function LevelEditor:setFonts(fonts)
    self.fonts = fonts
end

return LevelEditor
