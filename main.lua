-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local Game = require("classes/Game")
local Menu = require("classes/Menu")
local BackgroundManager = require("classes/BackgroundManager")
local LevelEditor = require("classes/LevelEditor")

local game, menu, backgroundManager, levelEditor
local screenWidth, screenHeight
local gameState = "menu" -- menu, level_select, playing, editor
local fonts = {}

local function updateScreenSize()
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()
end

function love.load()
    love.window.setTitle("Luminex - Laser Puzzle")
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("smooth")

    -- Load fonts
    fonts.small = love.graphics.newFont(16)
    fonts.medium = love.graphics.newFont(22)
    fonts.large = love.graphics.newFont(52)
    fonts.section = love.graphics.newFont(18)

    love.graphics.setFont(fonts.medium)

    game = Game.new()
    menu = Menu.new()
    backgroundManager = BackgroundManager.new()
    levelEditor = LevelEditor.new()

    menu:setFonts(fonts)
    game:setFonts(fonts)
    levelEditor:setFonts(fonts)

    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
    levelEditor:setScreenSize(screenWidth, screenHeight)
end

function love.update(dt)
    updateScreenSize()
    if gameState == "menu" or gameState == "level_select" then
        menu:update(dt, screenWidth, screenHeight)
    elseif gameState == "playing" then
        game:update(dt)
    elseif gameState == "editor" then
        levelEditor:update(dt)
    end

    backgroundManager:update(dt)
end

function love.draw()
    backgroundManager:draw(screenWidth, screenHeight, gameState)

    if gameState == "menu" or gameState == "level_select" then
        menu:draw(screenWidth, screenHeight, gameState)
    elseif gameState == "playing" then
        game:draw()
    elseif gameState == "editor" then
        levelEditor:draw()
    end
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 or button == 2 then -- Left click (1) or right click (2)
        if gameState == "menu" then
            local action = menu:handleClick(x, y, "menu")
            if action == "start" then
                gameState = "playing"
                game:loadLevel(1) -- Start with level 1
            elseif action == "level_select" then
                gameState = "level_select"
            elseif action == "editor" then
                gameState = "editor"
            elseif action == "quit" then
                love.event.quit()
            end
        elseif gameState == "level_select" then
            local action = menu:handleClick(x, y, "level_select")
            if action and action:sub(1, 5) == "level" then
                local level = tonumber(action:sub(7))
                gameState = "playing"
                game:loadLevel(level)
            elseif action == "back_to_menu" then
                gameState = "menu"
            end
        elseif gameState == "playing" then
            game:handleTouch(x, y, button)
        elseif gameState == "editor" then
            levelEditor:handleMousePress(x, y, button)
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        if gameState == "playing" then
            gameState = "menu"
        elseif gameState == "level_select" then
            gameState = "menu"
        elseif gameState == "editor" then
            gameState = "menu"
        else
            love.event.quit()
        end
    elseif gameState == "playing" then
        game:handleKeypress(key)
    elseif gameState == "editor" then
        levelEditor:handleKeyPress(key)
    end
end

function love.resize(w, h)
    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
    levelEditor:setScreenSize(screenWidth, screenHeight)
end
