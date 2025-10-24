-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_floor = math.floor
local math_random = math.random
local table_insert = table.insert

local Laser = require("classes/Laser")
local LevelManager = require("classes/LevelManager")

local Game = {}
Game.__index = Game

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 1200
    instance.screenHeight = 800
    instance.gridSize = 40
    instance.boardOffsetX = 0
    instance.boardOffsetY = 0

    instance.laser = nil
    instance.levelManager = nil
    instance.currentLevel = 1
    instance.levelComplete = false
    instance.moves = 0
    instance.bestMoves = 0

    instance.particles = {}
    instance.effects = {}

    instance.sounds = {
        laser = love.audio.newSource("assets/sounds/laser.mp3", "static"),
        win = love.audio.newSource("assets/sounds/win.mp3", "static"),
        rotate = love.audio.newSource("assets/sounds/rotate.mp3", "static")
    }

    return instance
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:calculateBoard()
end

function Game:calculateBoard()
    self.boardOffsetX = (self.screenWidth - 10 * self.gridSize) / 2
    self.boardOffsetY = (self.screenHeight - 10 * self.gridSize) / 2 + 20
end

function Game:loadLevel(levelNumber)
    self.currentLevel = levelNumber
    self.levelManager = LevelManager.new(self.gridSize)
    self.levelManager:loadLevel(levelNumber)
    self.laser = Laser.new(self.gridSize, self.levelManager:getLaserSource())
    self.levelComplete = false
    self.moves = 0
    self.bestMoves = self.levelManager:getBestMoves(levelNumber) or 0
    self.particles = {}
end

function Game:update(dt)
    if self.levelComplete then return end

    -- Update laser
    self.laser:update(dt, self.levelManager:getMirrors())

    -- Check level completion
    if not self.levelComplete and self.laser:checkTargetsHit(self.levelManager:getTargets()) then
        self.levelComplete = true
        love.audio.play(self.sounds.win)
        self.levelManager:saveBestMoves(self.currentLevel, self.moves)
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
                x = target.x + self.gridSize / 2,
                y = target.y + self.gridSize / 2,
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

    -- Draw level objects
    self.levelManager:draw(self.boardOffsetX, self.boardOffsetY)

    -- Draw laser
    self.laser:draw(self.boardOffsetX, self.boardOffsetY)

    -- Draw particles
    self:drawParticles()

    -- Draw UI
    self:drawUI()

    if self.levelComplete then
        self:drawLevelComplete()
    end
end

function Game:drawBoard()
    -- Board background
    love.graphics.setColor(0.08, 0.05, 0.12, 0.9)
    love.graphics.rectangle("fill",
        self.boardOffsetX,
        self.boardOffsetY,
        10 * self.gridSize,
        10 * self.gridSize
    )

    -- Draw grid lines for debugging
    love.graphics.setColor(0.3, 0.3, 0.5, 0.4)
    love.graphics.setLineWidth(1)

    -- Vertical grid lines
    for x = 0, 10 do
        love.graphics.line(
            self.boardOffsetX + x * self.gridSize,
            self.boardOffsetY,
            self.boardOffsetX + x * self.gridSize,
            self.boardOffsetY + 10 * self.gridSize
        )
    end

    -- Horizontal grid lines
    for y = 0, 10 do
        love.graphics.line(
            self.boardOffsetX,
            self.boardOffsetY + y * self.gridSize,
            self.boardOffsetX + 10 * self.gridSize,
            self.boardOffsetY + y * self.gridSize
        )
    end

    -- Draw coordinate labels
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.setFont(self.fonts.small)
    for x = 0, 9 do
        for y = 0, 9 do
            local label = (x + 1) .. "," .. (y + 1)
            local labelX = self.boardOffsetX + x * self.gridSize + 5
            local labelY = self.boardOffsetY + y * self.gridSize + 5
            love.graphics.print(label, labelX, labelY)
        end
    end

    -- Board border
    love.graphics.setColor(0.5, 0.2, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line",
        self.boardOffsetX,
        self.boardOffsetY,
        10 * self.gridSize,
        10 * self.gridSize
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
    love.graphics.print("Best: " .. self.bestMoves, 20, 80)

    -- Controls help
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf("Tap mirrors to rotate | R: Reset | ESC: Menu",
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

    if self.moves <= self.bestMoves or self.bestMoves == 0 then
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.printf("New Best!", 0, self.screenHeight / 2, self.screenWidth, "center")
    else
        love.graphics.printf("Best: " .. self.bestMoves, 0, self.screenHeight / 2, self.screenWidth, "center")
    end

    love.graphics.setFont(self.fonts.small)
    love.graphics.printf("Tap to continue", 0, self.screenHeight / 2 + 80, self.screenWidth, "center")
end

function Game:handleTouch(x, y)
    if self.levelComplete then
        self:loadLevel(self.currentLevel + 1)
        return
    end

    -- Convert screen coordinates to grid coordinates
    local gridX = math_floor((x - self.boardOffsetX) / self.gridSize)
    local gridY = math_floor((y - self.boardOffsetY) / self.gridSize)

    if gridX >= 0 and gridX < 10 and gridY >= 0 and gridY < 10 then
        if self.levelManager:rotateMirror(gridX, gridY) then
            self.moves = self.moves + 1
            love.audio.play(self.sounds.rotate)
        end
    end
end

function Game:handleKeypress(key)
    if key == "r" then
        self:loadLevel(self.currentLevel)
    end
end

function Game:setFonts(fonts)
    self.fonts = fonts
end

return Game