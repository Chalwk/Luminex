-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_floor = math.floor
local math_random = math.random
local table_insert = table.insert

local LevelManager = require("classes/LevelManager")

local Game = {}
Game.__index = Game

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 1200
    instance.screenHeight = 800
    instance.gridSize = 60
    instance.boardOffsetX = 0
    instance.boardOffsetY = 0

    instance.levelManager = nil
    instance.currentLevel = 1
    instance.levelComplete = false
    instance.moves = 0

    instance.particles = {}
    instance.effects = {}

    local laser = love.audio.newSource("assets/sounds/laser.mp3", "static")
    local win = love.audio.newSource("assets/sounds/win.mp3", "static")
    local rotate = love.audio.newSource("assets/sounds/rotate.mp3", "static")

    -- Simple sound placeholders - you can replace with actual files
    instance.sounds = {
        win = {
            play = function()
                love.audio.play(win)
            end
        },
        rotate = {
            play = function()
                love.audio.play(rotate)
            end
        },
        laser = {
            play = function()
                love.audio.play(laser)
            end
        }
    }

    return instance
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:calculateBoard()
end

function Game:calculateBoard()
    if self.levelManager then
        local gridWidth = self.levelManager.gridWidth or 5
        local gridHeight = self.levelManager.gridHeight or 5
        self.boardOffsetX = (self.screenWidth - gridWidth * self.gridSize) / 2
        self.boardOffsetY = (self.screenHeight - gridHeight * self.gridSize) / 2 + 20
    else
        self.boardOffsetX = (self.screenWidth - 5 * self.gridSize) / 2
        self.boardOffsetY = (self.screenHeight - 5 * self.gridSize) / 2 + 20
    end
end

function Game:loadLevel(levelNumber)
    self.currentLevel = levelNumber
    self.levelManager = LevelManager.new(self.gridSize)
    self.levelManager:loadLevel(levelNumber)
    self.levelComplete = false
    self.moves = 0
    self.particles = {}

    self:calculateBoard() -- Recalculate board with new level dimensions
end

function Game:update(dt)
    if self.levelComplete then return end

    -- Check level completion
    if not self.levelComplete and self.levelManager:isLevelComplete() then
        self.levelComplete = true
        self.sounds.win:play()
        self:createWinEffect()
    end

    -- Update particles
    self:updateParticles(dt)
end

function Game:updateParticles(dt)
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt

        if particle.life <= 0 then
            table.remove(self.particles, i)
        end
    end
end

function Game:createWinEffect()
    local targets = self.levelManager:getTargets()
    for _, target in ipairs(targets) do
        for i = 1, 20 do
            table_insert(self.particles, {
                x = target.x * self.gridSize + self.gridSize / 2,
                y = target.y * self.gridSize + self.gridSize / 2,
                dx = (math_random() - 0.5) * 120,
                dy = (math_random() - 0.5) * 120,
                life = 1.5,
                size = math_random(2, 6),
                color = { 0.3, 0.8, 1.0, 0.9 }
            })
        end
    end
end

function Game:draw()
    -- Draw game board
    self:drawBoard()

    -- Draw level objects (tiles)
    if self.levelManager then
        self.levelManager:draw(self.boardOffsetX, self.boardOffsetY)
    end

    -- Draw particles
    self:drawParticles()

    -- Draw UI
    self:drawUI()

    if self.levelComplete then
        self:drawLevelComplete()
    end
end

function Game:drawBoard()
    if not self.levelManager then return end

    local gridWidth = self.levelManager.gridWidth or 5
    local gridHeight = self.levelManager.gridHeight or 5

    -- Board background
    love.graphics.setColor(0.08, 0.05, 0.12, 0.9)
    love.graphics.rectangle("fill",
        self.boardOffsetX,
        self.boardOffsetY,
        gridWidth * self.gridSize,
        gridHeight * self.gridSize
    )

    -- Draw grid lines
    love.graphics.setColor(0.3, 0.3, 0.5, 0.4)
    love.graphics.setLineWidth(1)

    -- Vertical grid lines
    for x = 0, gridWidth do
        love.graphics.line(
            self.boardOffsetX + x * self.gridSize,
            self.boardOffsetY,
            self.boardOffsetX + x * self.gridSize,
            self.boardOffsetY + gridHeight * self.gridSize
        )
    end

    -- Horizontal grid lines
    for y = 0, gridHeight do
        love.graphics.line(
            self.boardOffsetX,
            self.boardOffsetY + y * self.gridSize,
            self.boardOffsetX + gridWidth * self.gridSize,
            self.boardOffsetY + y * self.gridSize
        )
    end

    -- Board border
    love.graphics.setColor(0.5, 0.2, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line",
        self.boardOffsetX,
        self.boardOffsetY,
        gridWidth * self.gridSize,
        gridHeight * self.gridSize
    )
    love.graphics.setLineWidth(1)
end

function Game:drawParticles()
    for _, particle in ipairs(self.particles) do
        local alpha = particle.life * 0.8
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill",
            particle.x + self.boardOffsetX,
            particle.y + self.boardOffsetY,
            particle.size
        )
    end
end

function Game:drawUI()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)

    -- Level info
    love.graphics.print("Level: " .. self.currentLevel, 20, 20)
    love.graphics.print("Moves: " .. self.moves, 20, 50)

    -- Level name
    if self.levelManager then
        local levelName = self.levelManager:getLevelName(self.currentLevel)
        love.graphics.printf(levelName, 0, 20, self.screenWidth - 20, "right")
    end

    -- Controls help
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf("Click tiles to rotate | R: Reset | ESC: Menu",
        0, self.screenHeight - 30, self.screenWidth, "center")
end

function Game:drawLevelComplete()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    love.graphics.setFont(self.fonts.large)
    love.graphics.setColor(0.3, 0.8, 1.0)
    love.graphics.printf("LEVEL COMPLETE!", 0, self.screenHeight / 2 - 100, self.screenWidth, "center")

    love.graphics.setFont(self.fonts.medium)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Moves: " .. self.moves, 0, self.screenHeight / 2 - 30, self.screenWidth, "center")

    love.graphics.setFont(self.fonts.small)
    love.graphics.printf("Tap to continue", 0, self.screenHeight / 2 + 80, self.screenWidth, "center")
end

function Game:handleTouch(x, y)
    if self.levelComplete then
        self:loadLevel(self.currentLevel + 1)
        return
    end

    if not self.levelManager then return end

    -- Convert screen coordinates to grid coordinates
    local gridX = math_floor((x - self.boardOffsetX) / self.gridSize)
    local gridY = math_floor((y - self.boardOffsetY) / self.gridSize)

    if gridX >= 0 and gridX < self.levelManager.gridWidth and
        gridY >= 0 and gridY < self.levelManager.gridHeight then
        if self.levelManager:rotateTile(gridX, gridY) then
            self.moves = self.moves + 1
            self.sounds.rotate:play()
        end
    end
end

function Game:handleKeypress(key)
    if key == "r" then self:loadLevel(self.currentLevel) end
end

function Game:setFonts(fonts)
    self.fonts = fonts
end

return Game
